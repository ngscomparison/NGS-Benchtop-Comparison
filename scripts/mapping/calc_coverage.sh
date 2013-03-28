#!/bin/bash


min_args=1

if [ $# -eq $min_args ]; then        
        if [ -d $1 ]; then
                echo "file not exists"
              
        else
                #exists
                path=${1/.bam/} 
		
                samtools depth $path.bam > $path.cov
		# this ugly line adds uncovered positions in the coverage file, which where not reported by samtools
		cat $path.cov| awk 'BEGIN { prev_chr="";prev_pos=0;} { if($1==prev_chr && prev_pos+1!=int($2)) {for(i=prev_pos+1;i<int($2);++i) {printf("%s\t%d\t0\n",$1,i);}} print; prev_chr=$1;prev_pos=int($2);}' > $path.cov.ungapped
        fi

else
        echo "Compute the per base coverage of the reference genome"
        echo "File path of bam file"
fi

