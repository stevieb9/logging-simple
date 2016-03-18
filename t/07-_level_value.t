#!/usr/bin/perl
use strict;
use warnings;

use Logging::Simple;
use Test::More;

my $mod = 'Logging::Simple';

{
    my $log = $mod->new;

    my %levels = $log->levels;
    my %rev = reverse $log->levels;

    my $subs = $log->_sub_names;

    for my $sub (@$subs){
        my $level_int = $log->_level_value($sub);

        if ($sub =~ /^_(\d)$/){
            my $name = $levels{$1};
            is ($levels{$level_int}, $name, "numbered sub $sub has $name");
        }
        else {
            my ($name) = grep /^$sub/, keys %rev;
            is ($levels{$level_int}, $name, "named sub $sub has $name");
        }
    }
}

done_testing();

