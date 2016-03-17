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
my @labels = qw(emergency alert critical error warning notice info debug);
my @short = qw(emerg crit err warn);

can_ok($mod, 'emergency');
can_ok($mod, 'emerg');
can_ok($mod, 'critical');
can_ok($mod, 'crit');
can_ok($mod, 'alert');
can_ok($mod, 'error');
can_ok($mod, 'err');
can_ok($mod, 'warning');
can_ok($mod, 'warn');
can_ok($mod, 'notice');
can_ok($mod, 'info');
can_ok($mod, 'debug');

for (qw(_0 _1 _2 _3 _4 _5 _6 _7)){
    can_ok($mod, $_);
}

done_testing();


