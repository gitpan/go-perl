# $Id: go_def.pm,v 1.2 2004/03/19 01:42:18 cmungall Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

=head1 NAME

  GO::Handlers::go_def     - 

=head1 SYNOPSIS

  use GO::Handlers::go_def

=cut

=head1 DESCRIPTION

=head1 PUBLIC METHODS - 

=cut

# makes objects from parser events

package GO::Handlers::go_def;
use base qw(GO::Handlers::base);
use strict;


sub e_term {
    my $self = shift;
    my $t = shift;
    my $n = $t->get_name || '';
    my $def = $t->get_definition;
    if ($def) {
        $self->tag(term => $n);
        $self->tag(goid => $t->get_id);
        $self->tag(definition => $def->sget_definition_text);
        $self->tag(definition_reference => $_) foreach $def->get_definition_reference;
        $self->tag(comment => $def->sget_comment);

        $self->print("\n");
    }
    return;

}

sub tag {
    my $self = shift;
    my ($t, $v) = @_;
    return unless $v;
    $self->printf("%s: %s\n", $t, $v);
#    $self->print("$t: $v\n");
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
    $word =~ s/\'//g;
    $word =~ s/\"/\\\"/g;
    $word =~ tr/a-zA-Z0-9_//cd;
    "\"$word\"";
}

1;
