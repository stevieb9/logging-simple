#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Log::Simple;
use Test::More;

my @labels = qw(emergency alert critical error warning notice info debug);
my @short = qw(emerg crit err warn);

{ # test log methods

    my $log = Log::Simple->new(print => 0);

    my @msgs;

    for (@labels){
        my $msg = $log->$_($_);
        push @msgs, $msg if $msg;
    }

    is (@msgs, 5, "with default level, we get proper msg count");

}
done_testing();

