#!/usr/bin/env perl 

use strict;
use warnings;
use Data::Dumper;

my $usage = << "USE";

	Usage: filters uniquely mapped reads from sam file (tested with: bwa, bowtie, shrimp, ngm)
	perl filter_unique.pl <sam file> <number of reads>
	
	Example:
		perl filter_unique.pl results.sam `grep -c ">" read_file.fa` > unique_reads.sam
USE

my $argcount = $#ARGV + 1;
my $reqArgs = 2;
$argcount >= $reqArgs or die "$usage";


my $file_path = $ARGV[0];
my $overall = $ARGV[1];
my $eval = "";

if($argcount == 3) {
	$eval = $ARGV[2];
}

my %mapped_id = ();

my $last_id = -100;
my $last_line;
my $count = -1;

my $unique = 0;
my $not_unique = 0;
my $number = 0;
my $notmapped = 0;

my $overall_found = 0;

open(FHI, "<$file_path") or die "Unable to open file $file_path \n";
while(<FHI>) {
	chomp;
	
	#if(/^([0-9]+)\t([0-9])/) {	
	if(/^([^@].*?)\t([0-9]+)/) {
		if($2 & 4) {
			$notmapped += 1;
			$overall_found += 1;	
		} else {
			if($count > -1) {							
				if($1 eq $last_id) {
					$count += 1;
				} else {
					$overall_found += 1;
					my $bwasw_equal = 0;
					if($last_line =~ /XS:i:([0-9]+)/) {
						my $xs = int($1);	
						$last_line =~ /AS:i:([0-9]+)/;		
						my $as = int($1);
						$bwasw_equal = (abs($as - $xs) < 1);
					}
					if($count == 0 && $last_line !~ /XA:Z:/ && !$bwasw_equal) {
						$last_line =~ /^([^@].*?)\t([0-9]+)/;						
						if(!$eval) {
							print $last_line . "\n";
						} else {
							$mapped_id{$1} = 1;
						}					
						$unique += 1;
					} else {
						$not_unique += 1;						
					}
					$number += 1;
					$_ =~ /^([^@].*?)\t([0-9]+)/;
					$last_id = $1;
					$last_line = $_;
					$count = 0;
				}
			} else {
				#First read
				$_ =~ /^([^@].*?)\t([0-9]+)/;
				$last_id = $1;
				$last_line = $_;
				$count = 0;
			}
		}
	} else {
		print $_ . "\n";
	}
}
close(FHI);

$overall_found += 1;
if($count == 0 && $last_line !~ /XA:Z:/) {
	if(!$eval) {
		print $last_line . "\n";
	} else {
		$mapped_id{$1} = 1;
	}					
	$unique += 1;
} else {
	$not_unique += 1;						
}
$number += 1;

print STDERR "Reads in file:\t\t$overall\n";
print STDERR "Reads found:\t\t$overall_found\n";
if($overall != 0) {
	print STDERR "Reads mapped:\t\t$number (" . ($number / $overall * 100) . "%)\n";
	print STDERR "  Uniquely mapped:\t$unique (" . ($unique / $overall * 100) . "%)\n";
	print STDERR "  Not uniquly mapped:\t$not_unique (" . (($not_unique) / $overall * 100) . "%)\n";
	if($notmapped == 0) {           
	        $notmapped = $overall - $unique - $not_unique;
	        print STDERR "Not mapped (calc):\t$notmapped (" . ($notmapped / $overall * 100) . "%)\n"; 
	        print STDERR "Sam file didn't contain unmapped reads.\n";
	} else {
	        print STDERR "Not mapped (found):\t$notmapped (" . ($notmapped / $overall * 100) . "%)\n";
	}
} else {
        print STDERR "Reads mapped:\t\t$number\n";
        print STDERR "  Uniquely mapped:\t$unique\n";
        print STDERR "  Not uniquly mapped:\t$not_unique\n";
	print STDERR "Not mapped (found):\t$notmapped\n";
}


my $sum = $unique + $not_unique + $notmapped;
if($sum != $overall && $overall != 0) {
	print STDERR "Error: Sum of (uniquely) mapped and unmapped reads does not match the total number of reads.\n";
	exit(1);
}

#print STDERR keys(%mapped_id) . "\n";

#open(FHI, "<$file_path") or die "Unable to open file $file_path \n";
#while(<FHI>) {
#	chomp;
	
#}
