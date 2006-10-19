#!/usr/bin/perl -w

use strict;
my %tag_h=();
my $regexp = '';
my $noheader;
my $negate;
while ($ARGV[0] =~ /^\-.+/) {
    my $opt = shift @ARGV;
    if ($opt eq '-t' || $opt eq '--tag') {
        $tag_h{shift @ARGV} = 1;
    }
    if ($opt eq '-r' || $opt eq '--regexp') {
        $regexp = shift @ARGV;
    }
    if ($opt eq '--noheader') {
        $noheader = 1;
    }
    if ($opt eq '--neg') {
        $negate = 1;
    }
}

print_obo_header();

$/ = "\n\n";

while (@ARGV) {
    my $f = pop @ARGV;
    if ($f eq '-') {
        *F=*STDIN;
    }
    else {
        open(F,$f) || die $f;
    }
    while(<F>) {
        if ($negate) {
            if ($_ !~ /$regexp/) {
                print;
            }
        }
        else {
            if (/$regexp/) {
                print;
            }
        }
    }
}

exit 0;

sub print_obo_header {
    if ($noheader) {
        return;
    }
    print <<EOM;
format-version: 1.2
date: 23:09:2005 14:37
saved-by: obo-grep
default-namespace: none

EOM

}
