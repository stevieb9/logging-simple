use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Log::Simple') };

my $mod = 'Log::Simple';

can_ok($mod, 'new');
can_ok($mod, 'file');
can_ok($mod, 'level');
can_ok($mod, 'labels');
can_ok($mod, 'display');

done_testing();


