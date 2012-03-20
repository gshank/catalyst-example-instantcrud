package Catalyst::Plugin::Auth::Utils;

use warnings;
use strict;
use Carp;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Plugin::Auth::Utils - Methods and actions to simplify authentication

=head1 SYNOPSIS

    use Catalyst qw/
        HTML::Widget
        Authentication
	Authentication::Store::DBIC
	Authentication::Credential::Password
	Auth::Utils
    /;

    # in your Controller::Root.pm

    sub auto : ActionClass('Auth::Check') {
        $_[1]->stash->{login_action} = 'login';
    } 

    sub login : Local : ActionClass('Auth::Login') {}
    
    sub logout : Local : ActionClass('Auth::Logout') {}

=head1 DESCRIPTION

Methods and actions to simplify authentication

=head1 METHODS

=head2 $c->login_widget()

Returns a L<HTML::Widget> object filled with login and password fields to be used in login forms.

=cut

sub login_widget {
    my ( $c, %a ) = @_;
    my $login_field = $c->config->{authentication}{dbic}{user_field};
    # Don't know why but sometimes login_field is an array ref ???
    $login_field = $login_field->[0] if ref $login_field;
    my $pass_field  = $c->config->{authentication}{dbic}{password_field};
    my $user_class  = $c->config->{authentication}{dbic}{user_class};
    my $source      = $user_class->result_source;
    my $login_info  = $source->column_info($login_field);
    my $pass_info   = $source->column_info($pass_field);

    $c->widget('widget')->method('post');
    #$c->widget->action( $c->uri_for( $a{action} ? "/$a{action}" : '/login' ));
    
    # username field
    $c->widget('login')->element('Textfield', $login_field)
      ->label($login_info->{label} || 'Username')->size(30);
      
    # Constraints for username 
    for my $const ( @{ $login_info->{constraints} || [] } ){
        my $constraint = $c->widget('login')->constraint( $const->{constraint},
	  $login_field, $const->{args} ? @{$const->{args}} : () );
        $const->{$_} and $constraint->$_($const->{$_})
          for qw/min max regex callback in message/;
    }
    
    # password field
    $c->widget('login')->element('Password', $pass_field)
      ->label($pass_info->{label} || 'Password')->size(30);
      
    # Constraints for password 
    for my $const ( @{ $pass_info->{constraints} || [] } ){
	next if $const->{args} && $const->{args}[0] eq "$pass_field\_2";
        my $constraint = $c->widget('login')->constraint( $const->{constraint},
	  $pass_field, $const->{args} ? @{$const->{args}} : () );
        $const->{$_} and $constraint->$_($const->{$_})
	  for qw/min max regex callback in message/;
    }
    
    # Login 
    my $failled_logon = $c->config->{authentication}{dbic}{failled_logon_message};
    $c->widget('login')->constraint('Callback', $login_field)->callback(sub {
        my $username = shift;
	my $password =  $c->request->params->{$pass_field};
	return $c->login($username, $password);
    })->message($failled_logon || 'Bad username or password.');
		    
    $c->widget('button')->element( 'Submit', 'ok' )->value('Ok');

    return $c->widget('widget')
      ->embed($c->widget('login'))
      ->embed($c->widget('button'));
}

=head2 $c->redirect_to_login_unless_user_exists()

This method redirects to the login action unless an authenticated user is found

=cut

sub redirect_to_login_unless_user_exists {
    my ( $c ) = @_;
    my $action = $c->stash->{login_action} || 'login';
    # Allow unauthenticated users to reach the login page
    return 1 if $c->action->reverse eq $action;
    
    # If a user doesn't exist, force login
    if (!$c->user_exists) {
        $c->log->debug("User not found, forwarding to /$action");
        # Redirect the user to the login page
        $c->response->redirect($c->uri_for("/$action",
          { request_uri => $c->req->uri->as_string }));
        # Return 0 to cancel 'post-auto' processing and prevent use of application
        return 0;
    }
    # User found, so return 1 to continue with processing after this
    return 1;
};

package Catalyst::Action::Auth::Check;
use base 'Catalyst::Action';

sub execute {
    my $self = shift;
    my ($controller, $c ) = @_;
    $self->NEXT::execute( @_ );
    return $c->redirect_to_login_unless_user_exists;
}

package Catalyst::Action::Auth::Login;
use base 'Catalyst::Action';

sub execute {
    my $self = shift;
    my ($controller, $c ) = @_;
    my $widget = $c->login_widget->action($c->uri_for($c->action->reverse));
    if ($c->request->method eq 'POST') {
        $c->stash->{widget} = $widget->process($c->request);
        $c->response->redirect($c->req->params->{request_uri} || $c->uri_for('/'))
          unless $c->stash->{widget}->has_errors;
    } else {
        $c->stash->{widget} = $widget->process;
    }
    $self->NEXT::execute( @_ );
}

package Catalyst::Action::Auth::Logout;
use base 'Catalyst::Action';

sub execute {
    my $self = shift;
    my ($controller, $c ) = @_;
    $self->NEXT::execute( @_ );
    # Clear the user's state
    $c->logout;
    # Send the user to the starting point
    $c->response->redirect($c->uri_for('/'));
}

=head1 SEE ALSO

L<Catalyst>, L<HTML::Widget>, L<Catalyst::Plugin::HTML::Widget>

=head1 AUTHOR

Zbigniew Lukasiak>  C<zz bb yy @ gmail.com>

Jonas Alves, C<jonas.alves at gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
