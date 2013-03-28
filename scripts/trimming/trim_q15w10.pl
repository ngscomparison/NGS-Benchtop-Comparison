#!/usr/bin/env perl

use strict;
use Getopt::Std;

my $usage = "\nusage: cat fastq file | perl $0 -q <int> > output \n\n".
            "Input must be in Sanger fastq format which omne line per entry and phred score +33".
            "-q <int> : min mean qscore to trim for\n\n";

our($opt_q);
getopts('q:') or die $usage;
if (!defined($opt_q) or !($opt_q =~ m/^[0-9]+$/)) {
    $opt_q = 15;
}

my $head1; my $seq;
my $head2; my $qal;
my $step = 1;  my $window = 10;   
my $addEmpty = 0;
# read header, seqeunce, header, qaility
while ($head1 = <>) {  
	$seq = <>;  chomp $seq;
	$head2 = <>;
	$qal = <>; chomp $qal;
	my $pos = length($qal);
	$window = 10;
	# if sequence is maller than window, reduce the window size
	if ($pos < $window) {$window = $pos;}
	my $localMean =0;
	# while the quality mean of the window is below threshold, move the window
	while ($localMean < $opt_q && $pos > 0) {
	    $localMean=0;
	    # for the position in the q-string and for each substracting position of the window e.g. (1..10)
	    # sum up the qscores to localMean 9what map does) and calculate the mean by dividing by window size (what map returns)
	    $localMean /= map {$localMean+=(ord(substr($qal,$pos-$_, 1))-33)} (1..$window); 
	    # got next position
	    $pos--;
	    # if we read end of sequence, then reduce window size in order to verify also the first x bases (x=windowsize)
	    if ($pos < $window) {$window = $pos;}
    	}
	# we have found a window with qmean > threshold or the last window is exactly the first x bases of the sequence (x=window size), with no good window found
	if ($addEmpty && $pos <= $window && $localMean < $opt_q) {
	    # add pseudo entries (important for paired end data to keep ordering etc.) ! not used anymore, using seqeunce id based merging of seperately handled paire-end data instead (shuffle script)
	    $seq = "N\n";
	    $qal = "#\n";
	} elsif ($pos <= $window && $localMean < $opt_q) {
	    next;
	} {  
	    $seq = substr($seq,0,$pos+1)."\n";
	    $qal = substr($qal,0,$pos+1)."\n";
	}
	print $head1.$seq.$head2.$qal;
}


