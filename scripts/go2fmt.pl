#!/usr/local/bin/perl

# POD docs at end of file

use strict;
use Getopt::Long;
use FileHandle;
use Data::Stag;
use GO::Parser;

my $opt = {};
GetOptions($opt,
	   "help|h",
           "format|p=s",
           "datatype|t=s",
	   "err|e=s",
           "handler_args|a=s%",
           "handler|w|writer=s",
	  );

if ($opt->{help}) {
    system("perldoc $0");
    exit;
}


my $errf = $opt->{err};
my $errhandler = Data::Stag->getformathandler('xml');
if ($errf) {
    $errhandler->file($errf);
}
else {
    $errhandler->fh(\*STDERR);
}

my $p = GO::Parser->new;
my @files = $p->normalize_files(@ARGV);
while (my $fn = shift @files) {
    my %h = %$opt;
    my $fmt;
    if ($fn =~ /\.obo$/) {
        $fmt = 'obo_text';
    }
    if ($fmt && !$h{format}) {
        $h{format} = $fmt;
    }
    my $parser = new GO::Parser(%h);
    $parser->errhandler($errhandler);
    if ($parser->handler->can("is_transform") &&
        $parser->handler->is_transform) {
        my $inner_handler = $parser->handler;
        my $handler =
          Data::Stag->chainhandlers([$parser->handler->CONSUMES],
                                    $inner_handler,
                                    'xml');
        $parser->handler($handler);
    }
    $parser->parse($fn);
    $parser->handler->export if $parser->handler->can("export");
}
$errhandler->finish;
exit 0;

__END__

=head1 NAME

go2fmt.pl
go2obo_xml
go2owl
go2rdf_xml
go2obo_text

=head1 SYNOPSIS

  go2fmt.pl -w obo_xml -e errlog.xml ontology/*.ontology
  go2fmt.pl -w obo_xml -e errlog.xml ontology/gene_ontology.obo

=head1 DESCRIPTION

parses any GO/OBO style ontology file and writes out as a different
format

=head2 ARGUMENTS

=head3 -e ERRFILE

writes parse errors in XML - defaults to STDERR
(there should be no parse errors in well formed files)

=head3 -p FORMAT

determines which parser to use; if left unspecified, will make a guess
based on file suffix. See below for formats

=head3 -w|writer FORMAT

format for output - see below for list

=head2 FORMATS

writable formats are

=over

=item go_ont

Files with suffix ".ontology"

These store the ontology DAGs

=item go_def

Files with suffix ".defs"

=item go_xref

External database references for GO terms

Files with suffix "2go" (eg ec2go, metacyc2go)

=item go_assoc

Annotations of genes or gene products using GO

Files with prefix "gene-association."

=item obo_text

Files with suffix ".obo"

This is a new file format replacement for the existing GO flat file
formats. It handles ontologies, definitions and xrefs (but not
associations)

=item obo_xml

Files with suffix ".obo.xml" or ".obo-xml"

This is the XML version of the OBO flat file format above

=item prolog

creates a prolog database file (for use with the OBO project)

=item tbl

simple (lossy) tabular representation

=item summary

can be used on both ontology files and association files

=item pathlist

shows all paths to the root

=item obj_yaml

a YAML representation of a GO::Model::Graph object

=item text_html

A html-ified OBO output format

=item godb_prestore

XML that maps directly to the GODB relational schema
(can then be loaded using stag-storenode.pl)

=item chadodb_prestore

XML that maps directly to the Chado relational schema
(can then be loaded using stag-storenode.pl)

=back

=head2 DOCUMENTATION

L<http://www.godatabase.org/dev>

=cut

