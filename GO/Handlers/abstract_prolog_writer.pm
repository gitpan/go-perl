
package GO::Handlers::abstract_prolog_writer;
use base qw(GO::Handlers::base Exporter);
use strict;

sub out {
    my $self = shift;
    $self->print("@_");
}

sub cmt {
    my $self = shift;
    my $cmt = shift;
    $self->out(" % $cmt") if $cmt;
    return;
}

sub prologquote {
    my $s = shift;
    $s = '' unless defined $s;
    $s =~ s/\'/\'\'/g;
    "'$s'";
}

sub nl {
    shift->print("\n");
}

sub fact {
    my $self = shift;
    my $pred = shift;
    my @args = @{shift||[]};
    my $cmt = shift;
    $self->out(sprintf("$pred(%s).",
		       join(', ', map {prologquote($_)} @args)));
    $self->cmt($cmt);
    $self->nl;
}

1;
