library(pacman)
p_load(data.table, tidyverse, plyr)

memory.limit(size=50000)

# path to cleaned output files from bowtie alignment

d="/data/nfs1/home/hgrant3/cancer_seek/shendure/sam_files/positions/"

samples=list.files(d)[which(endsWith(list.files(d),"all_cleaned.txt"))]

# run in parallel- one per sample
i = as.integer(Sys.getenv("SGE_TASK_ID"))
  file=samples[i]
print(file)
# create one file per chromosome
for(j in 1:22){
  dat = read.delim(paste(d,samples[i],sep = ""),
         col.names = c("chrom","pos","length"))%>%
        filter(chrom==paste("chr",j,sep="")& as.numeric(length)>0)

  name = substr(samples[i],1,10)

 fwrite(dat, file=paste(name,"_",j, "_all.csv",sep = ""))


}
~
