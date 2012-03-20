use strict;
use warnings;
use Test::More; 
use String::Random qw(random_string random_regex);
use DBI;

BEGIN {
use lib 't/tmp/My-App/lib';
}

eval "use Test::WWW::Mechanize::Catalyst 'My::App'";
if ($@){
    plan skip_all => "Test::WWW::Mechanize::Catalyst required for testing application";
}else{
    plan tests => 24;
}

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok("http://localhost/", "Application Running");

$mech->follow_link_ok({text => 'Firsttable'}, "Click on firsttable");

$mech->follow_link_ok({text => 'Intfield'}, "sort by intfield");
$mech->content_contains("This is the row with the smallest int", "smallest int row found");

$mech->follow_link_ok({text => 'Intfield'}, "desc sort by intfield");
$mech->content_contains("This is the row with the biggest int", "biggest int row found");

$mech->follow_link_ok({text => '3'}, "desc sort by intfield page 3");
$mech->content_contains("This is the row with the smallest int", "smallest int row found");

$mech->get_ok("/firsttable/edit/2", "Edit fisttable 2nd record");
$mech->submit_form(
    form_number => 1,
    fields      => {
        intfield => '3',
        varfield => 'Changed varchar field',
        charfield => 'a',
    }
);
$mech->follow_link_ok({text => 'Firsttable'}, "Click on firsttable");
$mech->follow_link_ok({text => 'Varfield'}, "Sort by Varfield");
$mech->content_contains("Changed varchar field", "Record changed");
$mech->get_ok("/firsttable/destroy/2", "Destroy 2nd record");
$mech->submit_form( form_number => 1 );
$mech->follow_link_ok({text => 'Varfield'}, "Sort by Varfield");
$mech->content_lacks("Changed varchar field", "Record deleted");

$mech->follow_link_ok({text => 'ComposedKey'}, "Click on composed key table");
$mech->follow_link_ok({text => 'Add'}, "Click on composed key Add row");
my $id1 = int(rand(1000000));
my $id2 = int(rand(1000000));
$mech->submit_form(
    form_number => 1,
    fields      => {
        id1 => $id1,
        id2 => $id2,
        value => 'Varchar Field',
    }
);
$mech->content_like( qr{<b>Id1:</b></td>\s*<td>\s*$id1}, 'Viewing record with composed key' );
$mech->follow_link_ok({text => 'Edit'}, "Editing a record with composed key");
$mech->content_contains( $id1, 'Following Edit for a record with composed key' );
my $random_string = 'random ' . random_regex('\w{20}');
#DBI->trace(1);
$mech->submit_form(
    form_number => 1,
    fields      => {
        value => $random_string,
    }
);
$mech->content_contains( $id1, 'Editing record with composed key' );
$mech->content_contains( $random_string, 'Editing record with composed key' );
$mech->follow_link_ok({text => 'List'}, "Listing records with composed key");
$mech->content_contains( $random_string, 'Listing of records with composed key contains the new record' );

