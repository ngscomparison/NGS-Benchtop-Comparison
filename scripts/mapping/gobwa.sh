#!/bin/bash
# author: Nick Loman
# based on: https://github.com/nickloman/benchtop-sequencing-comparison/tree/master/scripts

#Set the path to the location were bwa is installed
min_args=3
execDir=$(dirname $0)

if [ $# -eq $min_args ]; then        
	tag=$1
	reads=$2
	ref=$3
	threads=4
	
	if [ ! -r ${ref}.amb ]; then
	    echo "Start indexing of reference"
	    bwa index ${ref}
	    echo "finish indexing of reference"	   
	else
	    echo "index file exists"
	fi


	bwa bwasw -f $tag.sam -t $threads $ref $reads 
	${execDir}/filter_unique.pl $tag.sam 0 > $tag.uni.sam
	samtools view -bS $tag.uni.sam > $tag.uni.bam 
	samtools calmd -eb $tag.uni.bam $ref > $tag.uni.calmd.bam
	rm $tag.uni.bam
	samtools sort $tag.uni.calmd.bam $tag.uni.sorted
	rm $tag.uni.calmd.bam
	samtools index $tag.uni.sorted.bam
else
  echo "Run bwasw plus samtools to create a sorted mapped read file."
  echo "1: Output prefix"
  echo "2: Raw read file"
  echo "3: Reference file"
fi
