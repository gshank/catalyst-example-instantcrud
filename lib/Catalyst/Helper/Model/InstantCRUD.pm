package Catalyst::Helper::Model::InstantCRUD;

our $VERSION = '0.03';

use warnings;
use strict;
use Carp;
use Path::Class;
use Catalyst::Example::InstantCRUD::Utils;
use Data::Dumper;

sub mk_compclass {
    my ( $self, $helper, $schema, $dsn, $user, $password, $options, $attrs ) =
      @_;

    my $schemaclass = $helper->{app} . "::$schema";
    # Create the DBIC Schema Model
    $helper->mk_component( $helper->{app}, 'model', $helper->{name},
        'DBIC::Schema', $schemaclass, $dsn, $user, $password );

    $attrs ||= Catalyst::Example::InstantCRUD::Utils->load_schema(
        dsn      => $dsn,
        user     => $user,
        password => $password
    );

    my $schemadir = file( $helper->{file} )->parent->parent->subdir($schema);


    $helper->mk_dir( $schemadir );

    # Schema classes
    $helper->{schema} = $schemaclass;
    my @classes;
    for my $table ( keys %{ $attrs->{tables} } ) {
        $helper->{package}         = $helper->{app} . "::" . $attrs->{tables}{$table}{c};
        $helper->{class}         = $attrs->{tables}{$table}{c};
        $helper->{relationships} = $attrs->{rels}{ $helper->{class} };

        #my %elements = map { $_ => 1 } @{$attrs->{elems}{$helper->{class}}};
        my %elements = map { $_ => 1 } @{ $attrs->{tables}{$table}{qw/cols/} },
          @{ $attrs->{tables}{$table}{qw/relationships/} };
        $helper->{elements} = join ' ', keys %elements;
        $helper->{pks}      = join ' ', @{ $attrs->{tables}{$table}{pks} };
        $helper->{overload_method} = $attrs->{tables}{$table}{overload_method};
        $helper->{columns}         = $attrs->{tables}{$table}{columns};
        $helper->{table}           = $table;
        my $source = $attrs->{tables}{$table}{source};
        push @classes, $source;
        my $file = dir( $schemadir, "$source.pm" );
        $helper->render_file( schemaclass => $file );
    }

    # Schema base class
    my $file = dir( $schemadir, 'base.pm' );
    $helper->render_file( baseclass => $file );

    # Schema class
    $helper->{classes} = join ' ', @classes;
    $file = $schemadir . ".pm";
    $helper->render_file( schema => $file );

    return 1;
}

# No test file
sub mk_comptest { }

1;
__DATA__

=begin pod_to_ignore

__schemaclass__
package [% package %];

use strict;
use warnings;
use base qw/[% schema %]::base/;
# Stringifies to the first primary key.
# Change it to what makes more sense.
# Is that value that appears in HTML Select's and things like that.
[% IF overload_method %]use overload '""' => sub {$_[0]->[% overload_method %]}, fallback => 1;[% END %]

__PACKAGE__->table('[% table %]');
__PACKAGE__->add_columns(qw/[% FOR col = columns; col; ' '; END %]/);
__PACKAGE__->set_primary_key(qw/[% pks %]/);
[% relationships %]
1;
__baseclass__
package [% schema %]::base;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/DigestColumns Core/);
#__PACKAGE__->load_components(qw/InstantCRUD DigestColumns InflateColumn::DateTime Core/);

1;
__schema__
package [% schema %];
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw/[% classes %]/);

1;
__END__

=head1 NAME

Catalyst::Helper::Model::InstantCRUD


=head1 VERSION

This document describes Catalyst::Helper::Model::InstantCRUD 

=head1 SYNOPSIS

    use Catalyst::Helper::Controller::InstantCRUD;

  
=head1 DESCRIPTION

=head2 METHODS

=over 4

=item mk_compclass

=item mk_comptest

=back

=head1 INTERFACE 

=head1 DIAGNOSTICS

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back

=head1 AUTHOR

<Jonas Alves>  C<< <<jonas.alves @ gmail.com>> >>

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
