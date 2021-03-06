#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use Tie::File;

#arguments 
# 1: the assembly output dir as generated by the RUN_ASSEMBLY_PIPELINE.sh pipeline  
# 2: reference fasta

my $contigs = ""; 

$contigs .= join ("\t" , ("sample","#Contigs", "Tot. Contig size", "Longest C", "Shortest C", "C > 1K nt", "C > 10K nt", "C > 100K nt", "Mean C size", "#Reads assembled", "Avg. coverage", "N50", "N90", "N95"))."\n";

my $pass=$ARGV[0];
chomp($pass);
$contigs .=  $pass."\t";

my $contigsCSV = $pass."_assembly/".$pass."_d_results/".$pass."_out.unpadded.csv";
tie my @csv, 'Tie::File', $contigsCSV or die "error: $! $contigsCSV\n";
my @values =  split(",",$csv[-1]);
foreach (34, 37, 38, 39, 40, 42, 44, 50) {$contigs.=$values[$_]."\t";}

my $contigStats = $pass."_assembly/".$pass."_d_info/".$pass."_info_assembly.txt";
open (STATS, "<", $contigStats) or die "error: $! $contigStats \n";
my $all = undef;
my $stats = {};
while(<STATS>) {
    chomp;
    if ($_ =~ /(Num. reads assembled):\s+(\d+)/) {$stats->{1}=$2;}
    elsif ($_ =~ /(Avg. total coverage):\s+([\d\.]+)/) {$stats->{2} = $2;}
    elsif ($_ =~ /All contigs:/){$all=1;}
    elsif ($all && $_ =~ /(N50 contig size):\s+([\d\.]+)/) {$stats->{3}=$2;}
    elsif ($all && $_ =~ /(N90 contig size):\s+([\d\.]+)/) {$stats->{4}=$2;}
    elsif ($all && $_ =~ /(N95 contig size):\s+([\d\.]+)/) {$stats->{5}=$2;}
}
foreach (1..5) {$contigs.=$stats->{$_}."\t";}
$contigs.="\n";

open (SUMMARY, ">", "assembly_summary.csv");
print SUMMARY $contigs;
close SUMMARY;

