library(pacman)
p_load(data.table, tidyverse, plyr, janitor)

# specify amplicon and intersection type
i = as.integer(Sys.getenv("SGE_TASK_ID"))

if(i<=4){
  i_type = "full"
}
if(i>4){
  i_type = "any"
}

if(i %% 4 == 1){
  a_type = "chris"
}
if(i %% 4 == 2){
  a_type = "filtered"
}
if(i %% 4 == 3){
  a_type = "selected"
}
if(i %% 4 == 0){
  a_type = "top21"
}
  


if(a_type == "filtered"){
  amps = readRDS("/data/nfs1/home/hgrant3/cancer_seek/shendure/albert_amps_filtered_41320.rds")
}

if(a_type == "selected"){
  amps = readRDS("/data/nfs1/home/hgrant3/cancer_seek/shendure/albert_amps_selected_41320.rds")
}

if(a_type == "chris"){
  amps = readRDS("/data/nfs1/home/hgrant3/cancer_seek/shendure/chris_amps.rds")
}

if(a_type == "top21" ){
  amps = readRDS("/data/nfs1/home/hgrant3/cancer_seek/shendure/top21.rds")
}

top21_chrs = c(1,10,12,13,14,15,16,19,2,3,5,7,8)

d = "/data/nfs1/home/hgrant3/cancer_seek/shendure/amps_by_chrom"
d = paste(d,"/",a_type,"/",i_type, "_intersect",sep = "")

files = list.files(d)

df = data.table(data.frame(chrom = NULL, sample = NULL, disease = NULL, 
                           pos = NULL, length = NULL, end = NULL,
                           amplicon = NULL, amp_length = NULL))

for(i in 1:22){
  if(a_type=="top21" & !(i %in% top21_chrs)){next}

  chr = paste("chr",i,"_",sep = "")
  ind = grep(chr,files)
  
  dat = fread(paste(d,"/",files[ind],sep = "") )
  amps = amps[chr==paste("chr",i,sep="")]

  which_amp = function(dat,amps){
    closest_amp = c()
    amp_len = c()
    for(i in 1:nrow(dat)){
      chr_pos = dat[i,pos]
      amp_index = which.min(abs(amps$start-chr_pos))
      a = paste(amps$chr[amp_index],amps$id[amp_index],sep = "_")
      len = amps$length[amp_index]
      closest_amp = c(closest_amp,a)
      amp_len = c(amp_len, len)
    }
    
    out_list = list(closest_amp = closest_amp, amp_length = amp_len)
    return(out_list)
  }
  
  dat = dat[,`:=` (amplicon = which_amp(dat,amps)$closest_amp, amp_length = which_amp(dat,amps)$amp_length )]
  
  df = rbindlist(list(df,dat))
}

fwrite(chr_dat, file=paste("/data/nfs1/home/hgrant3/cancer_seek/shendure/",
a_type,"_",i_type,"_intersect_", "with_amps.csv" ,sep = ""))






