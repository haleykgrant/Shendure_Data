#$ -S /bin/bash
#$ -cwd
#$ -o sge/
#$ -e sge/
#$ -l mem_free=100,h_vmem=100G
#$ -j y
#$ -t 1-53 


path=/data/nfs1/home/hgrant3/anaconda3/bin

$path/Rscript process_all.R
