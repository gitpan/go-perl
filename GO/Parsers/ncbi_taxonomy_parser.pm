# $Id: ncbi_taxonomy_parser.pm,v 1.1 2005/08/19 01:48:09 cmungall Exp $
#
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

package GO::Parsers::ncbi_taxonomy_parser;

=head1 NAME

  GO::Parsers::ncbi_taxonomy_parser 

=head1 SYNOPSIS

  do not use this class directly; use GO::Parser

=cut

=head1 DESCRIPTION

See L<ftp://ftp.ebi.ac.uk/pub/databases/taxonomy/taxonomy.dat>


=head1 PARSER ARCHITECTURE

This generates Stag event streams from one of the various GO flat file
formats (ontology, defs, xref, associations). See GO::Parser for details

Examples of these files can be found at http://www.geneontology.org

A description of the event streams generated follows; Stag or an XML
handler can be used to catch these events

=cut

use Exporter;
use base qw(GO::Parsers::base_parser);
use GO::Parsers::ParserEventNames;  # declare XML constants

use Carp;
use FileHandle;
use strict qw(subs vars refs);


sub parse_fh {
    my ($self, $fh) = @_;
    my $file = $self->file;
    $self->{name_h} = {};

    $self->start_event(OBO);
    my $lnum = 0;
    my %h = ();
    my $text;
    while (my $line = <$fh>) {
        chomp $line;
        if ($line eq '//') {
            $self->emit_term(\%h,$text);
            %h = ();
            $text = '';
        }
        else {
            if ($line =~ /^([\w\s\-]+)\s+:\s*(.*)/) {
                my ($k,$v) = ($1,$2);
                $k = lc($k);
                $k =~ s/\s+$//;
                push(@{$h{$k}},$v);
            }
            else {
                $self->parse_err("Line: $line");
            }
            $text .= "$line\n";
        }
    }
    $self->pop_stack_to_depth(0);  # end event obo
}

sub _fix_id {
    return "NCBITaxon:$_[0]";
}

sub emit_term {
    my ($self, $h, $text) = @_;
    my $id = pop @{$h->{id}};
    if (!$id) {
        $self->parse_err("No id! in:\n$text");
        return;
    }
    $id = _fix_id($id);
    $self->start_event(TERM);
    $self->event(ID,$id);
    my $name = pop @{$h->{'scientific name'}};
    my $gname = pop @{$h->{'genbank common name'}};
    if (!$name) {
        $name = $gname;
    }
    if ($self->{name_h}->{$name}) {
        $name .= " [$id]";
    }
    $self->{name_h}->{$name} = $id;
    my @synonyms = 
      (@{$h->{synonym} || []},
       @{$h->{'blast name'} || []},
       @{$h->{'equivalent name'} || []},
       $gname);
    foreach my $s (@synonyms) {
        $self->event(SYNONYM,[[SYNONYM_TEXT,$s]]);
    }
    $self->event('rank',pop @{$h->{rank}});
    $self->event('gc_id',pop @{$h->{'gc id'}});
    my $parent_id = pop @{$h->{'parent id'}};
    if ($parent_id) {
        $parent_id = _fix_id($parent_id);
        $self->event(IS_A,$parent_id);
    }
    $self->end_event(TERM);
}

1;
