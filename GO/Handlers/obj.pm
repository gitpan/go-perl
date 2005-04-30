# $Id: obj.pm,v 1.13 2005/04/19 04:35:49 cmungall Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

=head1 NAME

  GO::Handlers::obj     - parses GO files into GO object model

=head1 SYNOPSIS

  use GO::Handlers::obj

=cut

=head1 DESCRIPTION

=head1 PUBLIC METHODS

=cut

# makes objects from parser events

package GO::Handlers::obj;
use Data::Stag qw(:all);
use GO::Parsers::ParserEventNames;
use base qw(GO::Handlers::base);
use strict qw(vars refs);

my $TRACE = $ENV{GO_TRACE};

sub init {
    my $self = shift;
    $self->SUPER::init;

    use GO::ObjCache;
    my $apph = GO::ObjCache->new;
    $self->{apph} = $apph;

    use GO::Model::Graph;
    my $g = $self->apph->create_graph_obj;
    $self->{g} = $g;
    return;
}


=head2 graph

  Usage   - my $terms = $obj_handler->graph->get_all_terms;
  Synonym - g
  Synonym - ontology
  Returns - GO::Model::Graph object
  Args    -

as files are parsed, objects are created; depending on what kind of
datatype is being parsed, the classes of the created objects will be
different - eg GO::Model::Term, GO::Model::Association etc

the way to access all of thses is through the top level graph object

eg

  $parser = GO::Parser->new({handler=>'obj'});
  $parser->parse(@files);
  my $graph = $parser->graph;
  

=cut

sub g {
    my $self = shift;
    $self->{g} = shift if @_;
    return $self->{g};
}

*graph = \&g;
*ontology = \&g;


sub apph {
    my $self = shift;
    $self->{apph} = shift if @_;
    return $self->{apph};
}

sub root_term {
    my $self = shift;
    $self->{_root_term} = shift if @_;
    return $self->{_root_term};
}

# 20041029 - not currently used
sub add_root {
    my $self = shift;
    my $g = $self->g;

    my $root = $self->apph->create_term_obj;
    $root->name('root');
    $root->acc('root');
    $g->add_term($root);
    $self->root_term($root);
    $self->root_to_be_added(1);
    $root;
}

# -- HANDLER METHODS --

sub e_obo {
    my $self = shift;
    my $g = $self->g;
    return ();
}

sub e_typedef {
    my $self = shift;
    my $t = shift;
    $self->stanza('Typedef', $t);
}

sub e_term {
    my $self = shift;
    my $t = shift;
    $self->stanza('Term', $t);
}

sub stanza {
    my $self = shift;
    my $stanza = lc(shift);
    my $tree = shift;
    my $acc = stag_get($tree, ID);
    if (!$acc) {
        $self->throw( "NO ACC: $@\n" );
    }
    my $term;
    eval {
        $term = $self->g->get_term($acc);
    };
    if ($@) {
        $self->throw( "ARG:$@" );
    }
    # no point adding term twice; we
    # assume the details are the same
    return $term if $term && $self->strictorder;

    $term = $self->apph->create_term_obj;
    my %h = ();
    foreach my $sn (stag_kids($tree)) {
        my $k = $sn->name;
        my $v = $sn->data;

        if ($k eq RELATIONSHIP) {
            my $obj = stag_get($sn, TO);
            $self->g->add_relationship($obj, $term->acc, stag_get($sn, TYPE));
        }
        elsif ($k eq IS_A) {
            $self->g->add_relationship($v, $term->acc, IS_A);
        }
        elsif ($k eq DEF) {
            my $defstr = stag_get($sn, DEFSTR);
	    my @xrefs = stag_get($sn, DBXREF);
	    $term->definition($defstr);
	    $term->add_definition_dbxref($self->dbxref($_)) foreach @xrefs;
        }
        elsif ($k eq SYNONYM) {
            my $synstr = stag_get($sn, SYNONYM_TEXT);
            my $type = stag_find($sn, 'scope');
	    my @xrefs = stag_get($sn, DBXREF);
	    $term->add_synonym_by_type($type, $synstr);
#	    $term->add_definition_dbxref($_) foreach @xrefs;
        }
        elsif ($k eq ALT_ID) {
	    $term->add_synonym($v);
        }
        elsif ($k eq 'property') {
            # experimental tag!!
            warn('experimental code!');
            my %ph = stag_pairs($sn);
            my $prop =
              $self->apph->create_property_obj({name=>$ph{name},
                                                range_acc=>$ph{range},
                                                namerule=>$ph{namerule},
                                                defrule=>$ph{defrule},
                                               });
            $term->add_property($prop);
        }
        elsif ($k eq XREF_ANALOG) {
            my $xref =
	      $self->apph->create_xref_obj(stag_pairs($sn));
            $term->add_dbxref($xref);
        }
        elsif ($k eq XREF_UNKNOWN) {
            my $xref =
	      $self->apph->create_xref_obj(stag_pairs($sn));
            $term->add_dbxref($xref);
        }
        elsif ($k eq 'cross_product') {
            warn('experimental code!');
            my %ph = stag_pairs($sn);
            my $xp =
              $self->g->add_cross_product($term->acc,
                                          $ph{parent_acc},
                                          []);
            foreach (stag_get($sn, 'restriction')) {
                $xp->add_restriction(stag_get($_, 'property_name'),
                                     stag_get($_, 'value'))
            }

        }
        elsif ($k eq ID) {
            $term->acc($v);
        }
        elsif ($k eq 'ontology') {
            warn('deprecated');
            $term->type($v);
        }
        elsif ($k eq NAMESPACE) {
            $term->type($v);
        }
        elsif ($k eq NAME) {
            $term->name($v);
        }
        elsif ($k eq SUBSET) {
            $term->add_subset($v);
        }
        elsif ($k eq COMMENT) {
            $term->comment($v);
        }
        elsif ($k eq IS_ROOT) {
            $term->is_root($v);
        }
        elsif ($k eq BUILTIN) {
            # ignore
        }
        elsif ($k eq IS_OBSOLETE) {
            $term->is_obsolete($v);
        }
        elsif ($k eq IS_TRANSITIVE ||
               $k eq IS_SYMMETRIC  ||
               $k eq IS_ANTI_SYMMETRIC  ||
               $k eq IS_REFLEXIVE  ||
               $k eq INVERSE_OF ||
               $k eq DOMAIN ||
               $k eq RANGE) {
            # obo extensions - not dealt with yet
        }
        elsif ($term->can("add_$k")) {
            # CONVENIENCE METHOD - map directly to object method
            warn("add method for $k");
            my $m = "add_$k";
            $term->$m($v);
        }
        elsif ($term->can($k)) {
            warn("add method for $k");
            # CONVENIENCE METHOD - map directly to object method
            $term->$k($v);
        }
        else {
            warn("add method for $k");
            $term->stag->add($k, $v);

#            $self->throw("don't know what to do with $k");
#            print "no $k\n";
        }
    }
    if ($self->root_to_be_added &&
	!$term->is_obsolete &&
        $stanza eq 'term') {
	my $parents = $self->g->get_parent_relationships($term->acc);
	if (!@$parents) {
	    my $root = $self->root_term || $self->throw("no root term");
            $self->g->add_relationship($root, $term->acc, IS_A);
	}
    }

#    $term->type($self->{ontology_type}) unless $term->type;
    if (!$term->name) {
        warn("no name; using acc ".$term->acc);
        $term->name($term->acc);
    }
    if ($stanza eq 'typedef') {
        $term->is_relationship_type(1);
    }

    $self->g->add_term($term);
    printf STDERR "Added term %s %s\n", $term->acc, $term->name 
      if $TRACE;
#    $term;
    return ();
}

sub dbxref {
    my $self = shift;
    my $x = shift;
    $self->apph->create_xref_obj(stag_pairs($x))
}


sub e_proddb {
    my $self = shift;
    $self->proddb(shift);
    return;
}

sub e_prod {
    my $self = shift;
    my $tree = shift;
    my $g = $self->g;
    my $prod =
      $self->apph->create_gene_product_obj({symbol=>stag_sget($tree, PRODSYMBOL),
                                            type=>stag_sget($tree, PRODTYPE),
                                            full_name=>stag_sget($tree, PRODNAME),
                                            speciesdb=>$self->proddb,
                                      });
    my @syns = stag_get($tree, PRODSYN);
    $prod->xref->xref_key(stag_sget($tree, PRODACC));
    $prod->synonym_list(\@syns);
    my @assocs = stag_get($tree, ASSOC);
    foreach my $assoc (@assocs) {
        my $acc = stag_get($assoc, TERMACC);
        if (!$acc) {
            $self->message("no accession given");
            next;
        }
        my $t = $g->get_term($acc);
        if (!$t) {
            if (!$self->strictorder) {
                $t = $self->apph->create_term_obj({acc=>$acc});
                $self->g->add_term($t);
            }
            else {
                $self->message("no such term $acc");
                next;
            }
        }
        my @evs = stag_get($assoc, EVIDENCE);
        my $ao =
          $self->apph->create_association_obj({gene_product=>$prod,
                                               is_not=>stag_sget($assoc, IS_NOT),
                                              });
        foreach my $ev (@evs) {
            my $eo =
              $self->apph->create_evidence_obj({
                                                code=>stag_sget($ev, EVCODE),
                                               });
            my @seq_xrefs = stag_get($ev, WITH),
            my @refs = stag_get($ev, REF);
            map { $eo->add_seq_xref($_) } @seq_xrefs;
            map { $eo->add_pub_xref($_) } @refs;
            $ao->add_evidence($eo);
        }
        $t->add_association($ao);
    }
    return;
}

1;
