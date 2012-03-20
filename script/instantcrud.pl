#!/usr/bin/perl -w

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use Getopt::Long;
use Pod::Usage;
use Path::Class;
use File::Slurp;
use Catalyst::Helper::InstantCRUD;
use Catalyst::Utils;
use Data::Dumper;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;
use DBIx::Class::Schema::Loader::RelBuilder;
use List::Util qw(first);
use DBI;
use Lingua::EN::Inflect::Phrase;
use utf8;

my $appname = $ARGV[0];

my $help     = 0;
my $adv_help = 0;
my $nonew    = 0;
my $scripts  = 0;
my $short    = 0;
my $auth     = 1;
my $rest     = 0;
my $dsn;
my $duser;
my $dpassword;
my $model_name  = 'DBICSchemamodel';
my $schema_name = 'DBSchema';
my %auth;
my %authz;

GetOptions(
    'help|?'  => \$help,
    'advanced_help'  => \$adv_help,
    'rest'   => \$rest,
    'nonew'   => \$nonew,
    'scripts' => \$scripts,
    'short'   => \$short,
    'dsn=s'     => \$dsn,
    'user=s'    => \$duser,
    'password=s'=> \$dpassword,
    'auth!'      => \$auth,
    
    'model_name=s'=> \$model_name,
    'schema_name=s'=> \$schema_name,
    
    'auth_user_table=s' => \$auth{user_table},
    'auth_user_field=s' => \$auth{user_field},
    'auth_password_field=s' => \$auth{password_field},
    'auth_password_type=s' => \$auth{password_type},
    'auth_password_hash_type=s' => \$auth{password_hash_type},
    'auth_user_role_user_field=s' => \$auth{user_role_user_field},
    
    'authz_role_table=s' => \$authz{role_table},
    'authz_role_field=s' => \$authz{role_field},
    'authz_user_role_user_field=s' => \$authz{user_role_user_field},
    'authz_role_rel=s' => \$authz{role_rel},
);

pod2usage($adv_help ? 1 : 2) if $help || $adv_help || !$appname;

# Application
my $appdir = $appname;
$appdir =~ s/::/-/g;
if( -d $appdir ){
    warn "\nThe directory '$appdir' already exists! Cannot recreate '$appname'!\n\n";
    pod2usage(1);
    exit;
}

my $db_file;
if( ! $dsn ){
    $db_file = lc $appname . '.db';
    $db_file =~ s/::/_/g;
    $db_file = file( $appdir, $db_file )->absolute->stringify;
    $dsn = "dbi:SQLite:dbname=$db_file";
}

my $helper = Catalyst::Helper::InstantCRUD->new( {
    '.newfiles'   => !$nonew,
    'scripts'     => $scripts,
    'short'       => $short,
    'model_name'  => $model_name,
    'schema_name' => $schema_name,
    'auth'        => \%auth,
    'authz'       => \%authz,
    'rest'        => $rest,
    'dsn'         => $dsn,
    'duser'        => $duser,
    'dpassword'    => $dpassword,
} );
    
if( ! $helper->mk_app( $appname ) ){
    warn "Cannot create application: $appname\n";
    pod2usage(1);
    exit;
}

if( $db_file ){
    create_example_db( $db_file );
    warn "Database created at $db_file\n";
}

local $FindBin::Bin = dir($appdir, 'script');

my $full_schema_name = $appname . '::' . $schema_name;
make_schema_at(
    $full_schema_name,
    { 
#        debug => 1, 
        dump_directory => dir( $appdir , 'lib')->absolute->stringify, 
        use_namespaces => 1,
#        default_resultset_class => '+DBIx::Class::ResultSet::RecursiveUpdate', 
        components => [ 'InflateColumn::DateTime', 'UTF8Columns' ],
    },
    [ $dsn, $duser, $dpassword ],
);

#{
#    no strict 'refs';
#    @{"$schema_name\::ISA"} = qw/DBIx::Class::Schema::Loader/;
#    $schema_name->loader_options(relationships => 1, exclude => qr/^sqlite_sequence$/);
#}

my $schema = $full_schema_name->connect(); #$dsn, $duser, $dpassword);

my ( $m2m, $bridges ) = guess_m2m( $schema );
for my $result_class ( $schema->sources ){ 
    my $result_source = $schema->source( $result_class );
    my $overload_method = first { $_ =~ /name/i } $result_source->columns;
    $overload_method ||= 'id';
    my @path = split /::/ , $appname . '::' . $schema_name;
    my $file = file( $appdir, 'lib', @path, 'Result', $result_class . '.pm' )->absolute->stringify;
    my $content = File::Slurp::slurp( $file );
    my $addition = q/use overload '""' => sub {$_[0]->/ . $overload_method . "}, fallback => 1;\n";
    for my $m ( @{$m2m->{$result_class}} ){
        my $a0 = $m->[0];
        my $a1 = $m->[1];
        my $a2 = $m->[2];
        $addition .= "__PACKAGE__->many_to_many('$a0', '$a1' => '$a2');\n";
    }
    my @columns = $result_source->columns;
    $addition .= "__PACKAGE__->utf8_columns(qw/@columns/);\n";
    $content =~ s/1;\s*/$addition\n1;/;
    File::Slurp::write_file( $file, $content );
}

# Controllers
$helper->mk_component ( $appname, 'controller', 'InstantCRUD', 'InstantCRUD',
  $schema, $m2m,
);

# Model
$helper->mk_component ( $appname, 'model', $model_name, 'DBIC::Schema', 
  $appname . '::' . $schema_name,
);

# View and Templates
$helper->mk_component ( $appname, 'view', 'TT', 'InstantCRUD', $schema, $m2m, $bridges );

sub guess_m2m {
    my $schema = shift;
    my %m2m;
    my %bridges;

    CLASS:
    for my $s ( $schema->sources ) {
        my $source = $schema->source($s);
        my @relationships = $source->relationships;
        my @cols = $source->columns;
        next if scalar @relationships != 2;
        next if scalar @cols!= 2;
        my @rclasses;
        for my $rel (@relationships) {
            my $info = $source->relationship_info($rel);
            next CLASS if $info->{attrs}{accessor} eq 'multi';
            my $rclass_name = $info->{class};
            $rclass_name =~ /([^:]*)$/;
            $rclass_name = $1;
            my $rsource = $schema->source( $rclass_name );
            my $found;
            for my $rrel ( $rsource->relationships ){
                my $rinfo = $rsource->relationship_info($rrel);
                my $rrclass_name = $rinfo->{class};
                $rrclass_name =~ /([^:]*)$/;
                $rrclass_name = $1;
                if( $rrclass_name eq $s ){
                    $found = $rrel;
                    last;
                }
            }
            next CLASS if not $found;
            push @rclasses, { rclass => $rclass_name, bridge => [ $found, $rel ] };
        }
        push @{$m2m{ $rclasses[0]->{rclass} }}, [ 
            Lingua::EN::Inflect::Phrase::to_PL( $rclasses[1]->{bridge}[1] ), 
            $rclasses[1]->{bridge}[0], 
            $rclasses[1]->{bridge}[1] 
        ];
        push @{$m2m{ $rclasses[1]->{rclass} }}, [ 
            Lingua::EN::Inflect::Phrase::to_PL( $rclasses[0]->{bridge}[1] ), 
            $rclasses[0]->{bridge}[0], 
            $rclasses[0]->{bridge}[1] 
        ];
        $bridges{$s} = 1;
    }
    return \%m2m, \%bridges;
}
    
sub create_example_db {
    my $filename = shift;
    my $dsn ||= 'dbi:SQLite:dbname=' . $filename;
    my $dbh = DBI->connect( $dsn ) or die "Cannot connect to $dsn\n";
    $dbh->{'sqlite_unicode'} = 1;

    my $sql;
    {
        local $/;
        $sql = <DATA>;
    }

    for my $statement ( split /;/, $sql ){
        next if $statement =~ /\A\s*\z/;
#        warn "executing: \n$statement";
        $dbh->do($statement) or die $dbh->errstr;
    }
    $dbh->disconnect;
}


1;

=head1 NAME

instantcrud.pl - Bootstrap a Catalyst application example

=head1 SYNOPSIS

instantcrud.pl ApplicationName [options]

 Options:
   -dsn            dsn
   -user           database user
   -password       database password
   -help           display this help and exits
   -model_name     model name (default: DBICSchemamodel) 
   -schema_name    schema name (default: DBSchema) 

 ApplicationName must be a valid Perl module name and can include "::".
 This version cannot update previously generated code base - it can only
 generate a new one.

 All options are optional, if no dsn is provided an example SQLite database will be 
 created and used.

 Examples:
    instantcrud.pl My::App -dsn='dbi:Pg:dbname=CE' -user=zby -password='pass' 

=head1 DESCRIPTION

The C<catalyst.pl> script bootstraps a Catalyst application example, creating 
a directory structure populated with skeleton files.  

The application name must be a valid Perl module name.  The name of the
directory created is formed from the application name supplied, with double
colons replaced with hyphens (so, for example, the directory for C<My::App> is
C<My-App>).

Using the example application name C<My::App>, the application directory will
contain the following items:

=over 4

=item README

a skeleton README file, which you are encouraged to expand on

=item Build.PL

a C<Module::Build> build script

=item Changes

a changes file with an initial entry for the creation of the application

=item Makefile.PL

an old-style MakeMaker script.  Catalyst uses the C<Module::Build> system so
this script actually generates a Makeifle that invokes the Build script.

=item lib

contains the application module (C<My/App.pm>) and
subdirectories for model, view, and controller components (C<My/App/M>,
C<My/App/V>, and C<My/App/C>).  

=item root

root directory for your web document content.  This is left empty.

=item script

a directory containing helper scripts:

=over 4

=item C<my_app_create.pl>

helper script to generate new component modules

=item C<my_app_server.pl>

runs the generated application within a Catalyst test server, which can be
used for testing without resorting to a full-blown web server configuration.

=item C<my_app_cgi.pl>

runs the generated application as a CGI script

=item C<my_app_fastcgi.pl>

runs the generated application as a FastCGI script

=item C<my_app_test.pl>

runs an action of the generated application from the comand line.

=back

=item t

test directory

=back

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Manual::Intro>

=head1 AUTHOR

Zbigniew Lukasiak, C<zz bb yy@gmail.com>
Jonas Alves, C<jonas.alves at gmail.com>

Based on catalyst.pl by:

Andrew Ford, C<A.Ford@ford-mason.co.uk>
Sebastian Riedel, C<sri@oook.de>,
Jonathan Manning

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__DATA__
BEGIN TRANSACTION;
CREATE TABLE dvd (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) DEFAULT NULL,
  imdb_id INTEGER DEFAULT NULL,
  owner INTEGER NOT NULL REFERENCES user (id),
  current_borrower INTEGER DEFAULT NULL REFERENCES user (id),
  creation_date date DEFAULT NULL,
  alter_date datetime DEFAULT NULL,
  hour time DEFAULT NULL
);
INSERT INTO "dvd" VALUES(2,'Hohoho',1,1,1,'1990-08-23','2000-02-17 10:00:00','10:00');
DELETE FROM sqlite_sequence;
INSERT INTO "sqlite_sequence" VALUES('role',2);
INSERT INTO "sqlite_sequence" VALUES('tag',25);
INSERT INTO "sqlite_sequence" VALUES('user',3);
INSERT INTO "sqlite_sequence" VALUES('dvd',4);
CREATE TABLE dvdtag (
  dvd INTEGER NOT NULL DEFAULT '0' REFERENCES dvd (id),
  tag INTEGER NOT NULL DEFAULT '0' REFERENCES tag (id),
  PRIMARY KEY (dvd,tag)
);
INSERT INTO "dvdtag" VALUES(2,1);
INSERT INTO "dvdtag" VALUES(2,2);
INSERT INTO "dvdtag" VALUES(2,5);
INSERT INTO "dvdtag" VALUES(2,6);
INSERT INTO "dvdtag" VALUES(3,1);
INSERT INTO "dvdtag" VALUES(0,7);
INSERT INTO "dvdtag" VALUES(4,1);
INSERT INTO "dvdtag" VALUES(1,0);
INSERT INTO "dvdtag" VALUES(1,1);
INSERT INTO "dvdtag" VALUES(1,2);
INSERT INTO "dvdtag" VALUES(1,4);
INSERT INTO "dvdtag" VALUES(1,6);
CREATE TABLE role (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  role VARCHAR(255)
);
INSERT INTO "role" VALUES(1,'Write');
INSERT INTO "role" VALUES(2,'Read');
CREATE TABLE tag (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) DEFAULT NULL
);
INSERT INTO "tag" VALUES(1,'Action');
INSERT INTO "tag" VALUES(2,'Romance');
INSERT INTO "tag" VALUES(3,'Tag1');
INSERT INTO "tag" VALUES(4,'Tag2');
INSERT INTO "tag" VALUES(5,'Tag3');
INSERT INTO "tag" VALUES(6,'Tag4');
INSERT INTO "tag" VALUES(8,'aa');
INSERT INTO "tag" VALUES(9,'aaa');
INSERT INTO "tag" VALUES(10,'aaaa');
INSERT INTO "tag" VALUES(11,'aaaaa');
INSERT INTO "tag" VALUES(12,'aaaaa');
INSERT INTO "tag" VALUES(13,'aaaaaa');
INSERT INTO "tag" VALUES(14,'aaaaaaa');
INSERT INTO "tag" VALUES(15,'aaaaaaaa');
INSERT INTO "tag" VALUES(16,'aaaaaaaaa');
INSERT INTO "tag" VALUES(17,'aaaaaaaaaa');
INSERT INTO "tag" VALUES(18,'aaaaaaaaaaa');
INSERT INTO "tag" VALUES(19,'aaaaaaaaaaaa');
INSERT INTO "tag" VALUES(20,'aaaaaaaaaaaaa');
INSERT INTO "tag" VALUES(21,'aaaaaaaaaaaaaa');
INSERT INTO "tag" VALUES(22,'aaaaaaaaaaaaaaa');
INSERT INTO "tag" VALUES(23,'aaaaaaaaaaaaaaaa');
INSERT INTO "tag" VALUES(24,'aaaaaaaaaaaaaaaaa');
INSERT INTO "tag" VALUES(25,'aaaaaaaaaaaaaaaaaa');
CREATE TABLE user (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  username VARCHAR(255) DEFAULT NULL,
  password VARCHAR(255) DEFAULT NULL,
  name VARCHAR(255) DEFAULT NULL
);
INSERT INTO "user" VALUES(1,'jgda','35a2c6fae61f8077aab61faa4019722abf05093c','Jonas Alves');
INSERT INTO "user" VALUES(2,'maya','59dc310530b44e8dd1231682b4cc5f2458af1c60','Maya');
CREATE TABLE user_role (
  user INTEGER NOT NULL DEFAULT '0' REFERENCES user (id),
  role INTEGER NOT NULL DEFAULT '0' REFERENCES role (id),
  PRIMARY KEY (user, role)
);
INSERT INTO "user_role" VALUES(1,1);
INSERT INTO "user_role" VALUES(1,2);
INSERT INTO "user_role" VALUES(3,0);
CREATE TABLE unicode_examples (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  iso_country_code CHAR(2),
  language_name varchar(255),
  main_unicode_set varchar(255),
  example_text text
);

INSERT INTO "unicode_examples" VALUES(1,'PL','Polish','Latin Extended A','Literki z ogonkami alfabetycznie: ąćęłńóśżźĄĆĘŁŃÓŚŹŻ (acelnoszzACELNOSZZ)');
INSERT INTO "unicode_examples" VALUES(2,'DE','German','Latin-1 Supplement','äöüÄÖÜß');
INSERT INTO "unicode_examples" VALUES(3,'RU','Russian','Cyrillic','Это текст на русском языке');
INSERT INTO "unicode_examples" VALUES(4,'','Math Symbols','Mathematical Operators','(x ∊ A ∪ B) ≡ (x ∊ A)∨(x ∊ B)');
COMMIT;
