# $Id: obo_text_parser.pm,v 1.14 2004/11/25 18:57:28 cmungall Exp $
#
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

package GO::Parsers::obo_text_parser;

=head1 NAME

  GO::Parsers::obo_text_parser     - OBO Flat file parser object

=head1 SYNOPSIS

  do not use this class directly; use GO::Parser

=cut

=head1 DESCRIPTION


=cut

use Exporter;
use Text::Balanced qw(extract_quotelike extract_bracketed);
use base qw(GO::Parsers::base_parser);
use GO::Parsers::ParserEventNames;

use Carp;
use FileHandle;

use strict qw(vars refs);

sub dtd {
    'obo-parser-events.dtd';
}

sub parse_fh {
    my ($self, $fh) = @_;
    my $file = $self->file;
    my $litemode = $self->litemode;
    my $is_go;
    local($_);    # latest perl is more strict about modification of $_

    $self->start_event(OBO);
    $self->fire_source_event($file);
    $self->start_event(HEADER);
    my $in_hdr = 1;
    my $is_root = 1; # default
    my $namespace_set;
    my $namespace = $self->force_namespace;
    
    while(<$fh>) {
	chomp;

        tr [\200-\377]
          [\000-\177];   # see 'man perlop', section on tr/
        # weird ascii characters should be excluded
        tr/\0-\10//d;   # remove weird characters; ascii 0-8
                        # preserve \11 (9 - tab) and \12 (10-linefeed)
        tr/\13\14//d;   # remove weird characters; 11,12
                        # preserve \15 (13 - carriage return)
        tr/\16-\37//d;  # remove 14-31 (all rest before space)
        tr/\177//d;     # remove DEL character

        s/^\!.*//;
        s/[^\\]\!.*//;
        s/[^\\]\#.*//;
        s/^\s+//;
        s/\s+$//;
	next unless $_;
        next if $litemode && $_ !~ /^(\[|id:|name:|is_a:|relationship:)/;
	if (/^\[(\w+)\]\s*(.*)/) { # new stanza
	    my $stanza = lc($1);
            $is_root = 0 unless $stanza eq 'term';
	    my $rest = $2;
	    if ($in_hdr) {
		$in_hdr = 0;
		$self->end_event(HEADER);
	    }
	    else {
                if (!$namespace_set) {
                    if (!$namespace) {
                        $self->parse_err("missing namespace!");
                    }
                    else {
                        $self->event(NAMESPACE, $namespace);
                    }
                }
                $self->event(IS_ROOT,1) if $is_root;
                $is_root = 1; # assume root by default
                $namespace_set = 0;
		$self->end_event;
	    }
            $is_root = 0 unless $stanza eq 'term';
	    $self->start_event($stanza);
	}
        elsif ($in_hdr) {
            if (/^([\w\-]+)\:\s*(.*)/) {  # tag-val pair
                my ($tag, $val) = ($1,$2);
                $self->event($tag=>$val);
                if ($tag eq 'default-namespace') {
                    $namespace = $val
                      unless $namespace;
                }
            }
            else {
                $self->parse_err("illegal header entry: $_");
            }
        }
	elsif (/^([\w\-]+)\:\s*(.*)/) {  # tag-val pair
	    my ($tag, $val) = ($1,$2);
            my $qh;
            ($val, $qh) = extract_quals($val);
	    my $val2 = $val;
	    $val2 =~ s/\\,/,/g;
	    if ($tag eq RELATIONSHIP) {
		my ($type, $id) = split(' ', $val2);
		$val = [[TYPE,$type],[TO,$id]];
	    }
	    elsif ($tag eq INTERSECTION_OF) {
		my ($type, $id) = split(' ', $val2);
		$val = [[TYPE,$type],[TO,$id]];
	    }
	    elsif ($tag eq XREF_ANALOG) {
		my $dbxref = dbxref($val);
		$val = $dbxref->[1];
	    }
	    elsif ($tag eq XREF_UNKNOWN) {
		my $dbxref = dbxref($val);
		$val = $dbxref->[1];
	    }
	    elsif ($tag eq DEF) {
		my ($defstr, $parts) =
		  extract_qstr($val);
		$val =
		  [[DEFSTR,$defstr],
		   map {dbxref($_)} @$parts];
	    }
	    elsif ($tag =~ /(\w*)synonym/) {
                my $scope = $1 || '';
                if ($scope) {
                    $tag = SYNONYM;
                    if ($scope =~ /(\w+)_$/) {
                        $scope = $1;
                    }
                    else {
                        $self->parse_err("bad synonym type: $scope");
                        $scope = '';
                    }
                }
		my ($syn, $parts) =
		  extract_qstr($val);
                if ($qh->{scope}) {
                    if ($scope) {
                        if ($scope ne $qh->{scope}) {
                            $self->parse_err("inconsistent scope: $scope/$qh->{scope}");
                        }
                        else {
                            $self->parse_err("redundant scope: $scope");
                        }
                    }
                }
                else {
                    $qh->{scope} = $scope;
                }
		$val =
		  [[SYNONYM_TEXT,$syn],
		   (map {dbxref($_)} @$parts)];
	    }
	    else {
		$val = $val2;
		# normal tag:val
	    }
            if (!ref($val) && $val eq 'true') {
                $val = 1;
            }
            if (!ref($val) && $val eq 'false') {
                $val = 0;
            }
            if (%$qh) {
                # note that if attributes are used for
                # terminal nodes then we effectively have
                # to 'push the node down' a level;
                # eg
                # <is_a>x</is_a>
                #    ==> [is_a=>'x']
                # <is_a t="v">x</is_a> 
                #    ==> [is_a=>[[@=>[[t=>v]]],[.=>x]]]
                my $data = ref $val ? $val : [['.'=>$val]];
                my @quals = map {[$_=>$qh->{$_}]} keys %$qh;
                $self->event($tag=>[['@'=>[@quals]],
                                    @$data,
                                   ]);
            }
            else {
                $self->event($tag=>$val);
            }
            if ($tag eq IS_A || $tag eq RELATIONSHIP) {
                $is_root = 0;
            }
            if ($tag eq IS_OBSOLETE && $val) {
                $is_root = 0;
            }
	    if ($tag eq NAMESPACE) {
                $namespace_set = $val;
	    }
	}
	else {
	    $self->throw("uh oh: $_");
	}
    }

    # duplicated code! check final event
    if (!$namespace_set) {
        if (!$namespace) {
            $self->parse_err("missing namespace!");
        }
        else {
            $self->event(NAMESPACE, $namespace);
        }
    }
    $self->event(IS_ROOT,1) if $is_root;
    $self->pop_stack_to_depth(0);
    $self->parsed_ontology(1);
    return;
}

sub extract_quals {
    my $str = shift;

    my %q = ();
    if ($str =~ /(.*)\s+(\{.*\})\s*$/) {
        my $return_str = $1;
        my $extr = $2;
        if ($extr) {
            my @qparts = split_on_comma($extr);
            foreach (@qparts) {
                if (/(\w+)=\"(.*)\"/) {
                    $q{$1} = $2;
                }
                elsif (/(\w+)=\'(.*)\'/) {
                    $q{$1} = $2;
                }
                else {
                    warn("$_ in $str");
                }
            }
        }
        return ($return_str, \%q);
    }
    else {
        return ($str, {});
    }
}

sub extract_qstr {
    my $str = shift;

    my ($extr, $rem, $prefix) = extract_quotelike($str);
    my $txt = $extr;
    $txt =~ s/^\"//;
    $txt =~ s/\"$//;
    if ($prefix) {
	warn("illegal prefix: $prefix");
    }

    my @parts = ();
    while (($extr, $rem, $prefix) = extract_bracketed($rem, '[]')) {
	last unless $extr;
	$extr =~ s/^\[//;
	$extr =~ s/\]$//;
	push(@parts, $extr) if $extr;
    }
    @parts =
      map {split_on_comma($_)} @parts;
    
    $txt =~ s/\\//g;
    return ($txt, \@parts);
}

sub split_on_comma {
    my $str = shift;
    my @parts = ();
    while ($str =~ /(.*[^\\],\s*)(.*)/) {
	$str = $1;
	my $part = $2;
	unshift(@parts, $part);
	$str =~ s/,\s*$//;
    }
    unshift(@parts, $str);
    return map {s/\\//g;$_} @parts;
}

sub dbxref {
    my $str = shift;
    $str =~ s/\\//g;
    my $name;
    if ($str =~ /(.*)\s+\"(.*)\"$/) {
        $str = $1;
        $name = $2;
    }
    my ($db, @rest) = split(/:/, $str);
    my $acc = join(':',@rest);
    [DBXREF,[[ACC,$acc],
              [DBNAME,$db],
              defined $name ? [NAME,$name] : ()
             ]];
}

1;