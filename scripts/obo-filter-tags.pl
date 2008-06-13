#!/usr/bin/perl -w

use strict;
my %tag_h=();
my $negate = 0;
while ($ARGV[0] =~ /^\-/) {
    my $opt = shift @ARGV;
    if ($opt eq '-h' || $opt eq '--help') {
        print usage();
        exit 0;
    }
    if ($opt eq '--neg') {
        $negate = 1;
    }
    if ($opt eq '-t' || $opt eq '--tag') {
        $tag_h{shift @ARGV} = 1;
    }
}
print STDERR "Tags: ", join(', ',keys %tag_h),"\n";

my $in_header = 1;
while(<>) {
    if (/^\[/) {
        $in_header=0;
    }
    if ($in_header) {
        print
    } else {
        if (/^(\w+):(.*)/) {
            if ($tag_h{$1}) {
                print
            } else {
                # FILTER
            }
        } else {
            print;
        }
    }
}

exit 0;

sub scriptname {
    my @p = split(/\//,$0);
    pop @p;
}


sub usage {
    my $sn = scriptname();

    <<EOM;
$sn [-t tag]* BASE-FILE FILE-TO-MERGE1 [FILE-TO-MERGE2...]

merges in tags to base file

Example:

$sn  -t intersection_of -t id-mapping gene_ontology.obo go_xp_cell.obo go_xp_chebi.obo 

EOM
}

