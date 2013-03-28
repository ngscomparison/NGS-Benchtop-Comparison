#! /usr/bin/env perl 
use strict;
use warnings;

#reads the coverage file and reports the mean coverage (for all contigs/chromosomes)
#coverage file is three columned, first = ref, second = pos, third = coverage

open COV, "<$ARGV[0]" || die $!;
my ($num, $totNum, $totDen, $den, $activePos)= (0,0,0,0,0);
my $lastRef = "";
while (my $line=<COV>) {
    my ($ref, $pos, $cov) = split(" ", $line);
    if ($pos < $activePos) {
	#print "$lastRef:".($num/$den).", ";
	print "".($num/$den)."\t";
	$num=0; 
	$den=0;
	$activePos = 0;
    } 
    $activePos++;
    $num+=$cov;
    $totNum+=$cov;
    $totDen++;
    $den++;
    $lastRef = $ref;
        print "".($num/$den)."\t" if eof;
}
close COV;
print "".($totNum/$totDen)."\n";

