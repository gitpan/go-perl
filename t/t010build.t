#!/usr/local/bin/perl -w

use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 4;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;
use GO::ObjCache;

# ----- REQUIREMENTS -----

# This test script tests the following requirements:/x
# GO::Model::Graph must implement the GO::Builder interface; ie
# it should be possible to pass in a graph to a parser and have it build
# up a graph object

# ------------------------

my $parser = new GO::Parser ({format=>'go_ont',
			      handler=>'obj'});
my $graph = $parser->handler->g;
ok(1);
$parser->parse ("./t/data/test-function.dat");
ok($parser->acc2name_h->{'GO:0003677'} = 'DNA binding');

# lets check we got stuff

#print $graph->dump;
my $t = $graph->get_term("GO:0003677");
ok($t);
ok(1);
