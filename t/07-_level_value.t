#!/usr/bin/perl
use strict;
use warnings;

use Log::Simple;
use Test::More;

my $mod = 'Log::Simple';

{
    my $log = $mod->new;

    my %labels = $log->labels;
    my %rev = reverse $log->labels;

    my $subs = $log->_sub_names;

    for my $sub (@$subs){
        my $level_int = $log->_level_value($sub);

        if ($sub =~ /^_(\d)$/){
            my $name = $labels{$1};
            is ($labels{$level_int}, $name, "numbered sub $sub has $name");
        }
        else {
            my ($name) = grep /^$sub/, keys %rev;
            is ($labels{$level_int}, $name, "named sub $sub has $name");
        }
    }
}

done_testing();

