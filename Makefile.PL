# $id$

use ExtUtils::MakeMaker;
use XML::LibXSLT;
require 5.6.0;
#use Config;

my $p = "XML::LibXSLT";
if (!eval "require $p") {
    print <<MSG;

You do not have XML::LibXSLT installed

This module is not required for go-perl, but it is useful for use in
conjunction with the XSL files that are part of the go-dev/xml
distribution.

If you intend to also install go-db-perl, you will require the
xsltproc executable, which comes as part of the libxslt distribution.

If you do not intend to use either XSL or go-db-perl, then you may
continue. Even if you do care about these, you may continue and
install XML::LibXSLT and libxslt at some future time.

If you are having problems installing XML::LibXSLT, please consult

  http://www.godatabase.org/dev/xml/doc/xml-doc.html

MSG
      
}


WriteMakefile(
	      'NAME'         => "GO",
	      'DISTNAME'         => "go-perl",
	      'ABSTRACT'     => 'GO Perl',
	      'AUTHOR'       => 'Chris Mungall <cjm@fruitfly.org>',
	      'VERSION_FROM' => "go-perl.pod",
	      'PREREQ_PM'    => {
				 'XML::Writer'         => 0,
				 'Data::Stag'         => "0.07",
                                 'Bio::Seq'           => 0,
                                 'Data::Dumper'           => 0,
                                 'Digest::MD5'         => 0,
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

  };  
}

