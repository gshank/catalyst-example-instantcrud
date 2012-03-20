use strict;
use warnings;
use Test::More tests => 2;
use Path::Class;
use File::Path;
use DBI;

my $apptree = dir('t', 'tmp', 'My-App');
my $dbfile = file('t', 'tmp', 'test.db');
rmtree( [$apptree, $dbfile] );

my $testfile = file('t', 'tmp', 'test.db')->absolute->stringify;
my $sqlfile = file('t', 'var', 'test.sql')->absolute->stringify;
create_example_db( $testfile, $sqlfile );

my $tmpdir = dir(qw/ t tmp/);
my $libdir = dir(dir()->parent->parent, 'lib');
my $instant = file(dir()->parent->parent, 'script', 'instantcrud.pl');

my $currdir = dir()->absolute;
chdir $tmpdir;
my $line = "$^X -I$libdir ../../script/instantcrud.pl My::App -dsn='dbi:SQLite:dbname=$testfile' -noauth";
warn $line;
`$line`;
chdir $currdir;

ok( -f file(qw/ t tmp My-App lib My App DBSchema.pm/), 'DBSchema creation');
ok( -f file( qw/ t tmp My-App lib My App Controller Usr.pm / ), 'Controller for "User" created');

sub create_example_db {
    my ( $filename, $sqlfile ) = @_;
    my $dsn ||= 'dbi:SQLite:dbname=' . $filename;
    my $dbh = DBI->connect( $dsn ) or die "Cannot connect to $dsn\n";
    $dbh->{'sqlite_unicode'} = 1;

    my $sqlfh;
    open $sqlfh, $sqlfile;
    my $sql;
    {
        local $/;
        $sql = <$sqlfh>;
    }

    for my $statement ( split /;/, $sql ){
        next if $statement =~ /\A\s*\z/;
#        warn "executing: \n$statement";
        $dbh->do($statement) or die $dbh->errstr;
    }
    $dbh->disconnect;
}

