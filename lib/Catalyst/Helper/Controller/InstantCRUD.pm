package Catalyst::Helper::Controller::InstantCRUD;

our $VERSION = '0.0.8';

use warnings;
use strict;
use Path::Class;
use Data::Dumper;
use HTML::FormHandler::Generator::DBIC;

sub mk_compclass {
    my ( $self, $helper, $schema, $m2m) = @_;
    
    my $dir = dir( $helper->{dir}, 'root' );
    $helper->mk_dir($dir);
    # controllers
    my @source_monikers = $schema->sources;
    for my $class( @source_monikers ) {
        mk_controller( $helper, $class, $schema, $m2m );
    }
}

sub mk_controller {
    my( $helper, $class, $schema, $m2m ) = @_;
    $helper->{class} = $helper->{app} . '::Controller::' . $class;
    $helper->{base_pathpart} = lc $class;
    (my $file = $helper->{file})  =~ s/InstantCRUD\.pm$/$class\.pm/;
    my $generator = HTML::FormHandler::Generator::DBIC->new( 
        schema => $schema, 
        class_prefix => $helper->{class}, 
        style => 'single', 
        m2m => $m2m,
        rs_name => $class,
    );
    $helper->{form_code} = $generator->generate_form();
    $helper->render_file( compclass => $file );
}



sub _strip_class {
    my $fullclass = shift;
    my @parts     = split /::/, $fullclass;
    my $class     = pop @parts;
    return $class;
}



1; # Magic true value required at end of module
__DATA__

=begin pod_to_ignore

__compclass__
use strict;
use warnings;

package [% class %];
[% IF rest %]
use base "Catalyst::Example::Controller::InstantCRUD::REST";
__PACKAGE__->config(
    serialize => {
        default => 'text/html',
        map => {
            'text/html'   => [ 'View', 'TT' ],
            'text/x-json' => 'JSON::Syck',
        }
    }
);
[% ELSE %]
use base "Catalyst::Example::Controller::InstantCRUD";
[% END %]

[% form_code %]

__PACKAGE__->config(
    action => {
        list => { Chained => 'base', PathPart => q{}, Args => 0 },
        view => { Chained => 'base' },
        edit => { Chained => 'base' },
        destroy => { Chained => 'base' },
    },
);

sub base : Chained('/') PathPart('[% base_pathpart %]') CaptureArgs(0) {}

1;

__END__

=head1 NAME

Catalyst::Helper::Controller::InstantCRUD - [One line description of module's purpose here]


=head1 VERSION

This document describes Catalyst::Helper::Controller::InstantCRUD version 0.0.1


=head1 SYNOPSIS

    use Catalyst::Helper::Controller::InstantCRUD;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.

=head2 METHODS

=over 4

=item mk_compclass

=item mk_controller

=back

=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


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
  
Catalyst::Helper::Controller::InstantCRUD requires no configuration files or environment variables.


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
C<bug-catalyst-helper-controller-instantcrud@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

<Zbigniew Lukasiak>  C<< <<zz bb yy @ gmail.com>> >>


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


