# $Id: chado_load.pm,v 1.3 2004/06/16 02:17:01 cmungall Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

=head1 NAME

  GO::Handlers::obo_to_chadodb     - 

=head1 SYNOPSIS

  use GO::Handlers::obo_to_chadodb

=head1 DESCRIPTION

  This is a transform for turning OBO XML events into XML events that
  are isomorphic to the GO Database (ie XML element names match Chado
  DB table and column names).

  This transformation is suitable for direct loading into a db using
  the generic DBIx::DBStag loader

  This perl transform may later be replaced by an XSL transform (for
  speed)


=head1 PUBLIC METHODS - 

=cut

# makes objects from parser events

package GO::Handlers::obo_to_chadodb;
use GO::SqlWrapper qw (:all);
use base qw(GO::Handlers::base);

use strict;
use Carp;
use Data::Dumper;
use Data::Stag qw(:all);

sub e_term {
    my ($self, $term) = @_;
    my $id = $term->get_id || $self->throw($term->sxpr);
    my $name_h = $self->{name_h};
    my $name = $term->get_name;
    my $ont = $term->get_namespace;
    my $is_obs = $term->get_is_obsolete;
    my $def = $term->get_def;
    my $defstr = $def ? $def->sget_defstr : '';
    my $dbxref = expand_xref($id);
 
    my @is_as = $term->get_is_a;
    my @rels = ($term->get_relationship,
                map {[relationship=>[[to=>$_],[type=>'is_a']]]} @is_as);
    my @cvrels =
      map {
          my $to = stag_get($_=>'to');
          my $type = stag_get($_=>'type');
          Data::Stag->new(cvtermrelationship=>[
                                               [subject=>[[cvterm=>[[acc=>$id]]]]],
                                               [object=>[[cvterm=>[[acc=>$to]]]]],
                                               [type=>[[cvterm=>[
                                                                 [acc=>$type],
                                                                 [name=>$type],
                                                                 [cv=>[[name=>'relationship']]]
                                                                ]
                                                       ]]],
                                              ]
                         );
      } @rels;
    my $cvterm = 
      Data::Stag->new(cvterm=>[
                               $dbxref,
                               [name=>$name],
                               [cv=>[[name=>$ont]]],
                               [is_obsolete=>$is_obs || 0],
                              ]
                     );

    return ($cvterm,@cvrels);
}

sub e_typedef {
    my ($self, $t) = @_;
    $t->set_name('term');
    $t->set_namespace('relationship') unless $t->get_namespace;
    return
      $self->e_term($t);
}


1;
