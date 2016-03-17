#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Log::Simple;
use Test::More;

my @labels = qw(emergency alert critical error warning notice info debug);
my @short = qw(emerg crit err warn);
my @nums = qw(_0 _1 _2 _3 _4 _5 _6 _7);

{ # test named methods
    my $log = Log::Simple->new(print => 0);

    my @msgs;

    for (@labels){
        my $msg = $log->$_($_);
        if ($msg) {
            like ( $msg, qr/\[$_\] $_/, "$_ has proper msg" );
        }
        push @msgs, $msg if $msg;
    }

    is (@msgs, 5, "with default level, long names has ok msg count");
}
{ # test short methods
    my $log = Log::Simple->new(print => 0);

    my @msgs;

    for (@short){
        my $msg = $log->$_($_);
        if ($msg) {
            like ( $msg, qr/\[$_\] $_/, "$_ has proper msg" );
        }
        push @msgs, $msg if $msg;
    }

    is (@msgs, 4, "with default level, short names has proper msg count");
}
{ # test num methods
    my $log = Log::Simple->new(print => 0);

    my @msgs;

    for (@nums){
        /^_(\d)$/;
        my $msg = $log->$_($_);
        if ($msg) {
            like ( $msg, qr/\[$_\] $_/, "$_ has proper msg" );
        }
        push @msgs, $msg if $msg;
    }

    is (@msgs, 5, "with default level, short names has proper msg count");
}

done_testing();

