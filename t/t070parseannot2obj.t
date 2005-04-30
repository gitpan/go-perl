#!/usr/local/bin/perl -w

use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 5;
}

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;

# ----- REQUIREMENTS -----

# ------------------------

my $parser = new GO::Parser ({format=>'go_ont',
			      handler=>'obj'});

#$parser->handler->add_root;
ok(1);
$parser->parse (shift @ARGV || "./t/data/generic.0208");
my $a2n = $parser->acc2name_h;
#$parser->parse (shift @ARGV || "./t/data/go-truncated.obo");
$parser = new GO::Parser ({format=>'go_assoc',
                           handler=>$parser->handler});
$parser->acc2name_h($a2n);
$parser->cache_errors;
$parser->parse (shift @ARGV || "./t/data/test-gene_association.fb");

# we expect one error because of the deliberately bogus last line
# refering to a non-existent GO ID
my @errs = $parser->errlist;
#print $_->sxpr foreach @errs;
ok(@errs == 1); # bogus last line

my $graph = $parser->handler->graph;
my $it = $graph->create_iterator;
while(my $node = $it->next_node_instance){
    my $term = $node->term;
    #use Data::Dumper;
    #print Dumper $graph;
    printf "TERM: %s %s\n", $term->acc, $term->name;
    my $assocs = $term->association_list;

    foreach my $assoc (@$assocs) {
        my $prod = 
          $assoc->gene_product;
        printf " PROD: %s\n", $prod->symbol;
    }
    #this causes an error
    my $deep_assocs = 
      $graph->deep_association_list($term->public_acc);
    printf "  *DEEP: %d\n", scalar(@$deep_assocs);
}

my $term = $graph->get_term('GO:0003673');
ok(!@{$term->association_list || []});
ok(@{$graph->deep_association_list('GO:0003673')} == 86);
#ok(@{$term->deep_association_list} == 86);

my $prods = $graph->deep_product_list($term->acc);
ok((grep {printf "Type:%s\n", $_->type;$_->type eq 'gene'} @$prods) == 16);
