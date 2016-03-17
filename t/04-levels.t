#!/usr/bin/perl
use strict;
use warnings;

use Log::Simple;
use Test::More;

my $mod = 'Log::Simple';

{
    my $log = $mod->new;

    my @names = $log->levels( 'names' );

    is ( @names, 8, "levels() returns correct count with 'names' param" );

    my %levels = (
        0 => 'emergency',
        1 => 'alert',
        2 => 'critical',
        3 => 'error',
        4 => 'warning',
        5 => 'notice',
        6 => 'info',
        7 => 'debug',
    );

    for (0..7){
        is (
            $names[$_],
            $levels{$_},
            "levels() with 'names' param maps $_ to $levels{$_} ok");
    }

    my %tags = $log->levels;

    is (ref \%tags, 'HASH', "levels() returns a hash");

    for (0..7){
        is ($tags{$_}, $levels{$_}, "return from levels() is sane");
    }

    is (keys %tags, 8, "levels() return has proper key count");
}
{ # level invalid warning
    my $warn;
    local $SIG{__WARN__} = sub { $warn = shift; };

    my $log = $mod->new;

    my $lvl = $log->level('xxx');

    like ($warn, qr/invalid level/, "an invalid level spits a warning");
    is ($lvl, 4, "...and the default level is set");
}

done_testing();

