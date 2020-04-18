#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l mem_free=100G,h_vmem=100G
#$ -e ../sge/
#$ -o ../sge/

#run this code in sam_files directory

# path to bin file with samtools installed
p=/data/nfs1/home/hgrant3/anaconda3/bin

mkdir positions

for filename in *.sam;
do

# specify name of output file (just use sample name)
output_name=$(echo $filename| cut -d'_' -f 1)
output_name=$(echo $output_name | cut -d '/' -f 2)

# pull fields 3, 4, and 9
$p/samtools view $filename | stdbuf -o0 cut -f 3-4,9 >> positions/${output_name}_all.txt

done

