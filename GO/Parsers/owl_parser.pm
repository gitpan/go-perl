# $Id: owl_parser.pm,v 1.2 2004/11/24 02:28:02 cmungall Exp $
#
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

package GO::Parsers::owl_parser;

=head1 NAME

  GO::Parsers::owl_parser.pm     - turns OWL XML into event stream

=head1 SYNOPSIS

  do not use this class directly; use GO::Parser

=cut

=head1 DESCRIPTION

this parser does a direct translation of XML to events, passed on to the handler

use GO::Handlers::owl_to_obo_handler to transform this stream into OBO-XML

=head1 AUTHOR

=cut

use Exporter;
use base qw(Data::Stag::XMLParser);


1;
