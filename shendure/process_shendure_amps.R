library(pacman)
p_load(data.table, tidyverse, plyr, janitor)

# specify chromosome
i = as.integer(Sys.getenv("SGE_TASK_ID"))

# directory for aligned sample files
d=paste("/data/nfs1/home/hgrant3/cancer_seek/shendure/processed_data/chr",i,sep = "")


# list of files
samples=list.files(d)

# sample info
sample_df = read.delim("/data/nfs1/home/hgrant3/cancer_seek/shendure/SraRunTable.txt", sep = ",")%>%
  clean_names()%>%
  select(run, disease, sex)%>%
  mutate(disease=tolower(disease)%>%as.character(),
         run= as.character(run))%>%
  arrange(run)

cancers = sample_df$run[grep("cancer",as.character(sample_df$disease))]
normals = sample_df$run[grep("healthy",as.character(sample_df$disease))]

amplicon_type = c("filtered","selected","chris")

for(type in amplicon_type){

if(type == "filtered"){
# r data structure with amplicons
amps = readRDS("/data/nfs1/home/hgrant3/cancer_seek/shendure/albert_amps_filtered_41320.rds")
amps = amps[chr==paste("chr",i,sep="")]
}

if(type == "selected"){
amps = readRDS("/data/nfs1/home/hgrant3/cancer_seek/shendure/albert_amps_selected_41320.rds")
amps = amps[chr==paste("chr",i,sep="")]
}

if(type == "chris"){
amps = readRDS("/data/nfs1/home/hgrant3/cancer_seek/shendure/chris_amps.rds")
amps = amps[chr==paste("chr",i,sep="")]
}

# function to determine which reads intersect with any of the amplicons ( in either chris, filtered, or selected amplicon list)
frag_amp_intersection = function(dat,amps){
  amp_intervals = list(lower = amps$start, upper = amps$end)

  non_amps1 = list(lower = c(0,amps$end+1)[seq(1,length(amps$start)+1,by = 2)],
                   upper = c(amps$start-1,Inf)[seq(1,length(amps$start)+1,by = 2)])

  non_amps2 = list(lower = c(0,amps$end+1)[seq(2,length(amps$start)+1,by = 2)],
                  upper = c(amps$start-1,Inf)[seq(2,length(amps$start)+1,by = 2)])

return((dat[,end] %inrange% amp_intervals |
  dat[,pos] %inrange% amp_intervals |
  (dat[,pos] %inrange% non_amps1 & dat[,end] %inrange% non_amps2) |
          (dat[,pos] %inrange% non_amps2 & dat[,end] %inrange% non_amps1)))

}

# data table with just reads that overlap with given amplicons
chr_dat = data.table(data.frame(chrom = NULL, sample = NULL, disease = NULL,
                     pos = NULL, length = NULL, end = NULL))


for(j in 1:length(samples)){
  file = samples[j]
  sample = substr(file,1,10)
  print(sample)
  disease = ifelse(sum(grepl(sample,cancers))==1,"cancer",
                   ifelse(sum(grepl(sample,normals))==1,"normal","other"))
  if(disease %in% c("cancer","normal")){

        dat = fread(paste(d,"/",file,sep = ""),
              colClasses = c("character","numeric","numeric"))[, `:=`(end = pos + length)]

        num = sum(frag_amp_intersection(dat,amps))

        dat = dat[, amp := frag_amp_intersection(dat,amps) ][amp==TRUE][,`:=`(sample = rep(sample,num), disease = rep(disease,num))]

        dat = dat[,amp:=NULL]

        chr_dat = rbindlist(list(chr_dat,dat))
}


}

# write output file
 fwrite(chr_dat, file=paste("/data/nfs1/home/hgrant3/cancer_seek/shendure/amps_by_chrom/chr",i,"_",type,".csv" ,sep = ""))



