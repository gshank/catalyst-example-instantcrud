use strict;
use warnings;
use Test::More; 

BEGIN {
use lib 't/tmp/DVDzbr_rest/lib';
}

eval "use Test::WWW::Mechanize::Catalyst 'DVDzbr_rest'";
if ($@){
    plan skip_all => "Test::WWW::Mechanize::Catalyst required for testing application";
}else{
    plan tests => 2;
    #plan tests => 'no_plan';
}

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok("http://localhost/", "Application Running");

$mech->default_header( 'Content-Type' => "text/x-json");
$mech->default_header( 'Accept' => "text/x-json");

$mech->get_ok("http://localhost/dvd/by_id/2", "GET dvd object");
#warn $mech->content;

