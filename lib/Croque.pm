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

Croque - Batch Kicker

=head1 SYNOPSIS

  use Croque;
  
  my $c = croque {
      boot { 
          my $process = shift;
          $process->redirect_output( '/tmp/stdout.log', '/tmp/stderr.log' );
          return '/path/to/batch.sh' 
      } at { qr/ (10|16):00:00$/ };
      
      down {
          my $process = shift;
          warn "process-id=". $process->pid . " will be killed.";
      } at { qr/ (10|16):30:00$/ };
  };
  
  $c->work; # loop

=head1 DESCRIPTION

Croque is a Batch Kicker. It has following features.

=over 4

=item Kicking a batch as scheduled.

=item Killing a batch-process as scheduled.

=back

=head1 WHY NOT CRON?

CRON can kick a batch as scheduled. And, it can kill batch-process as scheduled.

But, killing a batch-process with specified process-id is bit difficult (If batch not create pid-file).

=head1 COMMAND-LINE INTERFACE

=head1 EXPORTED METHODS

=head2 croque

Setup Croque object.

  my $croque_object = croque {
      ### croque setup code here ###
  };
  # or
  $croque_object = croque { ... } { oneshot => 1 };

1st argument is coderef that contains setting-up logic for kicking a batch. See SYNOPSIS.

2nd optional argument is hashref for specify some options. As options, following parameter may be specified.

=over 4

=item oneshot ( bool )

Break loop of work() when killing a batch-process if this parameter is defined.

See work method.

=back

=head2 at

Schedule specifier.

  my $coderef = at { qr/ 10:20:00$/ };
  # or
  $coderef = at { qr/^00$/ }, '%S';

1st argument is coderef that returns regexpref for matching current localtime.

2nd optional argument is string. This is a format of Time::Piece::strptime().

and, "at" returns coderef for matching current localtime.

  while( 1 ) {
      last if $coderef->();
      sleep 1;
  }
  say "matched!";

=head2 boot

Specifier for kicking a batch.

  boot {
      my $proc = shift;
      $proc->redirect_output( '/path/to/stdout', '/path/to/stderr' );
      return './my-batch.sh';
  } at { qr/:00$/ };

1st argument is coderef that returns command for kicking a batch as string/array. $proc is a object of Proc::Simple.

2nd argument is schedule specifier. See "at" method.

=head2 down

Specifier for killing a batch-process.

  down {} at { qr/:30$/ };
  # or
  down {
      my $proc = shift;
      warn sprintf( "pid %d was killed.", $proc->pid );
  } at { qr/:30$/ };

1st argument is coderef that is kicked *BEFORE* killing a batch-process.

=head1 OBJECT METHOD

=head2 work

Entering loop for waiting for kicking batch.

=head1 AUTHOR

ytnobody E<lt>ytnobody at gmail dot comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
