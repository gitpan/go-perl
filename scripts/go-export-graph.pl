#!/usr/local/bin/perl

use strict;
use GO::Basic;
use GO::Dotty::Dotty;

use Getopt::Long;

my $w = 'text';
GetOptions("write|w=s"=>\$w);

my $graph = parse(shift @ARGV);
my $subgraph = $graph->subgraph({@ARGV});
if ($w eq 'text') {
    $subgraph->to_text_output;
}
elsif ($w eq 'obo') {
    $subgraph->to_obo;
}
else {
    my $graphviz =
      GO::Dotty::Dotty::go_graph_to_graphviz( $subgraph,
                                              {node => {shape => 'box'},
                                              });
    print $graphviz->as_png;
}
