#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l mem_free=100G,h_vmem=100G
#$ -e sge/
#$ -o sge/

# set path to directory containing downloaded files
d=/data/nfs1/home/hgrant3/cancer_seek/shendure

samplefile=$d/sra_names.txt;
all_lines=`cat $samplefile`

mkdir sam_files

for sample in $all_lines;
do
# create variable for paired end files
f1=$d/zipped_samples/${sample}_1.fastq.gz;
f2=$d/zippeed_sample/${sample}_2.fastq.gz;

# unzip
gunzip -c $f1 >"${sample}_1.fastq";
gunzip -c $f2 >"${sample}_2.fastq";

# reset names to unzipped file
f1_unzipped=$d/${sample}_1.fastq;
f2_unzipped=$d/${sample}_2.fastq;

# run bowtie alignment
../../anaconda3/bin/bowtie --chunkmbs 200 --maxins 800 -v 2 --threads 4 --sam ../../anaconda3/bin/hg19 -1 $f1_unzipped -2 $f2_unzipped > ./sam_files/"${sample}_aligned.sam"

# remove unzipped files to save space
rm $f1_unzipped
rm $f2_unzipped

done
