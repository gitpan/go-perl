# $Id: base_parser.pm,v 1.5 2004/11/24 02:28:02 cmungall Exp $
#
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

package GO::Parsers::base_parser;

=head1 NAME

  GO::Parsers::base_parser     - base class for parsers

=head1 SYNOPSIS

  do not use this class directly; use GO::Parser

=cut

=head1 DESCRIPTION

=head1 AUTHOR

=cut

use Carp;
use FileHandle;
use Digest::MD5 qw(md5_hex);
use GO::Parser;
use base qw(Data::Stag::BaseGenerator Exporter);
use strict qw(subs vars refs);

# Exceptions

sub throw {
    my $self = shift;
    confess("@_");
}

sub warn {
    my $self = shift;
    warn("@_");
}

sub messages {
    my $self = shift;
    $self->{_messages} = shift if @_;
    return $self->{_messages};
}

*error_list = \&messages;

sub message {
    my $self = shift;
    my $msg = shift;
    CORE::warn 'deprecated';
    $self->parse_err($msg);
}

=head2 show_messages

  Usage   -
  Returns -
  Args    -

=cut

sub show_messages {
    my $self = shift;
    my $fh = shift;
    $fh = \*STDERR unless $fh;
    foreach my $e (@{$self->error_list || []}) {
        printf $fh "\n===\n  Line:%s [%s]\n%s\n  %s\n\n", $e->{line_no} || "", $e->{file} || "", $e->{line} || "", $e->{msg} || "";
    }
}

sub init {
    my $self = shift;

    $self->messages([]);
    $self->acc2termname({});
    $self;
}

sub parsed_ontology {
    my $self = shift;
    $self->{parsed_ontology} = shift if @_;
    return $self->{parsed_ontology};
}

sub acc2termname {
    my $self = shift;
    $self->{_acc2termname} = shift if @_;
    return $self->{_acc2termname};
}

=head2 normalize_files

  Usage   - @files = $parser->normalize_files(@files)
  Returns -
  Args    -

takes a list of filenames/paths, "glob"s them, uncompresses any compressed files and returns the new file list

=cut

sub normalize_files {
    my $self = shift;
    my $dtype;
    my @files = map {glob $_} @_;
    my @errors = ();
    my @nfiles = ();
    
    # uncompress any compressed files
    foreach my $fn (@files) {
        if ($fn =~ /\.gz$/) {
            my $nfn = $fn;
            $nfn =~ s/\.gz$//;
            my $cmd = "gzip -dc $fn > $nfn";
            print STDERR "Running $cmd\n";
            my $err = system("$cmd");
            if ($err) {
                push(@errors,
                     "can't uncompress $fn");
                next;
            }
            $fn = $nfn;
        }
        if ($fn =~ /\.Z$/) {
            my $nfn = $fn;
            $nfn =~ s/\.Z$//;
            my $cmd = "zcat $fn > $nfn";
            print STDERR "Running $cmd\n";
            my $err = system("$cmd");
            if ($err) {
                push(@errors,
                     "can't uncompress $fn");
                next;
            }
            $fn = $nfn;
        }
        push(@nfiles, $fn);
    }
    my %done = ();
    @files = grep { my $d = !$done{$_}; $done{$_} = 1; $d } @nfiles;
    return @files;
}

sub fire_source_event {
    my $self = shift;
    my $file = shift || die "need to pass file argument";
    my @fileparts = split(/\//, $file);
    my @stat = stat($file);
    my $mtime = $stat[9];
    $self->event(source => [
				     [source_type => 'file'],
				     [source_path => $fileparts[-1] ],
				     [source_md5 => md5_hex($fileparts[-1])],
				     [source_mtime => $mtime ],
				    ]
			 );
    return;
}
sub parse_assocs {
    my $self = shift;
    my $fn = shift;
    $self->dtype('go_assoc');
    my $p = GO::Parser->get_parser_impl('go_assoc');
    %$p = %$self;
    $p->parse($fn);
    return;
}

sub set_type {
    my ($self, $fmt) = @_;
    $self->dtype($fmt);
    my $p = GO::Parser->get_parser_impl($fmt);
    bless $self, ref($p);
    return;
}
sub dtype {
    my $self = shift;
    $self->{_dtype} = shift if @_;
    return $self->{_dtype};
}

sub parse_file {
    my ($self, $file, $dtype) = @_;

    $self->dtype($dtype);
    $self->parse($file);
}

sub xslt {
    my $self = shift;
    $self->{_xslt} = shift if @_;
    return $self->{_xslt};
}

sub force_namespace {
    my $self = shift;
    $self->{_force_namespace} = shift if @_;
    return $self->{_force_namespace};
}


sub parse {
    my ($self, @files) = @_;

    my $dtype = $self->dtype;
    foreach my $file (@files) {
        $self->file($file);

        # check for XSL transform
        if ($self->can('xslt') && $self->xslt) {

            # we want to pass the XML stream generated via
            # the parse to an XSL transform. We will do this
            # by lauching an external process to parse the file
            # and pipe this through an xsl transformation, like this
            #   go2xml <file> | go-apply-xslt <xsltfile> -
            # then parse the results as XML and pass them directly to
            # the handler

            my $xslt = $self->xslt;
            my $fmt_arg = '';
            my $err_arg = '';
            my $errf = "$$.err.xml";
            if ($dtype) {
                $fmt_arg = " -p $dtype";
            }
            if ($self->errhandler) {
                $err_arg = " -e $errf";
            }
            my $cmd = "go2xml $fmt_arg $err_arg $file | go-apply-xslt $xslt -";
            #print STDERR "CMD: $cmd\n";
            my $fh = FileHandle->new("$cmd |") || die("cannot open $cmd");
            my $load_parser = new GO::Parser ({format=>'obo_xml'});
            $load_parser->handler($self->handler);
            $load_parser->parse_fh($fh);
            if ($err_arg) {
                my $err_parser = new GO::Parser ({format=>'obo_xml'});
                $err_parser->handler($self->errhandler);
                $err_parser->parse($errf);
            }
        } else {
            # no XSL transform - perform parse as normal
            # (use Data::Stag superclass)
            $self->SUPER::parse($file);
        }
    }
}

sub litemode {
    my $self = shift;
    $self->{_litemode} = shift if @_;
    return $self->{_litemode};
}

sub dtd {
    undef;
}

1;
