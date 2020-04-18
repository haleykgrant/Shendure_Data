#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -o sge/
#$ -e sge/
#$ -l mem_free=100,h_vmem=100G


path=/data/nfs1/home/hgrant3/anaconda3/bin

$path/Rscript frag_dist_amps.R
