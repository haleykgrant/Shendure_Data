#!/bin/bash
#$ -S /bin/bash
#$ -cwd 
#$ -l mem_free=100G,h_vmem=100G
#$ -e ../../sge/
#$ -o ../../sge/

# list of files output from get_positions
samples=all_files.txt
all_lines=`cat $samples`

for file in $all_lines;
do
filename=$(echo $file | cut -d '_' -f 1)

# get rid of any file with a * or - sign and outputt cleaned version
egrep -v "(\*|\-)" ${file}> "${filename}_all_cleaned.txt"

done

