# $Id: godb_stag.pm,v 1.2 2004/06/16 02:17:01 cmungall Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

=head1 NAME

  GO::Handlers::godb_stag     - 

=head1 SYNOPSIS

  use GO::Handlers::godb_stag

=cut

=head1 DESCRIPTION

=head1 PUBLIC METHODS - 

=cut

# makes objects from parser events

package GO::Handlers::godb_stag;
use GO::SqlWrapper qw (:all);
use base qw(GO::Handlers::genericdb);

use strict;
use Carp;
use Data::Dumper;
use Data::Stag qw(:all);

sub e_header {
    my ($self, $hdr) = @_;
    [dbstag_metadata=>[
                       [map=>"..."]
                      ]
     ];
}

sub e_term {
    my ($self, $term) = @_;
    my $id = $term->get_id || $self->throw($term->sxpr);
    $term->set_acc($id);
    my $name_h = $self->{name_h};
    my $name = $term->get_name;
    my $ont = $term->get_namespace;
    my $is_obs = $term->get_is_obsolete || '';
 
    my @is_as = $term->get_is_a;
    my @rels = ($term->get_relationship,
                map {[relationship=>[[to=>$_],[type=>'is_a']]]} @is_as);
    my @cvrels =
      map {
          my $to = stag_get($_=>'to');
          my $type = stag_get($_=>'type');
          Data::Stag->new(term2term=>[
				      [term1=>[[term=>[[acc=>$to]]]]],
				      [term2=>[[term=>[[acc=>$id]]]]],
				      _type($type, 'relationship'),
				     ]
                         );
      } @rels;
    my $def = $term->get_def;
    my @alt_ids = $term->get_alt_id;
    my @syns = $term->get_synonym;

    $term = 
      Data::Stag->new(term=>[
			     [acc=>$id],
			     [name=>$name],
			     [term_type=>$ont],
			     [is_obsolete=>$is_obs eq 'true' ? 1:0],
			    ]
                     );
    my @term_dbxrefs =
      map {
	  Data::Stag->new(term_dbxref=>[[dbxref=>[_xref_stags($_)]]])
      } $term->get_xref_analog;
    if ($def) {
	$term->set(term_definition=>[
				     [term_definition=>$def->sget_defstr],
				     [term_comment=>$term->sget_comment]
				    ]);
	push(@term_dbxrefs,
	     Data::Stag->new(term_dbxref=>[[is_for_definition=>1],
					   [dbxref=>[_xref_stags($_)]]]))
	  foreach $def->get_dbxref;
    }
    $term->add_term_dbxref($_) foreach @term_dbxrefs;
    $term->add(term_synonym=>[
			      [acc_synonym=>$_]
			     ])
      foreach @alt_ids;

    foreach (@syns) {
	my $type = $_->sget_type;
	$term->add(term_synonym=>[
				  $type ? _type($type,'synonym') : (),
				  [term_synonym=>$_->sget_synonym_text]
				 ]);
    }
    return ($term,@cvrels);
}

sub e_typedef {
    my ($self, $t) = @_;
    my $id = $t->sget_id;
    return
      Data::Stag->new(term=>[
			     [acc=>$id],
			     [name=>$id]
			    ]);
}

sub e_prod {
    my ($self, $prod) = @_;
    my $proddb = $self->up(1)->sget_proddb;
    my @gpstags =
      (
       [symbol=>$prod->sget_prodsymbol],
       [dbxref=>[[xref_dbname=>$proddb],
		 [xref_key=>$prod->sget_prodacc]]],
       [species=>[[ncbi_taxa_id=>$prod->sget_prodtaxa]]],
       _type($prod->sget_type || 'gene', 'gene_product'),
       (map {
	   [gene_product_synonym=>[[product_synonym=>$_]]]
       } $prod->get_prodsyn),
      );
    my @assocs = $prod->get_assoc;
    foreach my $assoc (@assocs) {
	my $qual = $assoc->sget_qualifier;
	push(@gpstags,
	     [association=>[
			    [term=>[[acc=>$assoc->sget_termacc]]],
			    [is_not=>$assoc->sget_is_not],
			    ($qual ? [qualifier=>[[term=>[[acc=>$qual]]]]]: ()),
			    [source_db=>[[db=>[[name=>$assoc->sget_source_db]]]]],
			    [assocdate=>$assoc->sget_assocdate],
			    (map {
				my @seq_accs = $_->get_seq_acc;
				[evidence=>[
					    [code=>$_->sget_evcode],
					    [seq_acc=>join('|',@seq_accs)],
					    [dbxref=>[_xref($_->sget_ref)]],
					    [evidence_dbxref=>[
							       (map {
								   [dbxref=>[_xref($_)]]
							       } @seq_accs)
							      ]]
					   ]]
			    } $assoc->get_evidence)
			   ]
	     ]
	    );
							  
    }
    return Data::Stag->new(gene_product=>[@gpstags]);
}

sub _xref_stags {
    my $x = shift;
    ([xref_key=>$x->sget_acc],
     [xref_dbname=>$x->sget_dbname]);
}

sub _type {
    my $type = shift;
    my $ont = shift;
    [type=>[[term=>[
		    [acc=>$type],
		    [name=>$type],
		    [term_type=>$ont],
		   ]
	    ]]
    ];

}

sub _xref {
    my $id = shift;
    my ($dbname,$acc);
    if ($id =~ /(\w+):(\S+)/) {
        $dbname = $1;
        $acc = $2;
    }
    else {
        $dbname = '';
        $acc = $id;
    }
    return 
      [dbxref=>[
                [xref_dbname=>$dbname],
                [xref_key=>$acc]
               ]
      ];
}


1;
