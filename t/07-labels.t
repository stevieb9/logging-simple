#!/usr/bin/perl
use strict;
use warnings;

use File::Temp;
use Logging::Simple;
use Test::More;

my $mod = 'Logging::Simple';

{ # default labels
    my $log = $mod->new;

    my %default = _default_labels();
    my %labels = $log->levels;

    for (0..7){
        is ($labels{$_}, $default{$_}, "default labels ok");
    }

    my @custom = qw(zero one two three four five six seven);
    $log->labels(\@custom);

    %labels = $log->levels;

    use Data::Dumper;
    print Dumper \%labels;
}

sub _default_labels {
    return (
        0 => 'lvl 0',
        1 => 'lvl 1',
        2 => 'lvl 2',
        3 => 'lvl 3',
        4 => 'lvl 4',
        5 => 'lvl 5',
        6 => 'lvl 6',
        7 => 'lvl 7',
    );
}

done_testing();
