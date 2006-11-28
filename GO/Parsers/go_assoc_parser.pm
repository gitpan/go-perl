# $Id: go_assoc_parser.pm,v 1.10 2006/10/19 18:38:28 cmungall Exp $
#
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

package GO::Parsers::go_assoc_parser;

=head1 NAME

  GO::Parsers::go_assoc_parser     - syntax parsing of GO gene-association flat files

=head1 SYNOPSIS


=head1 DESCRIPTION

do not use this class directly; use L<GO::Parser>

This generates Stag/XML event streams from GO association files.
Examples of these files can be found at http://www.geneontology.org,
an example of lines from an association file:

  SGD     S0004660        AAC1            GO:0005743      SGD:12031|PMID:2167309 TAS             C       ADP/ATP translocator    YMR056C gene    taxon:4932 20010118
  SGD     S0004660        AAC1            GO:0006854      SGD:12031|PMID:2167309 IDA             P       ADP/ATP translocator    YMR056C gene    taxon:4932 20010118

See L<http://www.geneontology.org/GO.annotation.shtml#file>

See
L<http://www.godatabase.org/dev/xml/dtd/go_assoc-parser-events.dtd>
For the DTD of the event stream that is generated

The following stag-schema describes the events that are generated in
parsing an assoc file:

  (assocs
   (dbset+
     (proddb "s")
     (prod+
       (prodacc "s")
       (prodsymbol "s")
       (prodtype "s")
       (prodtaxa "i")
       (assoc+
         (assocdate "i")
         (source_db "s")
         (termacc "s")
         (is_not "i")
         (aspect "s")
         (evidence+
           (evcode "s")
           (ref "s")))))) 

=cut

use Exporter;
use base qw(GO::Parsers::base_parser Exporter);
#use Text::Balanced qw(extract_bracketed);
use GO::Parsers::ParserEventNames;

use Carp;
use FileHandle;
use strict;

sub dtd {
    'go_assoc-parser-events.dtd';
}

sub ev_filter {
    my $self = shift;
    $self->{_ev_filter} = shift if @_;
    return $self->{_ev_filter};
}



sub skip_uncurated {
    my $self = shift;
    $self->{_skip_uncurated} = shift if @_;
    return $self->{_skip_uncurated};
}

sub parse_fh {
    my ($self, $fh) = @_;
    my $file = $self->file;

    my $product;
    my $term;
    my $assoc;
    my $line_no = 0;

    my @COLS = (0..15);
    my ($PRODDB,
        $PRODACC,
        $PRODSYMBOL,
        $QUALIFIER,
        $TERMACC,
        $REF,
        $EVCODE,
        $WITH,
        $ASPECT,
        $PRODNAME,
        $PRODSYN,
        $PRODTYPE,
        $PRODTAXA,
        $ASSOCDATE,
	$SOURCE_DB,
        $TERM_REFINEMENT,   # experimental! 
       ) = @COLS;

    my @mandatory_cols = ($PRODDB, $PRODACC, $TERMACC, $EVCODE);

    #    <assocs>
    #      <dbset>
    #        <db>fb</db>
    #        <prod>
    #          <prodacc>FBgn0027087</>
    #          <prodsym>Aats-his</>
    #          <prodtype>gene</>
    #          <prodtaxa>7227</>
    #          <prodsynonym>...</>
    #          <assoc>
    #            <termacc>GO:0004821</termacc>
    #            <evidence>
    #              <code>NAS</code>
    #              <ref>FB:FBrf0105495</ref>
    #              <with>...</with>
    #            </evidence>
    #          </assoc>
    #        </prod>
    #      </dbset>
    #    <assocs>
 
    $self->start_event(ASSOCS);

    my @last = map {''} @COLS;

    my $skip_uncurated = $self->skip_uncurated;
    my $ev = $self->ev_filter;
    my %evyes = ();
    my %evno = ();
    if ($ev) {
	if ($ev =~ /\!(.*)/) {
	    $evno{$1} = 1;
	}
	else {
	    $evyes{$ev} = 1;
	}
    }

    my $taxa_warning;

    my $line;
    my @vals;
    my @stack = ();
    while (<$fh>) {
        # UNICODE causes problems for XML and DB
        # delete 8th bit
        tr [\200-\377]
          [\000-\177];   # see 'man perlop', section on tr/
        # weird ascii characters should be excluded
        tr/\0-\10//d;   # remove weird characters; ascii 0-8
                        # preserve \11 (9 - tab) and \12 (10-linefeed)
        tr/\13\14//d;   # remove weird characters; 11,12
                        # preserve \15 (13 - carriage return)
        tr/\16-\37//d;  # remove 14-31 (all rest before space)
        tr/\177//d;     # remove DEL character

        $line_no++;
	chomp;
	if (/^\!/) {
	    next;
	}
	if (!$_) {
	    next;
	}
        # some files use string NULL - we just use empty string as null
        s/\\NULL//g;
        $line = $_;

        $self->line($line);
        $self->line_no($line_no);

	@vals = split(/\t/, $line);

	# normalise columns, and set $h
	for (my $i=0; $i<@COLS;$i++) {
	    if (defined($vals[$i])) {

		# remove trailing and
		# leading blanks
		$vals[$i] =~ s/^\s*//;
		$vals[$i] =~ s/\s*$//;

		# sometimes - is used for null
		$vals[$i] =~ s/^\-$//;

		# TAIR seem to be
		# doing a mysql dump...
		$vals[$i] =~ s/\\NULL//;
	    }
	    if (!defined($vals[$i]) ||
		length ($vals[$i]) == 0) {
		if ( grep {$i == $_} @mandatory_cols) {
		    $self->parse_err("no value defined for col ".($i+1)." in line_no $line_no line\n$line\n");
		    next;
		}
                $vals[$i] = '';
	    }
	}

    my ($proddb,
        $prodacc,
        $prodsymbol,
        $qualifier,
        $termacc,
        $ref,
        $evcode,
        $with,
        $aspect,
        $prodname,
        $prodsyn,
        $prodtype,
        $prodtaxa,
        $assocdate,
	$source_db,
        $term_refinement) = @vals;


#	if (!grep {$aspect eq $_} qw(P C F)) {
#	    $self->parse_err("Aspect column says: \"$aspect\" - aspect must be P/C/F");
#	    next;
#	}
        if ($self->acc_not_found($termacc)) {
	    $self->parse_err("No such ID: $termacc");
	    next;
        }
	if (!($ref =~ /:/)) {
            # ref does not have a prefix - we assume it is medline
	    $ref = "medline:$ref";
	}
	if ($with eq "IEA") {
	    $self->parse_err("SERIOUS COLUMN PROBLEM: IGNORING LINE");
	    next;
	}
	if ($skip_uncurated && $evcode eq "IEA") {
	    next;
	}
	if (%evyes && !$evyes{$evcode}) {
	    next;
	}
	if (%evno && $evno{$evcode}) {
	    next;
	}
	$prodtaxa =~ s/taxonid://gi;
	$prodtaxa =~ s/taxon://gi;

	if (!$prodtaxa) {
	    if (!$taxa_warning) {
		$taxa_warning = 1;
		$self->parse_err("No NCBI TAXON specified; ignoring");
	    }
	}
	else {
	    if ($prodtaxa !~ /\d+/) {
		if (!$taxa_warning) {
		    $taxa_warning = 1;
		    $self->parse_err("No NCBI TAXON wrong fmt: $prodtaxa");
		    $prodtaxa = "";
		}
	    }
	}

        # check for new element; shift a level
	my $new_dbset = $proddb ne $last[$PRODDB];
	my $new_prodacc =
	  $prodacc ne $last[$PRODACC] || $new_dbset;
	my $new_assoc =
	  ($termacc ne $last[$TERMACC]) ||
	    $new_prodacc ||
	      ($qualifier ne $last[$QUALIFIER]) ||
		($source_db ne $last[$SOURCE_DB]) ||
		  ($assocdate ne $last[$ASSOCDATE]);

        if (!$new_prodacc && ($prodtaxa ne $last[$PRODTAXA])) {
            # two identical gene products with the same taxon
            # IGNORE!
	    $self->parse_err("different taxa ($prodtaxa, $last[$PRODTAXA]) for same product $prodacc");
            next;
        }

	# close finished events
	if ($new_assoc) {
	    $self->pop_stack_to_depth(3) if $last[$TERMACC];
	    #	    $self->end_event("assoc") if $last[$TERMACC];
	}
	if ($new_prodacc) {
	    $self->pop_stack_to_depth(2) if $last[$PRODACC];
	    #	    $self->end_event("prod") if $last[$PRODACC];
	}
	if ($new_dbset) {
	    $self->pop_stack_to_depth(1) if $last[$PRODDB];
	    #	    $self->end_event("dbset") if $last[$PRODDB];
	}
	# open new events
	if ($new_dbset) {
	    $self->start_event(DBSET);
	    $self->event(PRODDB, $proddb);
	}
	if ($new_prodacc) {
	    $self->start_event(PROD);
	    $self->event(PRODACC, $prodacc);
	    $self->event(PRODSYMBOL, $prodsymbol);
	    $self->event(PRODNAME, $prodname) if $prodname;
	    $self->event(PRODTYPE, $prodtype) if $prodtype;
            if ($prodtaxa) {
                if ($prodtaxa =~ /\|/) {
                    my @other = ();
                    ($prodtaxa, @other) = split(/\s*\|\s*/, $prodtaxa);
                    if (@other > 1 ) {
                        $self->parse_err("max cardinality for PRODTAXA is 2. File says: $prodtaxa @other");
                    }
                    $self->event(SECONDARY_PRODTAXA, $other[0]);
                }
                $self->event(PRODTAXA, $prodtaxa);
            }
	    my $syn = $prodsyn;
	    if ($syn) {
		my @syns = split(/\|/, $syn);
		my %ucheck = ();
		@syns = grep {
		    if ($ucheck{lc($_)}) {
			0;
		    }
		    else {
			$ucheck{lc($_)} = 1;
			1;
		    }
		} @syns;
		map {
		    $self->event(PRODSYN, $_);
		} @syns;
	    }
	}
	if ($new_assoc) {
	    my $assocdate = $assocdate;
	    $self->start_event(ASSOC);
	    if ($assocdate) {
		if ($assocdate && length($assocdate) == 8) {
		    $self->event(ASSOCDATE, $assocdate);
		}
		else {
		    $self->parse_err("ASSOCDATE wrong format (must be YYYYMMDD): $assocdate");
		}
	    }
	    $self->event(SOURCE_DB, $source_db)
		    if $source_db;
	    $self->event(TERMACC, $termacc);
            my @quals = map lc,split(/[;\,]\s*/,$qualifier || '');
	    my $is_not = grep {/^not$/i} @quals;
	    $self->event(IS_NOT, $is_not || '0');
	    $self->event(QUALIFIER, $_) foreach @quals;
	    $self->event(ASPECT, $aspect);
            if ($term_refinement) {
                #$self->parse_term_refinement($term_refinement);
            }
	}
	$self->start_event(EVIDENCE);
	$self->event(EVCODE, $evcode);
	if ($with) {
	    my @seq_accs = split(/\s*[\|\;]\s*/, $with);
	    $self->event(WITH, $_)
	      foreach @seq_accs;
	    if (@seq_accs > 1) {
		if ($evcode ne 'IGI' &&
		    $evcode ne 'IPI' &&
		    $evcode ne 'ISS' &&
		    $evcode ne 'IEA'
		   ) {
		    $self->parse_err("cardinality of WITH > 1 [@seq_accs] and evcode $evcode is NOT RECOMMENDED - see GO docs");
		}
	    }
	}
	map {
	    $self->event(REF, $_)
	} split(/\|/, $ref);
	$self->end_event(EVIDENCE);
	#@last = @vals;
        @last =
          (
           $proddb,
           $prodacc,
           $prodsymbol,
           $qualifier,
           $termacc,
           $ref,
           $evcode,
           $with,
           $aspect,
           $prodname,
           $prodsyn,
           $prodtype,
           $prodtaxa,
           $assocdate,
           $source_db,
           $term_refinement,
          );
    }
    $fh->close;

    $self->pop_stack_to_depth(0);
}

#sub parse_term_refinement {
#    my $self = shift;
#    my $slotstr = shift;
#    $slotstr =~ s/\s+//;

#    my $idstr, $relation;

#    while (($idstr, $slotstr, $relation) = extract_bracketed($slotstr, '()')) {
#        $self->parse_term_refinement($idstr);
        
#    }
#}

1;

# 2.864 orig/handler
# 2.849 opt/handler
# 1.986 orig/xml
# 1.310 opt/xml
