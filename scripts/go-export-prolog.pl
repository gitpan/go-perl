#!/usr/local/bin/perl -w

use strict;
use GO::Parser;
use Getopt::Long;
use Data::Dumper;

my $opt = {};
GetOptions($opt,
           "format|f=s",
           "handler|h=s",
           "force_namespace=s",
           "expand|e");

my @fns = @ARGV;

my $fmt = $opt->{format};

my $parser =
  new GO::Parser (format=>$fmt, handler=>'prolog');
if ($opt->{force_namespace}) {
    $parser->force_namespace($opt->{force_namespace});
}
$parser->parse (@fns);
