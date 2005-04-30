package GO::Parsers::obj_storable_parser;
use strict;
use base qw(GO::Parsers::obj_emitter GO::Parsers::base_parser);
use GO::Model::Graph;
use Storable qw(fd_retrieve);

sub parse_fh {
    my ($self, $fh) = @_;
    my $g = fd_retrieve($fh);
    $self->emit_graph($g);
    return $g;
}


1;
