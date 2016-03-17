#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use File::Temp;
use Log::Simple;

my $mod = 'Log::Simple';
my $fn = _fn();

my $log = $mod->new(name => 'parent', level => 7, print => 1);
#my $log = $mod->new(file => $fn, name => 'parent', level => 7, print => 1);

$log->info('in parent main');

one('blah');
four('crap');
three('died');
three('whoops');
two('two');
two('xxx');
three('asdfas');
one('vbqewqrq');

#dump_log();

sub one {
    my $log = $log->child('one');
    $log->info(shift);
}
sub two {
    my $log = $log->child('two');
    $log->info(shift);
}
sub three {
    my $log = $log->child('three');
    $log->info(shift);
}
sub four {
    my $log = $log->child('four');
    $log->info(shift);
}
sub dump_log {
    $log->file(0);
    open my $fh, '<', $fn or die $!;
    print $_ for <$fh>;
}
sub _fn {
    my $fh = File::Temp->new(UNLINK => 1);
    my $fn = $fh->filename;
    close $fh;
    return $fn;
}
