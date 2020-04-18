library(pacman)
p_load(plyr, readr, ggplot2, tidyverse, data.table)


types = c("filtered","selected","chris")

for(type in types){

d = "/data/nfs1/home/hgrant3/cancer_seek/shendure/amps_by_chrom"
d = paste(d,"/",type,sep = "")

myfiles = paste(d,"/",list.files(d),sep = "")

# read in and stack all csv files and get counts for each length
dist = ldply(myfiles, read_csv)%>%
        group_by(disease, length,sample)%>%
        tally()

write.csv(dist, paste("frag_amp_dist_",type,".csv",sep=""))
}

