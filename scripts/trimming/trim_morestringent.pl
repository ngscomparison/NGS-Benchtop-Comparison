#!/usr/bin/env perl

use strict;
use Getopt::Std;
use List::Util qw(min max);

my $usage = "\nusage: cat original.fastq | perl $0 -q <int> > trimmed.fastq\n\n".
            "Input must be in Sanger fastq format which omne line per entry and phred score +33".
            "-q <int> : min mean qscore to trim for\n\n";
our($opt_q);
getopts('q:') or die $usage;
if (!defined($opt_q) or !($opt_q =~ m/^[0-9]+$/)) {$opt_q = 15;}

my $h1;  my $s;  my $h2;  my $q;
my $step = 1;  my $window = 10;   
my $addEmpty = 0;
while ($h1 = <>) {  # read first header
	$s = <>; $h2 = <>; $q = <>;
	chomp $q; chomp $s;
	my $maxPos = length($q);
	my $pos =1;
	my $wstart = 0;
	my $wend = min($wstart+$window, $maxPos);
	my $localMean = 0;
	map {$localMean+=(ord(substr($q,$_, 1))-33)} ($wstart .. $wend-1);
	my $minMean = $wend * $opt_q;
	my $foundWindow = 0;
	while ($localMean >= $minMean && $wend < $maxPos) 
	{
	    $localMean +=( ord(substr($q,$wend++, 1))-33); 
	    $localMean -=( ord(substr($q,$wstart++, 1))-33); 
	    $foundWindow = 1;
	}
	if ($localMean < $minMean && $foundWindow ) {
	    my $trimPos = $wstart + (($wend - $wstart) /2);
	    $s = substr($s,0,$trimPos);
	    $q = substr($q,0,$trimPos);
	}elsif ($localMean < $minMean &! $foundWindow) {
	    next;
	}else {
	} 
	print $h1.$s."\n".$h2.$q."\n";
}


