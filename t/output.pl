#!/usr/bin/perl
use strict;
use warnings;

use Log::Simple;

my $mod = 'Log::Simple';
my $log = $mod->new;

$log->debug("this is a debug msg");


