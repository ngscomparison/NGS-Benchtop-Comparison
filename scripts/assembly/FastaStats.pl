#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Std;

sub usage {
    my ($msg) = @_;
    print STDERR <<EOF;
    $msg
    usage: $0 [-q] fastq | [-f] fasta

    Prints general statistics (read length, number of reads and bases) of a fasta or fastq file to standard out.
    -h        : this (help) message
    -q file   : fastq input file
    -f file   : fasta input file
EOF
    exit;
}

my %options = ();
my $stats = {"totalB" => 0, "totalR" => 0, "min" => 99999999, "max" => 0};
my $seqLengths = [];
my $lengthHist = {};

getopts( "hq:f:", \%options ) or usage;
usage() if $options{h};
die usage("\n\tERROR: Please specify a input fasta or fastq file\n") unless ( defined $options{q} || defined $options{f});
die usage("\n\tERROR: Please specify either a fasta or a fastq input file\n") if ( defined $options{q} && defined $options{f});
my $reader;
if (defined $options{q}) {
    $reader = sub { _read_fastq_file($options{q}, \&parser_callback)};
} else {
    $reader = sub { _read_fasta_file($options{f}, \&parser_callback)};
}

sub _read_fasta_file {
    my ($f, $callback) = @_;
    open(F, $f) or die "Cannot read $f\n";
    next unless ref($callback);
    my $name;
    my $sequence;
    while (<F>) {
        chomp;
        # remove ^M's..
        s/\015//g;
        if (/^>(\S+)/) {
            if ($name) {
                &$callback($sequence);
            }
            $name = $1;
            $sequence = "";
        }
        else {
            $sequence .= $_;
        }
    }
    if ($name) {
        &$callback($sequence);
    }
    close(F);
}

sub _read_fastq_file {
    my ($f, $callback) = @_;
    open(F, $f) or die "Cannot read $f\n";
    next unless ref($callback);
    while (<F>) {
        chomp;
        s/\015//g;
	if ($.%4==2) {
            &$callback($_);
	}
    }
    close(F)
}

sub parser_callback {
    my ($seq) = @_;
    my $seqL = length($seq);
    $stats->{"totalB"} += $seqL;
    $stats->{"totalR"} ++;
    push(@$seqLengths, $seqL);
    if (defined $lengthHist->{$seqL}) { $lengthHist->{$seqL} = $lengthHist->{$seqL}+1; } else {$lengthHist->{$seqL} = 1;} 
    $stats->{"max"} = $seqL if $seqL > $stats->{"max"};
    $stats->{"min"} = $seqL if $seqL < $stats->{"min"};
}

sub min { 
    return unless @_;
    return $_[0] unless @_ > 1;
    my $min= shift;
    foreach(@_) { $min= $_ if $_ < $min; }
    return $min;
}

sub max { 
    return unless @_;
    return $_[0] unless @_ > 1;
    my $max= shift;
    foreach(@_) { $max= $_ if $_ > $max; }
    return $max;
}

sub mean {
    return unless @_;
    return $_[0] unless @_ > 1;
    return sum(@_)/scalar(@_);
}


sub median {
    return unless @_;
    return $_[0] unless @_ > 1;
    @_= sort{$a<=>$b}@_;
    return $_[$#_/2] if @_&1;
    my $mid= @_/2;
    return ($_[$mid-1]+$_[$mid])/2;
}

sub mode {
    return unless @_;
    return $_[0] unless @_ > 1;
    my %count;
    foreach(@_) { $count{$_}++; }
    my $maxhits= max(values %count);
    foreach(keys %count) { delete $count{$_} unless $count{$_} == $maxhits; }
    return mean(keys %count);
}

sub variance {
    return unless @_;
    return 0 unless @_ > 1;
    my $mean= mean @_;
    return (sum(map { ($_ - $mean)**2 } @_)) / $#_;
}

sub range {
    return unless @_;
    return 0 unless @_ > 1;
    return abs($_[1]-$_[0]) unless @_ > 2;
    my $min= shift; my $max= $min;
    foreach(@_) { $min= $_ if $_ < $min; $max= $_ if $_ > $max; }
    return $max - $min;
}

sub sum {
    return unless @_;
    return $_[0] unless @_ > 1;
    my $sum;
    foreach(@_) { $sum+= $_; }
    return $sum;
}

sub stddev {
    return unless @_;
    return 0 unless @_ > 1;
    return sqrt variance @_;
}

sub printhist {
    my ($h) = @_;    
    my $ph;
    foreach(sort {$a<=>$b} keys(%$h)) {$ph.= sprintf("%d\t%d\n",$_, $h->{$_});}
    return $ph;
}

sub computeStats {
    return unless @_;
    my ($s, $l, $h) = @_;
    $s->{"median"} = median(@$l);
    $s->{"mean"} = mean(@$l);
    $s->{"sd"} = stddev(@$l);
    $s->{"mode"} = mode(@$l);
    $s->{"range"} = range(@$l);
    $s->{"hist"} = printhist($h);
}



&$reader;
computeStats($stats, $seqLengths, $lengthHist);

printf "Bases:	%d\n", $stats->{"totalB"};
printf "Reads:	%d\n", $stats->{"totalR"};
printf "Max length: %d\n", $stats->{"max"};
printf "Mean length:	%f\n", $stats->{"mean"};
printf "Median length:	%d\n", $stats->{"median"};
printf "Min length: %d\n", $stats->{"min"};
printf "Mode length:	%f\n", $stats->{"mode"};
printf "Range length:	%f\n", $stats->{"range"};
printf "SD length:  %.2f\n", $stats->{"sd"};
printf "\n #Length Histogram: \n%s\n", $stats->{"hist"};

