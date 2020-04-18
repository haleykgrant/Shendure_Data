# Shendure_Data
Code for downloading, cleaning, and analyzing fragmentation data from Shendure paper (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4715266/)

Each file has a description of its contents as well as the location of the file and the location of the output.

Description on files:

# DATA

## all_files.txt

__Directory: shendure/sam_files/positions__

__Used in:__ `clean_positions.sh`


Text file with names of files produced from `get_positions.sh` that will be used to get the names of files that need to be cleaned in  `clean_positions.sh`

## RegionsOfAmplicons (Directory)

__Directory : shendure__

__Used in:__ `process_region_dist.R`

This directory contains files indicating the regions that each chromosome will be split into. The files (one per chromosome) indicate which of 10 regions each amplicon (from another dataset) falls into. To get the rough boundaries of each region, sort by region number and take the min and max of the "End" column. 

## RegionsOfAmpliconsLasso (Directory)

__Directory : shendure__

__Used in:__ `process_region_dist.R`

Similar to RegionsOfAmplicons. This directory contains files indicating the regions that each chromosome will be split into, with regions being selected using a Lasso method (not described here). The files (one per chromosome) indicate which of 18-20 regions each amplicon (from another dataset) falls into. To get the rough boundaries of each region, sort by region number and take the min and max of the "End" column. 

## SraRunTable.txt

__Directory : shendure__

__Used in:__ `process_region_dist.R`

This is a text file containing the sample information about each sample pulled in `srr_download.sh` including disease status, gender, etc.

## chris_amps.rds

__Directory: shendure__

__Used in:__ `process_shendure_amps.R`

This is an R data file with a data frame containing a list of all amplicons (with size>0) from the RealSeq primer as well as each amplicon's length, start, and stop position.


## albert_amps_filtered_41320.rds

__Directory: shendure__

__Used in:__ `process_shendure_amps.R`

This is an R data file with a data frame containing a list of amplicons selected after one round of pruning (from total amplicon list in `chris_amps.rds`) with each amplicon's length, start, and stop position.


## albert_amps_selected_41320.rds

__Directory: shendure__

__Used in:__ `process_shendure_amps.R`

This is an R data file with a data frame containing a list of amplicons selected after two round of pruning (from total amplicon list in `chris_amps.rds`) with each amplicon's length, start, and stop position.





# Scripts (R and shell)

## srr_download.sh

__Directory: shendure__

 This is a shell script to download SRR samples from GEO. The commands were obtained from https://sra-explorer.info/# using accession numbers from the [SRA Run Selector tool](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA291063&o=acc_s%3Aa&s=SRR2129993,SRR2129994,SRR2129995,SRR2129996,SRR2129997,SRR2129998,SRR2130000,SRR2130002,SRR2130003,SRR2130004,SRR2130005,SRR2130006,SRR2130007,SRR2130008,SRR2130009,SRR2130010,SRR2130011,SRR2130012,SRR2130013,SRR2130014,SRR2130015,SRR2130016,SRR2130017,SRR2130018,SRR2130019,SRR2130020,SRR2130021,SRR2130022,SRR2130023,SRR2130024,SRR2130025,SRR2130026,SRR2130027,SRR2130028,SRR2130029,SRR2130030,SRR2130031,SRR2130032,SRR2130033,SRR2130034,SRR2130035,SRR2130036,SRR2130037,SRR2130038,SRR2130039,SRR2130040,SRR2130041,SRR2130042,SRR2130043,SRR2130044,SRR2130045,SRR2130046,SRR2130047,SRR2130048,SRR2130050,SRR2130051,SRR2130052,SRR2129999,SRR2130001,SRR2130049).
 
 __Output to shendure directory.__
 
 
 ## bowtie_align.sh
 
__Directory: shendure__
 
 This is a shell script to run bowtie to align samples from the files downloaded in srr_download.sh. It uses hg19 as a reference with maximum insert size limit set at 800bp. The script produces SAM files (file extention `.sam`), which we will use to extract information about the samples.

The bowtie software can be installed using one of the following commands:
 
 `conda install -c bioconda bowtie`
 
`conda install -c bioconda/label/cf201901 bowtie`

hg19 can be downloaded from: http://bowtie-bio.sourceforge.net/md5s.shtml

__Output to shendure/sam_files directory.__

## get_positions.sh

__Directory: shendure/sam_files__

This is a shell script that uses the outputed .sam filed from `bowtie_align.sh` to extract the 3rd, 4th, and 9th columns of the SAM files, corresponding to:

* 3: chromosome number (reference name)
* 4: position (base pair position along reference)
* 9: length of fragment (nferred insert size)

The samtools software can be installed using one of the following commands:

`conda install -c bioconda samtools`

`conda install -c bioconda/label/cf201901 samtools`

__Output to shendure/sam_files/positions directory.__

## clean_positions.sh

__Directory: shendure/sam_files/positions__

Shell script to remove any lines that are either not aligned (chromosome column will be a * in the "all.txt" files) or have length reported as negative (from 2nd paired end read). This script helps clean the files in `all_files.txt` (output from `get_positions.sh`) to reduce file size to only include rows with useful information.

__Output to shendure/sam_files/positions directory.__

## process_all.R

__Directory: shendure__

R script to read in cleaned files with chromosome, position, and length from bowtie alignment (one per sample) and output 22 .csv files (one per chromosome) with position and length information for each read mapped to the corresponding chromosome.

## process_all.sh

__Directory: shendure__

Shell script to run `process_all.R` script in parallel. Header line `t 1-53` specifies to run the R script on each one of the 53 files in parallel (different compute nodes).

__Output to shendure directory.__

After getting all csv files I organize place them into a new directory `shendure/processed_data` then make separate chromosome directories `shendure/processed_data/chr1`,...,`shendure/processed_data/chr22`, each with 53 files containing fragment length and poisition information for each sample.

## process_region_dist.R

__Directory : shendure__

*Need to make output directories `chr_lassoregions_dist` and `chr_10regions_dist` before running!*

This R script takes sample information by chromosome and summarizes the data in the following way: for each chromosome we read in one file per sample. For each sample we group its (fragment) reads into regions (either lasso 18-20 or arbitrary 10 regions) then compute summary statistics for each region. These summary statistics include the mean fragment length as well as percentiles from 10th-90th percentile (increments of 10). We then combine all information for that chromosome to get a CSV file with one row per region and sample for a total of either 10 $\times$ 53 or 18-20 $\times$ 53 rows per chromosome file.

__Output to either chr_lassoregions_dist or chr_10regions_dist.__





