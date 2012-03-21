use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME                => 'Catalyst::Example::InstantCRUD',
    AUTHOR              => '<Zbigniew Lukasiak> <<zz bb yy @ gmail.com>>',
    VERSION_FROM        => 'lib/Catalyst/Example/InstantCRUD.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Example/InstantCRUD.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Catalyst::Runtime'                                      => '5.90007',
        'Catalyst::Devel'                                        => '1.00',
        'Catalyst::View::TT'                                     => '0.21',
        'DBIx::Class'                                            => '0.08196',
        'DBIx::Class::Schema::Loader'                            => '0.07017',
        'DBIx::Class::ResultSet::RecursiveUpdate'                => 0,
        #'DBIx::Class::UTF8Columns'                               => 0,
        'Lingua::EN::Inflect::Phrase'                            => 0,
#        'DBIx::Class::DigestColumns'                             => 0,
#        'Template::Plugin::Class'                                => 0,
        'Catalyst::Model::DBIC::Schema'                          => 0.29,
        'Catalyst::Helper::Model::DBIC::Schema'                  => 0,
        'Catalyst::Plugin::ConfigLoader'                         => 0,
        'Catalyst::Plugin::Static::Simple'                       => 0,
        'Catalyst::Plugin::Unicode::Encoding'                              => 0,
	#'Catalyst::Plugin::Unicode'                              => 0,
#        'Catalyst::Plugin::Authentication'                       => '0.07',
#        'Catalyst::Plugin::Authentication::Store::DBIC'          => '0.07',
#        'Catalyst::Plugin::Authentication::Credential::Password' => 0,
        'Catalyst::Plugin::Session::State::Cookie'               => 0,
        'Catalyst::Plugin::Session::Store::FastMmap'             => 0,
	'Catalyst::Action::REST'	=> 0,
        'HTML::FormHandler::Generator::DBIC'                     => 0.03,
        'HTML::FormHandler::Model::DBIC'                         => 0.04,
        'HTML::FormHandler'                                      => 0.40001,
        'Path::Class'                                            => 0,
#        'URI::Escape'                                            => 0,
        'File::Slurp'                                            => 0,
        'Pod::Usage'                                             => 0,
        'List::Util'                                             => 0,
        'String::Random'                                         => 0,
	'MooseX::NonMoose'					 => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Example-InstantCRUD-*' },
    EXE_FILES           => ['script/instantcrud.pl'],
    LICENSE             => 'perl',
);

