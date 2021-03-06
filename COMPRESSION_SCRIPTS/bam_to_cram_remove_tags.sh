# ---qsub parameter settings---
# --these can be overrode at qsub invocation--

# tell sge to execute in bash
#$ -S /bin/bash

# tell sge to submit any of these queue when available
#$ -q rnd.q,prod.q,test.q

# tell sge that you are in the users current working directory
#$ -cwd

# tell sge to export the users environment variables
#$ -V

# tell sge to submit at this priority setting
#$ -p -1020

# tell sge to output both stderr and stdout to the same file
#$ -j y

# export all variables, useful to find out what compute node the program was executed on
# redirecting stderr/stdout to file as a log.

# Reference genome used for creating BAM file. Needs to be indexed with samtools faidx (would have ref.fasta.fai companion file)

IN_BAM=$1
DIR_TO_PARSE=$2
REF_GENOME=$3
CRAM_DIR=$(echo $IN_BAM | sed -r 's/BAM.*/CRAM/g')
SM_TAG=$(basename $IN_BAM .bam) 
BAM_FILE_SIZE=$(du -ab $IN_BAM | awk '{print ($1/1024/1024/1024)}')
set

START_CRAM=`date '+%s'`

mkdir -p $CRAM_DIR

SAMTOOLS_EXEC=/isilon/sequencing/Kurt/Programs/samtools/samtools-1.6/samtools
# For further information: http://www.htslib.org/doc/samtools.html

if [[ ! -e $DIR_TO_PARSE/cram_compression_times.csv ]]
	then
		echo -e SAMPLE,PROCESS,ORIGINAL_BAM_SIZE,CRAM_SIZE,START_TIME,END_TIME >| $DIR_TO_PARSE/cram_compression_times.csv
fi


# Use samtools-1.6 devel to convert a bam file to a cram file with no error
 $SAMTOOLS_EXEC view -C $IN_BAM -x BQ -o $CRAM_DIR/$SM_TAG".cram" -T $REF_GENOME -@ 4

# Use samtools-1.6 devel to create an index file for the recently created cram file with the extension .crai
$SAMTOOLS_EXEC index $CRAM_DIR/$SM_TAG".cram"
cp $CRAM_DIR/$SM_TAG".cram.crai" $CRAM_DIR/$SM_TAG".crai"

# create a md5 hashsum for the cram file

md5sum $CRAM_DIR/$SM_TAG".cram" \
>| $CRAM_DIR/$SM_TAG".cram.md5"

CRAM_FILE_SIZE=$(du -ab $CRAM_DIR/$SM_TAG".cram" | awk '{print ($1/1024/1024/1024)}')

END_CRAM=`date '+%s'`

# md5sum $CRAM_DIR/$SM_TAG".cram" >> $DIR_TO_PARSE/MD5_REPORTS/cram_md5.list
# md5sum $CRAM_DIR/$SM_TAG".crai" >> $DIR_TO_PARSE/MD5_REPORTS/cram_md5.list

echo $IN_BAM,CRAM,$BAM_FILE_SIZE,$CRAM_FILE_SIZE,$START_CRAM,$END_CRAM \
>> $DIR_TO_PARSE/cram_compression_times.csv
