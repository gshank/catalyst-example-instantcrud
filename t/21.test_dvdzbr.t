use strict;
use warnings;
use Test::More; 

BEGIN {
use lib 't/tmp/DVDzbr/lib';
}

eval "use Test::WWW::Mechanize::Catalyst 'DVDzbr'";
if ($@){
    plan skip_all => "Test::WWW::Mechanize::Catalyst required for testing application";
}else{
    plan tests => 20;
    #plan tests => 'no_plan';
}

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok("http://localhost/", "Application Running");

# $mech->content_lacks("dvdtag", "Do not list the relation tables");
# $mech->content_lacks("user_role", "Do not list the relation tables");
# 
# $mech->follow_link_ok({text => 'Restricted Area'}, "Go to restricted area");
# 
# $mech->content_like(qr/Username.*Password/, "Login Requested");
# $mech->submit_form(
#     form_number => 1,
#     fields      => {
#         username => 'jgda',
# 	password => 'jonas',
#     },
# );
# 
# $mech->follow_link_ok({text => 'Restricted Area'}, "Go to restricted area");
# $mech->content_contains("This is the restricted area", "Yes, we are logged in");
 
$mech->follow_link_ok({text => 'Tag'}, "Click on tag");
$mech->follow_link_ok({text => 'Add'}, "Let's add a tag :)");
$mech->submit_form(
    form_number => 1,
    fields      => {
        name => 'TestTag',
	#dvdtags => 0,
    }
);
$mech->follow_link_ok({text => 'List'}, "Let's list them all");
$mech->follow_link_ok({text => 'Name'}, "Let's sort them");
$mech->content_contains("TestTag", "Yes, our tag is listed");

$mech->get_ok("/user/edit", "Adding a User");
$mech->submit_form(
    form_number => 1,
    fields      => {
        name => 'Zbigniew Lukasiak',
        username => 'zby',
	password => 'zby',
 
        #dvd_owners => 0,
        #dvd_current_owners => 0,
        #user_roles => 0,
    },
);
# $mech->content_contains("Confirm the password", "Password constraint");
# 
# $mech->submit_form(
#     form_number => 1,
#     fields      => {
#         name => 'Zbigniew Lukasiak',
#         username => 'zby',
# 	password => 'zby',
# 	password_2 => 'zbyyyy',
#  
#         #dvd_owners => 0,
#         #dvd_current_owners => 0,
#         #user_roles => 0,
#     }
# );
# $mech->content_contains("Passwords must match", "Password constraint");
# 
# $mech->submit_form(
#     form_number => 1,
#     fields      => {
#         name => 'Zbigniew Lukasiak',
#         username => 'zby',
# 	password => 'zby',
# 	password_2 => 'zby',
# 
#         #dvd_owners => 0,
#         #dvd_current_owners => 0,
#         #user_roles => 0,
#     }
# );
$mech->content_contains('Zbigniew Lukasiak', "User added");
$mech->get_ok("/user", "Listing Users");
$mech->content_contains("Zbigniew Lukasiak", "User listed");

$mech->get_ok("/dvd/edit", "Adding a DVD with a related Tag");

# Hack to simulate the selection of a value in the double select
#$mech->form_number(1)->push_input(option => {name => 'tags', value => '1' });

$mech->submit_form(
    form_number => 1,
    fields      => {
        name => 'Jurassic Park II',
        tags =>  1,
        owner => 1,
        current_owner => 2,
        hour => '10:00',
        'creation_date.year' => '1990',
        'creation_date.month' => '08',
        'creation_date.day' => '23',
        'alter_date.year' => '2000',
        'alter_date.month' => '02',
        'alter_date.day' => '17',
	imdb_id => 133,
    }
);

$mech->content_contains('Jurassic Park II', "DVD added");
$mech->content_like(qr/Tags[^A]+Action/, "DVD added with Tag");
$mech->get_ok("/dvd", "Listing DVD's");
$mech->content_contains("Jurassic Park II", "DVD Listed");
$mech->content_contains("Action", "Related Tag Listed");

$mech->follow_link_ok({text => 'Edit'}, "Editing a DVD");
$mech->submit_form(
    form_number => 1,
    fields      => {
        name => 'Big Fish',
        #dvdtags => 0,
        owner => 1,
        current_owner => 2,
        hour => '10:00',
        'creation_date.year' => '1990',
        'creation_date.month' => '08',
        'creation_date.day' => '23',
        'alter_date.year' => '2000',
        'alter_date.month' => '02',
        'alter_date.day' => '17',
	imdb_id => 133,
    }
);
$mech->content_like(qr/Name[^B]+Big Fish/, "DVD eddited");
$mech->get_ok("/dvd", "Listing DVD's");
$mech->content_contains("Big Fish", "DVD Listed");



