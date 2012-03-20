package Catalyst::Example::Controller::InstantCRUD::REST;

use Moose;
BEGIN {
       extends 'Catalyst::Example::Controller::InstantCRUD';
}

use Carp;
use Data::Dumper;

our $VERSION = '002';

sub model_pks {
    my ( $self, $c ) = @_;
    my $rs = $self->model_resultset($c);
    my @pks = $rs->result_source->primary_columns;
    return @pks;
}

sub create_form : Action {
    my ( $self, $c, @pks ) = @_; 
    $self->edit( $c, @pks );
    $c->stash( template => 'edit.tt' );
}

sub by_id : Action : ActionClass('REST') { }

sub _get_form {
    my( $self, $c, $pks ) = @_;
    my $form_name = ref( $self ) . '::' . $self->source_name . 'Form';
    my @ids;
    @ids = ( item_id => $pks ) if defined $pks && @$pks;
    my $form = $form_name->new(
        schema => $self->model_schema($c),
#    item_class => $self->source_name($c),
        method => $c->req->method,
        params => $c->req->params,
        @ids,
    );
    my $field = HTML::FormHandler::Field::Hidden->new( 
        name => 'x-tunneled-method', 
        form => $form, 
        value => 'PUT',
    );
    $form->add_field($field);
    return $form;
}
    

sub by_id_GET : Action {
    my ( $self, $c, @args ) = @_; 
    my @model_pks = $self->model_pks( $c );
    my @pks = @args[ 0 .. scalar @model_pks - 1 ];
    my $view_type = $args[ scalar @model_pks ];
    $view_type = 'view' if !defined( $view_type ) or $view_type ne 'edit';
    my $item = $self->model_item( $c, @pks );
    $c->stash->{item} = $item;
    if( $view_type eq 'edit' ){
        my $form = $self->_get_form( $c, \@pks );
        $c->stash( form => $form );
    }
    $c->stash( template => $view_type . '.tt' );
}

sub by_id_PUT : Action {
    my ( $self, $c, @args ) = @_; 
    my @model_pks = $self->model_pks( $c );
    my @pks = @args[ 0 .. scalar @model_pks - 1 ];
    my $form = $self->_get_form( $c, \@pks );
    if( $form->process ){
        my $item = $form->item;
        my @new_pks = map { $item->$_ } @model_pks;
        $c->res->redirect(
            $c->uri_for( $self->action_for('by_id'), @new_pks )
        );
    }
    else{ 
        $c->stash( form => $form );
        $c->stash( template => 'edit.tt' );
    }
}


1;

__END__

=head1 NAME

Catalyst::Example::Controller::InstantCRUD::REST - Catalyst CRUD example RESTful Controller


=head1 VERSION

This document describes Catalyst::Example::Controller::InstantCRUD::REST version 0.0.1


=head1 SYNOPSIS

    use base Catalyst::Example::Controller::InstantCRUD::REST;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=head2 METHODS

=over 4

=item by_id
The main dispatch point.  

=item by_id_PUT
Updates an object (or creates one).

=item by_id_GET 
Shows object representation

=item create_form
Form for object creation.

=back

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Catalyst::Example::Controller::InstantCRUD requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-catalyst-example-controller-instantcrud@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

<Zbigniew Lukasiak>  C<< <<zz bb yy @ gmail.com>> >>
<Jonas Alves>  C<< <<jonas.alves at gmail.com>> >>
<Lars Balker Rasmussen>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, <Zbigniew Lukasiak> C<< <<zz bb yy @ gmail.com>> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
