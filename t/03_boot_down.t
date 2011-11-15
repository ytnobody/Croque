use strict;
use Test::More;
use Croque;
use File::Spec;
use File::Slurp;

my $stdout = File::Spec->catfile( qw/ t std.out / );
my $stderr = File::Spec->catfile( qw/ t std.err / );

my $time = time;

my $c = croque {
    boot {
        my $proc = shift;
        $proc->redirect_output( $stdout, $stderr );
        return "echo $time";
    } at { qr/(1|4|7)$/ };

    down { 
        diag "THANK YOU FOR WAITING.";
    } at { qr/(3|6|9)$/ };
} { oneshot => 1 };

isa_ok $c, 'Croque';
isa_ok $c->{boot}, 'HASH';
isa_ok $c->{boot}->{code}, 'CODE';
isa_ok $c->{boot}->{at}, 'CODE';
is $c->{oneshot}, 1, "oneshot was expected as 1, but got \n". explain $c->{oneshot};

diag 'PLEASE CTRL+C WHEN WAITING LONG TIME (over 60sec.)...';
$c->work;

my $out = read_file( $stdout );
is $out, "$time\n";

$out = read_file( $stderr );
is $out, "";

done_testing;
