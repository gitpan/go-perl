# $id$

use ExtUtils::MakeMaker;
require 5.6.0;
#use Config;

if (system("which xsltproc > /dev/null")) {
    print <<MSG;

NOTICE: ** You do not have xsltproc **

This tool is not required for go-perl, but it is useful for for
certain kinds of format conversion (eg converting to OWL format). You
will also need this tool if you are installing go-db-perl

You can safely ignore this notification message; Even if you do intend
to use go-db-perl later, you can install xsltproc at a later date

xsltproc is available as part of libxslt. See http://xmlsoft.org/XSLT/
for details

MSG
      
}

$p = "XML::Parser::PerlSAX";
if (!eval "require $p") {
    print <<MSG;

NOTICE: ** You do not have XML::Parser::PerlSAX installed **

This module is not required for go-perl, but it is required if you
wish to parse Obo-XML files. It is also required by the go-db-perl
library for loading the GO Database.

If you do not intend to use either Obo-XML or go-db-perl, then you may
continue. Even if you do care about these, you may continue and
install XML::Parser::PerlSAX at some future time.

MSG
      
}

my $seq_ok = 1;
$p = "Bio::Seq";
if (!eval "require $p") {
    $seq_ok = 0;
    print <<MSG;

NOTICE: ** You do not have BioPerl installed **
MSG

}
$p = "Digest::MD5";
if (!eval "require $p") {
    $seq_ok = 0;
    print <<MSG;

NOTICE: ** You do not have Digest::MD5 installed **
MSG

}

if (!$seq_ok) {

    print <<MSG;

BioPerl and Digest::MD5 are required if you wish to install
AmiGO. They are also required for some applications involving
sequences.

If you don't care about these, then you can ignore this message. If
you do care about these, you can still ignore this message for now and
install both BioPerl and Digest::MD5 later on

MSG
      
}


WriteMakefile(
	      'NAME'         => "GO",
	      'DISTNAME'         => "go-perl",
	      'ABSTRACT'     => 'GO Perl',
	      'AUTHOR'       => 'Chris Mungall <cjm@fruitfly.org>',
	      'VERSION_FROM' => "go-perl.pod",
	      'PREREQ_PM'    => {
				 'Data::Stag'         => "0.07",
                                 #'Bio::Seq'           => 0,
                                 'Data::Dumper'           => 0,
                                 #'Digest::MD5'         => 0,
				},
#               PL_FILES	=> { 'doc/makedoc.PL' => ['bioscripts.pod','biodatabases.pod','biodesign.pod','bioperl.pod'] },
	      'EXE_FILES'    => [
                                 qw(
                                    scripts/go-export-graph.pl
                                    scripts/go-export-prolog.pl
                                    scripts/go2chadoxml
                                    scripts/go2error_report
                                    scripts/go2fmt.pl
                                    scripts/go2godb_prestore
                                    scripts/go2obo
                                    scripts/go2obo_html
                                    scripts/go2obo_text
                                    scripts/go2obo_xml
                                    scripts/go2owl
                                    scripts/go2pathlist
                                    scripts/go2prolog
                                    scripts/go2rdf
                                    scripts/go2rdfxml
                                    scripts/go2summary
                                    scripts/go2sxpr
                                    scripts/go2tbl
                                    scripts/go2text_html
                                    scripts/go2xml
                                    scripts/map2slim
                                   )
				],
	      'dist'         => { 
				 'SUFFIX'       => ".gz",
				 'DIST_DEFAULT' => 'all tardist',
				 'COMPRESS'     => "gzip -9f" 
				},
	      clean => {
			FILES => 'go-perl-$(VERSION).tar.gz',
		       },
	     );


sub MY::postamble {
  qq{

pod :: \
	go-perl-make-pod-html.pl < MANIFEST

pod.tar.gz :: pod\
	tar cvf pod.tar pod && gzip pod.tar

  };  
}

