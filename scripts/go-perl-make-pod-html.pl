#!/usr/bin/perl -w
use strict;

while (<>) {
    chomp;
    my $f = $_;
    my @path = split(/\//, $f);
    my $lf = pop @path;
    if ($lf =~ /(.*)\.(\S+)$/) {
        my $n = $1;
        my $sfx = $2;
        if ($sfx eq 'pm' || $sfx eq 'pl' || $sfx eq 'pod') {
            print STDERR "Making pod for $lf\n";
            my $dir = join('/', 'pod', @path);
            my $title = 
              join('::',@path,$n);
            `mkdir -p $dir` unless -d $dir;
            my $outf = $dir . '/'. $n . '.html';
            system("pod2html --htmlroot /dev/pod --title $title $f > $outf");
        }
    }
    elsif ($path[-1] eq 'scripts') {
        print STDERR "Making pod for $lf\n";
        my $dir = join('/', 'pod', @path);
        my $title = 
          join('::',@path,$lf);
        `mkdir -p $dir` unless -d $dir;
        my $outf = $dir . '/'. $lf . '.html';
        system("pod2html --htmlroot /dev/pod --title $title $f > $outf");

    }
    else {
    }
}
