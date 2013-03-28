#!/usr/bin/env perl

use strict;
use Getopt::Std;

my $usage = "\nusage: cat fastq file | perl $0 > output \n\n".
            "Input must be in Sanger fastq format which omne line per entry and phred score +33 \n\n".

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
	my $pos = length($qal)-1;
	my $localBase = ord(substr($qal,$pos, 1))-33;
	# while last base is below threshold, go on
	while ($localBase < 3 && --$pos > 0) {
	    $localBase = ord(substr($qal,$pos, 1))-33;
    	}
	if ($pos == 0 && $addEmpty && $localBase < 3) {
	    # add pseudo entries (important for paired end data to keep ordering etc.) ! not used anymore, using seqeunce id based merging of seperately handled paire-end data instead (shuffle script)
	    $seq = "N\n";
	    $qal = "#\n";
	} elsif ($pos == 0 && $localBase < 3) {
	    next;
	}{
            $seq = substr($seq,0,$pos+1)."\n";
	    $qal = substr($qal,0,$pos+1)."\n";
	}
	print $head1.$seq.$head2.$qal;
}


