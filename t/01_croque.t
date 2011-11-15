use strict;
use Test::More;
use Croque;

isa_ok croque { }, 'Croque';
can_ok croque { }, qw/ work /;

done_testing;
