# $Id: ObjFactory.pm,v 1.2 2004/11/24 02:27:59 cmungall Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

package GO::ObjFactory;

=head1 NAME

  GO::ObjFactory     - Gene Ontology Object Factory

=head1 SYNOPSIS

  use GO::ObjFactory;


=head1 DESCRIPTION


=head1 PUBLIC METHODS - ObjFactory


=cut


use strict;
use Carp;
use GO::Model::Seq;
use GO::Model::Term;
use GO::Model::Xref;
use GO::Model::GeneProduct;
use GO::Model::CrossProduct;
use GO::Model::Graph;
use GO::Model::Ontology;
use GO::Model::Property;
use GO::Model::Restriction;
use GO::Model::Species;


sub apph{
  my $self = shift;
  $self->{apph} = shift if @_;

  my $apph = $self->{apph} || $self;
  return $apph;
}



sub create_term_obj {
    my $self = shift;
    my $term = GO::Model::Term->new(@_);
    $term->apph( $self->apph );
    return $term;
}

sub create_relationship_obj {
    my $self = shift;
    my $term = GO::Model::Relationship->new(@_);
    $term->apph( $self->apph );
    return $term;
}

sub create_xref_obj {
    my $self = shift;
    my $xref = GO::Model::Xref->new(@_);
#    $xref->apph($self);
    return $xref;
}

sub create_evidence_obj {
    my $self = shift;
    my $ev = GO::Model::Evidence->new(@_);
    return $ev;
}

sub create_seq_obj {
    my $self = shift;
    my $seq = GO::Model::Seq->new(@_);
    $seq->apph( $self->apph );
    return $seq;
}

sub create_association_obj {
    my $self = shift;
    my $association = GO::Model::Association->new();
    $association->apph( $self->apph );
    $association->_initialize(@_);
    return $association;
}

sub create_gene_product_obj {
    my $self = shift;
    my $gene_product = GO::Model::GeneProduct->new(@_);
    $gene_product->apph( $self->apph );
    return $gene_product;
}

sub create_species_obj {
    my $self = shift;
    my $sp = GO::Model::Species->new(@_);
    $sp->apph( $self->apph );
    return $sp;
}

sub create_graph_obj {
    my $self = shift;
    my $graph = GO::Model::Graph->new(@_);
    $graph->apph( $self->apph );
    return $graph;
}

sub create_ontology_obj {
    my $self = shift;
    my $ontology = GO::Model::Ontology->new(@_);
    $ontology->apph( $self->apph );
    return $ontology;
}

sub create_property_obj {
    my $self = shift;
    my $property = GO::Model::Property->new(@_);
    $property->apph( $self->apph );
    return $property;
}

sub create_restriction_obj {
    my $self = shift;
    my $restriction = GO::Model::Restriction->new(@_);
    $restriction->apph( $self->apph );
    return $restriction;
}

sub create_cross_product_obj {
    my $self = shift;
    my $cross_product = GO::Model::CrossProduct->new(@_);
    $cross_product->apph( $self->apph );
    return $cross_product;
}

1;


