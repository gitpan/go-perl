# $Id: go_xref_parser.pm,v 1.3 2004/11/24 02:28:02 cmungall Exp $
#
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

package GO::Parsers::go_xref_parser;

=head1 NAME

  GO::Parsers::go_xref_parser     - syntax parsing of GO xref flat files (eg eg2go, metacyc2go)

=head1 SYNOPSIS

  do not use this class directly; use GO::Parser

=cut

=head1 DESCRIPTION

This generates Stag event streams from one of the various GO flat file
formats (ontology, defs, xref, associations). See GO::Parser for details

Examples of these files can be found at http://www.geneontology.org

A description of the event streams generated follows; Stag or an XML
handler can be used to catch these events

=head1 GO XREF FILES

These files have a filename *2go; eg metacyc2go

  (dbxrefs
   (termdbxref+
     (termacc "s")
     (dbxref
       (xref_dbname "s")
       (xref_key "s")))) 

 

=head1 AUTHOR

=cut

use Carp;
use FileHandle;
use strict qw(vars refs);
use base qw(GO::Parsers::base_parser);
use GO::Parsers::ParserEventNames;    # XML constants

sub dtd {
    'go_xref-parser-events.dtd';
}

sub parse_fh {
    my ($self, $fh) = @_;
    my $file = $self->file;

    my $lnum = 0;
    $self->start_event(DBXREFS);
    while (<$fh>) {
        chomp;
        $lnum++;
        next if /^\!/;
        next if /^$/;
        $self->line($_);
        $self->line_no($lnum);
        if (/(\w+):?(.*)\s+\>\s+(.+)\s+;\s+(.+)/) {
            my ($db, $dbacc, $goname, $goacc) = ($1, $2, $3, $4);
            my @goaccs = split(/\, /, $goacc);
            foreach $goacc (@goaccs) {
                $self->start_event(TERM);
                $self->event(ID, $goacc);
                $self->start_event(XREF_ANALOG);
                $self->event(ACC, $dbacc);
                $self->event(DBNAME, $db);
                $self->end_event(XREF_ANALOG);
                $self->end_event(TERM);
            }
        }
        else {
            $self->message("cannot parse this line");
        }
    }
    $self->end_event(DBXREFS);
}

1;
