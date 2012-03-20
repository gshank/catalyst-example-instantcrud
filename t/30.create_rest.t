use strict;
use warnings;
use Test::More tests => 1;
use Path::Class;
use File::Path;
use File::Copy;

my $app = 'DVDzbr_rest';
my $lcapp = lc $app;

rmtree( ["t/tmp/$app", "t/tmp/$lcapp.db"] );

`cd t/tmp; $^X -I../../lib ../../script/instantcrud.pl $app -rest`;

ok( -f "t/tmp/$app/lib/$app/DBSchema.pm", 'DBSchema creation');


