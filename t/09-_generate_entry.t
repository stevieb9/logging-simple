#!/usr/bin/perl
use strict;
use warnings;

use Logging::Simple;
use Test::More;

my $mod = 'Logging::Simple';

{ # bad label
    my $log = $mod->new(print => 0);
    my $ok = eval { $log->_generate_entry(label => 'bad'); 1; };
    is ($ok, undef, "croaks with bad label");
    like ($@, qr/requires a sub/, "...and error msg is ok");
}
{ # default display
    my $log = $mod->new(print => 0);
    my $msg = $log->_generate_entry(label => 'info', msg => 'test');
    like ($msg, qr/\[.*?\]\[info\] test/, "default display is correct");
}
{ # display with name param
    my $log = $mod->new(print => 0, name => $mod);
    my $msg = $log->_generate_entry(label => 'info', msg => 'test');
    like ($msg, qr/\[.*?\]\[info\]\[Logging::Simple\] test/, "display with name ok");
}
done_testing();

