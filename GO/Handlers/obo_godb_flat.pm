# $Id: obo_godb_flat.pm,v 1.4 2007/06/12 21:59:18 benhitz Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

=head1 NAME

  GO::Handlers::obo_godb_flat    - 

=head1 SYNOPSIS

  use GO::Handlers::obo_godb_flat

=cut

=head1 DESCRIPTION

transforms OBO XML events into flat tables for mysql to load
part of the association bulk loading pipeline


=head1 PUBLIC METHODS - 

=cut

# makes objects from parser events

package GO::Handlers::obo_godb_flat;
use Data::Stag qw(:all);
use Data::Dumper;
use GO::Parsers::ParserEventNames;
use base qw(GO::Handlers::base);
use strict qw(vars refs);

my %TABLES = (
    dbxref       => [ qw(id xref_key xref_keytype xref_dbname) ], # must append many dbxrefs
    term         => [ qw(id name term_type acc is_obsolete is_root) ], # must append SO terms, qualifiers
    gene_product => [ qw(id symbol dbxref_id species_id secondary_species_id type_id full_name) ],
    association  => [ qw(id term_id gene_product_id is_not role_group assocdate source_db_id) ],
    db           => [ qw(id name fullname datatype generic_url url_syntax) ], # last 4 all null in current load
    evidence     => [ qw(id code association_id dbxref_id seq_acc) ],
    association_qualifier => [ qw(id association_id term_id value) ], # must append 
    species               => [ qw(id ncbi_taxa_id common_name lineage_string genus species) ],
    # linking tables
    gene_product_synoynm => [ qw(gene_product_id product_synonym)],
    evidence_dbxref      => [ qw(evidence_id dbxref_id) ]
    );
    
my %fh = ( map (("$_.txt" => 0), keys %TABLES));


sub init {

    my $self = shift;

    $self->SUPER::init();
    $self->{pk} = { map (($_ => 0), keys %TABLES) };

}
    
sub apph {
    my $self = shift;
    $self->{apph} = shift if @_;
    return $self->{apph};
}
    

sub _obo_escape {
    my $s=shift;
    $s =~ s/\\/\\\\/;
    $s =~ s/([\{\}])/\\$1/g;
    $s;
}


sub safe {
    my $word = shift;
    $word =~ s/ /_/g;
    $word =~ s/\-/_/g;
    $word =~ s/\'/prime/g;
    $word =~ tr/a-zA-Z0-9_//cd;
    $word =~ s/^([0-9])/_$1/;
    $word;
}

sub quote {
    my $word = shift;
    #$word =~ s/,/\\,/g;  ## no longer required
    $word =~ s/\"/\\\"/g;
    "\"$word\"";
}



sub e_prod {
    my $self = shift;
    my $prod = shift;

    my $proddb = $self->up_to('dbset')->get_proddb;

    $self->file('gene_product.txt'); # we actually to map these to file handles somewhere

    my $gp_id = $self->add_gene_product($prod, $proddb);
    
    my @assocs = $prod->get_assoc;

    for my $assoc (@assocs) {

	# first dump the ASSOCIATION table
	$self->file('association.txt');       
	$self->write(join("\t", (
				 ++$self->{pk}{association},
				 $self->get_term_id($assoc->get_termacc),
				 $gp_id,
				 stag_get($assoc, IS_NOT),
				 '\N', # role_group current always NULL
				 $assoc->sget_assocdate,
				 $self->get_sourcedb_id($assoc->sget_source_db),))
		     );

        $self->write("\n");
	# now the qualifiers
	$self->file('association_qualifier.txt');
	for my $qual ($assoc->get_qualifier) {

	    $self->write(join("\t", (
				     ++$self->{pk}{association_qualifier},
				     $self->{pk}{association},
				     $self->get_term_id($qual, 'association_qualifier'),
				     '\N',)) # value is currently always NULL
			 );
	    $self->write("\n");
	}

	# now evidence and evidence dbxref
	for my $ev ($assoc->get_evidence) {
	    
	    $self->file('evidence.txt');
	    $self->write(join("\t", (
				     ++$self->{pk}{evidence},
				     $ev->sget_evcode,
				     $self->{pk}{association},
				     $self->get_dbxref_id($ev->sget_ref), # only the first one here
				     $ev->sget_with || "",  # put only the first one here, I dunno why
				     ))
			 );
	    $self->write("\n");

	    $self->file('evidence_dbxref.txt');
	    for my $ref ($ev->get_ref) {

		next; # skip whole loop until we figure this out.
		$self->write(join("\t", (
					  $self->{pk}{evidence},
					  $self->get_dbxref_id($ref),
					  ))
			     );
		$self->write("\n");

	    }
	    for my $with ($ev->get_with) {

		$self->write(join("\t", (
					  $self->{pk}{evidence},
					  $self->get_dbxref_id($with),
					  ))
			     );
		$self->write("\n");

	    }

				     
	}
	
    }
    
}


sub add_gene_product {

    my $self = shift;
    my $prod = shift;
    my $proddb = shift;

    my $acc = $prod->get_prodacc;

    if ($self->apph->dbxref2gpid_h->{$proddb}->{$acc}) {
    # check to see if we've already added it
#	warn "checking $proddb, $acc ".$self->apph->dbxref2gpid_h->{$proddb}->{$acc};
    # unique key for gene product is actually dbxref_id, but need the gp_id
    } else {
#	warn "$proddb, $acc, does not exist, creating";
    
	# if not, write a line to gene_product.txt
	# new dbxref_id is added by get_dbxref_id.
	$self->write(join("\t", (
				 ++$self->{pk}{gene_product},
				 $prod->sget_prodsymbol,
				 $self->get_dbxref_id($proddb, $acc),
				 $self->get_taxon_id($prod->sget_prodtaxa),
				 '\N', # currently no secondary species ids
				 $self->get_term_id($prod->get_prodtype, 'sequence'),
				 $prod->sget_prodname || "") )# that should be full name.
		     );

	$self->write("\n");
	$self->apph->dbxref2gpid_h->{$proddb}->{$acc} = $self->{pk}{gene_product};

    }

    # add synoyms if necessary
    $self->file('gene_product_synonym.txt');

    for my $syn ($prod->get_prodsyn) {

	$self->write(join("\t", ($self->{pk}{gene_product}, $syn)));
	$self->write("\n");
    }

    return $self->apph->dbxref2gpid_h->{$proddb}->{$acc};
    
}

sub get_dbxref_id {

    my $self = shift;
    my $dbname = shift;
    my $key = shift;

    if (!$key) {

        if ($dbname =~ /^([^:]+):+(\S+)/) {
	    $dbname = $1;
	    $key = $2;
	} 

    }



    if (!$dbname || !$key) {
	warn "Must supply dbname and key: ($dbname),($key) attempting to write $self->{_file}\n";
	return 0;

    }

    my $ucKey = uc($key);
    my $ucDb  = uc($dbname);

    # mysql will handle case-insensitivity, but perl keeps seperate

    return $self->apph->dbxref2id_h->{$ucDb}->{uc($ucKey)} if $self->apph->dbxref2id_h->{$ucDb}->{$ucKey};

    # doesn't exist, add it to dbxref file and hash
    my $oldfile = $self->file;

    $self->file('dbxref.txt');

    $self->write(join("\t", (
			     ++$self->{pk}{dbxref},
			     $key,
			     '\N',
			     $dbname,))
		 );

    $self->write("\n");

    $self->file($oldfile); # set it back

    $self->apph->dbxref2id_h->{$ucDb}->{$ucKey} = $self->{pk}{dbxref};  # return the id


}
			     
sub get_term_id {

    # note this hopeless fails if 2 terms in different CVs have the same name!

    my $self = shift;
    my $term = shift;
    my $termType = shift;
    my $acc = shift || $term;

    $term = lc($term) unless $term =~ /^GO:/; # sometimes people use Gene instead of gene

    return $self->apph->acc2id_h->{$term} if $self->apph->acc2id_h->{$term};

    die "No term type specified for $term, and not in hash" if !$termType;

    # doesn't exist, add it to dbxref file and hash
    my $oldfile = $self->file;

    $self->file('term.txt');

    $self->write(join("\t", (
			     ++$self->{pk}{term},
			     $term,
			     $termType,
			     $acc,
			     0,    # never is_obsolete
			     0,))  # never is_root
		 );
    $self->write("\n");

    $self->file($oldfile); # set it back

    $self->apph->acc2id_h->{$term} = $self->{pk}{term};  # return the id


}
    
sub get_sourcedb_id {

    my $self = shift;
    my $db = shift;
 
    return $self->apph->source2id_h->{$db} if $self->apph->source2id_h->{$db};

    # doesn't exist, add it to file and hash
    my $oldfile = $self->file;

    $self->file('db.txt');

    $self->write(join("\t", (
			     ++$self->{pk}{db},
			     $db,
			     '\N',
			     '\N',
			     '\N',   
			     '\N',))  # last 4 columns always null
		 );
    $self->write("\n");

    $self->file($oldfile); # set it back

    $self->apph->source2id_h->{$db} = $self->{pk}{db};  # return the id


}
sub get_taxon_id {

    my $self = shift;
    my $taxonId = shift;
    
    return $self->apph->taxon2id_h->{$taxonId} if $self->apph->taxon2id_h->{$taxonId};
    warn "Could not find id in db for taxon $taxonId, adding\n";

    my $oldfile = $self->file;

    $self->file('species.txt');

    $self->write(join("\t", (
			     ++$self->{pk}{species},
			     $taxonId,
			     '\N',  # name unknown
			     '\N',  # lineage unknown
			     '\N',  # genuss unknown
			     '\N',))  # species unknown
		 );
    $self->write("\n");

    $self->file($oldfile); # set it back

    $self->apph->taxon2id_h->{$taxonId} = $self->{pk}{species};  # return the id


}


sub file {
# overrides Data::Stag::Writer file
    my $self = shift;

    if (@_) {
	
	$self->{_file} = shift;
	$self->{_fh} = undef;
    }

    unless ( $fh{$self->{_file}} ) {

#	print STDERR "opening file $self->{_file}...\n";
	$fh{$self->{_file}} = $self->safe_fh;

    }
    
    $self->{_fh} = $fh{$self->{_file}};

    return $self->{_file};

}

sub close_files {

    my $self = shift;
    for my $fh (values %fh) {

	close($fh) if $fh;
    }

    close($self->{_fh}) if $self->{_fh};
}
1;
