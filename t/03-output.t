#!/usr/bin/perl
use strict;
use warnings;

use Log::Simple;
#use Test::More;

my $mod = 'Log::Simple';
my $log = $mod->new;

$log->debug("this is a debug msg");

#done_testing();

