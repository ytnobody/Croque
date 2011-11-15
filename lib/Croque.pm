package Croque;
use strict;
use warnings;
use Exporter 'import';
use Proc::Simple;
use Time::HiRes qw( sleep );
use Time::Piece;
use Guard;

our $VERSION = '0.01';
our $CROQUE;
our @EXPORT = qw/ croque at boot down /;

sub croque (&;$) {
    my ( $code, $args ) = @_;
    $args ||= {};
    local $CROQUE = bless $args, __PACKAGE__;
    $code->();
    return $CROQUE;
}

sub at (&;$) {
    my ( $matchcode, $format ) = @_;
    $format ||= '%Y-%m-%d %H:%M:%S';
    return sub {
        my $t = shift || localtime->strftime( $format );
        return 1 if $t =~ $matchcode->();
    };
}

sub boot (&;@) {
    my ( $cmd, $at ) = @_;
    $CROQUE->{boot} = {
        code => sub { 
            my $croque = shift;
            my $proc = Proc::Simple->new;
            $proc->start( $cmd->( $proc ) ); 
            $croque->{proc} = {
                proc => $proc,
                guard => guard { $proc->kill if $proc->poll },
            };
        },
        at => $at,
    };
}

sub down (;&@) {
    my $code = scalar @_ > 1 ? $_[0] : sub {} ;
    my $at = scalar @_ > 1 ? $_[1] : $_[0] ;
    $CROQUE->{down} = {
        code => sub { 
            my $croque = shift;
            $code->( $croque->{proc}->{proc} );
            delete $croque->{proc};
            $croque->{finish} = 1 if $croque->{oneshot};
        },
        at => $at,
    };
}

sub work {
    my ( $self ) = @_;
    while ( ! $self->{finish} ) {
        sleep 0.1;
        if ( $self->{proc} && $self->{down} ) {
            $self->{down}->{code}->( $self ) if $self->{down}->{at}->();
        }
        elsif ( $self->{boot} && !$self->{proc} ) {
            $self->{boot}->{code}->( $self ) if $self->{boot}->{at}->();
        }
    }
}

1;
__END__

=head1 NAME

Croque - 

=head1 SYNOPSIS

  use Croque;

=head1 DESCRIPTION

Croque is

=head1 AUTHOR

azuma E<lt>azuma@livedoor.jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
