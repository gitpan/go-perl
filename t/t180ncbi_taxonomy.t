#!/usr/local/bin/perl -w

use lib '.';
use constant NUMTESTS => 2;
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => NUMTESTS;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;

# ----- REQUIREMENTS -----

# ncbi_taxonomy roundtrips
# this test involves class properties

# ------------------------

if (1) {
    my $f = './t/data/sample.ncbi_taxonomy';
    my $f2 = cvt($f,'ncbi_taxonomy','obo');
    
    my $parser = new GO::Parser;
    $parser->parse($f2);
    my $obo = $parser->handler->stag;
    ok($obo->get('header/synonymtypedef'));
    ok($obo->get('term/synonym/@/synonym_type'));
}
exit 0;

sub cvt {
    my $f = shift;
    my ($from, $to) = @_;
    print "$f from:$from to:$to\n";

    my $parser = new GO::Parser ({format=>$from,
				  handler=>$to});
    my $outf = "$f.$to";
    unlink $outf if -f $outf;
    $parser->handler->file($outf);
    $parser->parse($f);
    return $outf;
}
