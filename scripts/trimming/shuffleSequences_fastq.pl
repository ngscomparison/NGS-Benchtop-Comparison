#!/usr/bin/perl

$filenameA = $ARGV[0];
$filenameB = $ARGV[1];
$filenameOut = $ARGV[2];

open $FILEA, "< $filenameA";
open $FILEB, "< $filenameB";

open $OUTFILE, "> $filenameOut";

while(<$FILEA>) {
	chomp;
	print $OUTFILE $_."\n";
	$_ = <$FILEA>;
	print $OUTFILE $_; 
	$_ = <$FILEA>;
	print $OUTFILE "+\n";
	$_ = <$FILEA>;
	print $OUTFILE $_; 

	$_ = <$FILEB>;
	chomp;
	print $OUTFILE $_."\n";
	$_ = <$FILEB>;
	print $OUTFILE $_;
	$_ = <$FILEB>;
	print $OUTFILE "+\n";
	$_ = <$FILEB>;
	print $OUTFILE $_;
}
