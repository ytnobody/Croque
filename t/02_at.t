use strict;
use Test::More;
use Croque;

isa_ok( at { qr/0$/ }, 'CODE');

my $at = at { qr/30$/ } '%S';
isa_ok( $at, 'CODE' );

my $res = $at->( '30' );
ok $res eq 1, "'30' is expected to match. but, got \n". explain $res;

$res = $at->( '31' );
ok $res eq undef, "'31' is not expected to match. but, got \n". explain $res;

$res = $at->();
ok $res eq undef || $res eq 1, "return-value is expected as undef or 1. but got \n". explain $res;

done_testing;
