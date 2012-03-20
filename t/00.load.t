use Test::More tests => 3;

BEGIN {
use_ok( 'Catalyst::Example::Controller::InstantCRUD' );
use_ok( 'Catalyst::Helper::Controller::InstantCRUD' );
use_ok( 'Catalyst::Example::InstantCRUD');
}

diag( "Testing Catalyst::Example::InstantCRUD $Catalyst::Example::InstantCRUD::VERSION" );
