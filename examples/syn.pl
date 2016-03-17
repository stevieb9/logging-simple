#!/usr/bin/perl
use strict;
use warnings;

use Log::Simple;

my $log = Log::Simple->new(name => 'whatever');

$log->warning("this shouldn't happen");
$log->_4("all levels can be called by number. This is warning()");

$log->_7("this is debug(). Default level is 4, so this won't print");

$log->level(7);
$log->debug("same as _7(). It'll print now");

$log->file('file.log');
$log->info("this will go to file");
$log->file(0); # back to STDOUT

$log->_6("info facility, example output");
#[2016-03-17 16:49:32.491][info][whatever] info facility, example output

$log->display(0);
$log->info("display(0) disables all output but this msg");
$log->info("see display() method for disabling, enabling individual tags");

$log->display(1);
$log->info("all tags enabled");
#[2016-03-17 16:52:06.356][info][whatever][5689][t/syn.pl|29] all tags enabled

$log->print(0);
my $log_entry = $log->info("print(0) disables printing and returns the entry");









