library(tidyverse)
library(ggplot2)
library(readr)
library(janitor)
library(data.table)



# j indicates chromosome number (1-22)
j = as.integer(Sys.getenv("SGE_TASK_ID"))
chrom_dir = paste("chr",j,sep="")
d = paste("/data/nfs1/home/hgrant3/cancer_seek/shendure/processed_data/",
          chrom_dir,"/",sep = "")

# make lasso = T if using informed "lasso regions"  
# and lasso = F if using arbitrary splitting into 10 regions

lasso = T

## read in data ---------------------------------------------------

# fragment files
chr_files = list.files(d)

# sample info
sample_df = read.delim("/data/nfs1/home/hgrant3/cancer_seek/shendure/SraRunTable.txt", sep = ",")%>%
  clean_names()%>%
  select(run, disease, sex)%>%
  mutate(disease=tolower(disease)%>%as.character(),
         run= as.character(run))%>%
  arrange(run)

cancers = sample_df$run[grep("cancer",as.character(sample_df$disease))]
normals = sample_df$run[grep("healthy",as.character(sample_df$disease))]

# cutting intensity (Kamel)
oldnames = paste("score",c("",paste(".",seq(1,9),sep="")),sep = "")
newnames = paste("r",seq(1,10),sep = "")

lambda_dir = "/data/nfs1/home/hgrant3/cancer_seek/shendure/IntensityFrag/"

lambda_cancer = read_csv(paste(lambda_dir,
                               "LambdaDetectCancersFirst",
                               j, ".csv",sep=""))%>%
  rename_at(vars(oldnames), ~ newnames)%>%
  pivot_longer(3:12, names_to = "region", values_to = "score")%>%
  mutate(region = factor(region, levels = paste("r",seq(1,10) ,sep="")))
lambda_normal = read_csv(paste(lambda_dir,
                               "LambdaDetectNormalsFirst",
                               j,".csv",sep=""))%>%
  rename_at(vars(oldnames), ~ newnames)%>%
  pivot_longer(3:12, names_to = "region", values_to = "score")%>%
  mutate(region = factor(region, levels = paste("r",seq(1,10) ,sep="")))

# regions of chromosome


if(!lasso){
regions_dir = "/data/nfs1/home/hgrant3/cancer_seek/shendure/RegionsOfAmplicons/"
regions = read_csv(paste(regions_dir,"RegionsOfAmplicons",j,".csv",sep = ""))
}
if(lasso){
  regions_dir = "/data/nfs1/home/hgrant3/cancer_seek/shendure/RegionsOfAmpliconsLasso/"
  regions = read_csv(paste(regions_dir,"RegionsOfAmpliconsLasso",j,".csv",sep = ""))
  }

nregions = length(unique(regions$Region))
region_boundaries = regions%>%
  clean_names()%>%
  mutate(region = paste("r",region,sep = ""),
         region = factor(region, levels = c(paste("r",seq(1,nregions),sep=""))))%>%
  group_by(region)%>%
  summarise(min = min(end, na.rm = T),
            max = max(end, na.rm = T))%>%
  mutate(width = max - min)

# combine 
regions_length = region_boundaries%>%
  full_join(lambda_cancer%>%
              group_by(region)%>%
              summarise(lambda = mean(score, na.rm = T)),
            by = "region")%>%
  mutate(expected_length = 1/lambda,
         disease = "cancer")%>%
  bind_rows(
    region_boundaries%>%
      full_join(lambda_normal%>%
                  group_by(region)%>%
                  summarise(lambda = mean(score, na.rm = T)),
                by = "region")%>%
      mutate(expected_length = 1/lambda,
             disease = "normal"))

### functions ---------------------------------------------------

# function to find which region each fragment read is in (if any)
find_region = function(number){
  reg = NA
  for(i in 1:nregions){
    if(number >=region_boundaries$min[i] & number <= region_boundaries$max[i]){
      reg =paste("r",i,sep = "")
    }
     }
  reg = factor(reg, levels = paste("r",seq(1,nregions) ,sep=""))
  return(reg)
  }


# sample data

# dataframe to store summary level data
chr = data.frame(matrix(ncol = 14, nrow = 0))
colnames(chr) = c("sample", "disease_status","region","mean_length", "perc_10","perc_20", "perc_30","perc_40","perc_50","perc_60", "perc_70","perc_80","perc_90","read_count")


for(i in 1:length(chr_files)){
  file = chr_files[i]
  sample = substr(chr_files[i],1,10)
  print(sample)
  disease = ifelse(sum(grepl(sample,cancers))==1,"cancer",
                   ifelse(sum(grepl(sample,normals))==1,"normal","other"))
  if(disease %in% c("cancer","normal")){
dat = read.csv(paste(d,file,sep = ""))%>%
  clean_names()%>%
  dplyr::select(-chrom)%>%
  mutate(sample = sample, disease_status = disease)%>%
  rowwise()%>%
  mutate(region = find_region(pos))%>%
  as.data.frame()%>%
  dplyr::filter(!is.na(region))%>%
  dplyr::group_by(region)%>%
  dplyr::summarise(mean_length = mean(length,na.rm=T),
            perc_10 = quantile(length,.1,na.rm=T),
            perc_20 = quantile(length,.2,na.rm=T),
            perc_30 = quantile(length,.3,na.rm=T),
            perc_40 = quantile(length,.4,na.rm=T),
            perc_50 = quantile(length,.5,na.rm=T),
            perc_60 = quantile(length,.6,na.rm=T),
            perc_70 = quantile(length,.7,na.rm=T),
            perc_80 = quantile(length,.8,na.rm=T),
            perc_90 = quantile(length,.9,na.rm=T),
		read_count = n())%>%
  mutate(sample = sample, disease_status = disease)
    chr = bind_rows(chr,dat)
  }
}
# write output file for this chromosome

if(lasso){
fwrite(chr, paste("/data/nfs1/home/hgrant3/cancer_seek/shendure/chr_lassoregions_dist/chr",
                  j,".csv",sep = ""))

}

if(!lasso){

fwrite(chr, paste("/data/nfs1/home/hgrant3/cancer_seek/shendure/chr_10region_dist/chr",
                  j,".csv",sep = ""))

}
