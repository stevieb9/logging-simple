#!/usr/bin/perl
use strict;
use warnings;

use Log::Simple;
use Test::More;


my @labels = qw(emergency alert critical error warning notice info debug);
my @short = qw(emerg crit err warn);
my @nums = qw(_0 _1 _2 _3 _4 _5 _6 _7);

my @all;

push @all, @labels, @short, @nums;

my $log = Log::Simple->new;

my $subs = $log->_sub_names;

is (ref $subs, 'ARRAY', "_sub_names() returns an aref");
is (@$subs, @all, "count of sub names is ok");

my $i = 0;
for (@$subs){
    is ($_, $all[$i], "sub $_ matches $all[$i] ok");
    $i++;
}

done_testing();

