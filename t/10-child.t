#!/usr/bin/perl
use strict;
use warnings;

use File::Temp;
use Log::Simple;
use Test::More;

my $mod = 'Log::Simple';

my $fn = 't/working/append.log';
my $parent = 't/working/parent.log';
my $f1 = 't/working/one.log';
my $f2 = 't/working/two.log';
my $f3 = 't/working/three.log';
my $f4 = 't/working/four.log';

{ # append file
    my $log = $mod->new(
        file       => $fn,
        write_mode => 'a',
        name       =>
        'parent',
        level      => 7
    );
    $log->display(time => 0);
    $log->info( 'in parent main' );

    run();
    run();

    sub run {
        one( 'blah' );
        four( 'crap' );
        three( 'died' );
        three( 'whoops' );
        two( 'two' );
        two( 'xxx' );
        three( 'asdfas' );
        one( 'vbqewqrq' );
    }
    sub one {
        my $log = $log->child( 'one' );
        my $x = shift;
        $log->info( $x );
    }
    sub two {
        my $log = $log->child( 'two' );
        my $x = shift;
        $log->info( $x );
        $log->debug( $x );
    }
    sub three {
        my $log = $log->child( 'three' );
        $log->info( shift );
        $log->emerg( shift );
    }
    sub four {
        my $log = $log->child( 'four' );
        $log->info( shift );
        $log->_2( shift );
    }
}
{ # individual files

    my $log = $mod->new(
        file       => $parent,
        write_mode => 'a',
        name       =>
        'parent',
        level      => 7
    );
    $log->display(time => 0);
    $log->info( 'in parent main' );

    run1();

    sub run1 {
        one1( 'blah' );
        four1( 'crap' );
        three1( 'died' );
        three1( 'whoops' );
        two1( 'two' );
        two1( 'xxx' );
        three1( 'asdfas' );
        one1( 'vbqewqrq' );
    }
    sub one1 {
        my $log = $log->child( 'one' );
        $log->file($f1);
        my $x = shift;
        $log->info( $x );
    }
    sub two1 {
        my $log = $log->child( 'two' );
        $log->file($f2);
        my $x = shift;
        $log->info( $x );
        $log->debug( $x );
    }
    sub three1 {
        my $log = $log->child( 'three' );
        $log->file($f3);
        $log->info( shift );
        $log->emerg( shift );
    }
    sub four1 {
        my $log = $log->child( 'four' );
        $log->file($f4);
        $log->info( shift );
        $log->_2( shift );
    }
}
done_testing();
