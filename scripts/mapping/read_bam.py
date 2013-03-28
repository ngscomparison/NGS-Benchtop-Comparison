#!/usr/bin/env python
# author: Nick Loman
# taken from: https://github.com/nickloman/benchtop-sequencing-comparison/tree/master/scripts

import pysam
import sys
from runutils import read_run_details
from Bio import SeqIO


def _usage(str):
    print "Usage:", sys.argv[0], "meta file, reference file"
    print "Example:", sys.argv[0], "alignment.txt ref.fa"
    print str
    sys.exit(1)
    
print len(sys.argv)
if len(sys.argv) !=3:
    _usage("") 
    

reference = dict([(rec.id, rec) for rec in SeqIO.parse(sys.argv[2], "fasta")])

def has_masked(s):
        return len([c for c in s if c.islower()])

MINIMUM_MAPPING_QUALITY = 1

print "sample\tref\trid\tmapped\tmapq\tinsertions\tl_insertions\tdeletions\tl_deletions\trlen\tsubst"

samples = read_run_details(sys.argv[1])

for sample in samples:
	mapped = 0
	unmapped = 0

	samfile = pysam.Samfile(sample['Path'], "rb")
	id = 1
	for read in samfile:
		if read.is_unmapped or \
		read.mapq < MINIMUM_MAPPING_QUALITY or \
		has_masked(str(reference[samfile.getrname(read.tid)][read.pos : read.pos + read.alen].seq)):
			unmapped += 1
			print "%s\t%s\t%s\t0\t0\t0\t0\t0\t0\t%s\t0" % (sample['Description'], sample['Reference'], id, read.qlen)
			#print "%s\t%s\t%s\t0\t0\t0\t0\t0\t0\t%s" % (sample['Description'], sample['Reference'], id, read.qlen)
		else:  
			#if id == 11:
			 #   sys.exit(0)
			mis=0
			#Runs over the MD string and counts the occured Characters == mismatchs/deletions
			#chaneg by jueneman	
			#MD=read.tags[6][1] 
			MD=None 
			for readtag in read.tags:
			    if readtag[0] == 'MD':
				MD=readtag[1]
			if MD is None:
			    print >> sys.stderr, "Warning, no MD tag found for ",id,". Flags were: ",read.tags,". Skipping this entry as unmapped \n" 
			    unmapped += 1	
			    print "%s\t%s\t%s\t0\t0\t0\t0\t0\t0\t%s\t0" % (sample['Description'], sample['Reference'], id, read.qlen)
			    next
			flag=1
			for i in range(len(MD)):
			  char=MD[i]
			
			  if MD[i]=='^':
			    flag=2
			    
			  if MD[i].isalpha():
			    #print MD[i]
			    if i==0:
			      mis=mis+1
			    elif flag!= 2:    #if it is no deletion.
			      mis=mis+1
			      
			  if MD[i] != '^' and not MD[i].isalpha():
			    flag=1
			   
			#print MD
			#print mis
			   
			
			mapped += 1
	
			discrete_insertions = 0
			discrete_deletions = 0

			length_insertions = 0
			length_deletions = 0
			
			mismatch = 0

			for flag, bases in read.cigar:
				if flag == 1:
					discrete_insertions += 1
					length_insertions += bases
				if flag == 2:
					discrete_deletions += 1
					length_deletions += bases
					
			
			mismatch = mismatch + read.tags[5][1]
			
			print "%s\t%s\t%s\t1\t%s\t%s\t%s\t%s\t%s\t%s\t%s" % (sample['Description'], sample['Reference'], id, read.mapq, discrete_insertions, length_insertions, discrete_deletions, length_deletions, read.qlen,mis)
		id += 1
	print >>sys.stderr, sample['Path'], mapped, unmapped

