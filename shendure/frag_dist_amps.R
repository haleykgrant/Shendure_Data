library(pacman)
p_load(plyr, readr, ggplot2, tidyverse, data.table)


types = c("filtered","selected","chris","top21")
intersection = c("full","any")

for(type in types){


for(int_type in intersection){
d = "/data/nfs1/home/hgrant3/cancer_seek/shendure/amps_by_chrom"
d = paste(d,"/",type,sep = "")
d = paste(d,"/",int_type,"_intersect",sep = "")

myfiles = paste(d,"/",list.files(d),sep = "")

dist = ldply(myfiles, read_csv)%>%
	group_by(disease, length,sample)%>%
	tally()

write.csv(dist, paste("frag_amp_dist_",int_type,"_",type,".csv",sep=""))
}
}
 
