#!/usr/bin/perl
use strict;
use warnings;

use Log::Simple;
use Test::More;

my $mod = 'Log::Simple';
my $log = $mod->new(print => 0);

{ # bad label
    my $ok = eval { $log->_generate_entry(label => 'bad'); 1; };
    is ($ok, undef, "croaks with bad label");
    like ($@, qr/requires a sub/, "...and error msg is ok");
}
{ # default display
    my $msg = $log->_generate_entry(label => 'info', msg => 'test');
    like ($msg, qr/\[.*?\]\[info\]\[Log::Simple\] test/, "default display is correct");
}
done_testing();

