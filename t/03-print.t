#!/usr/bin/perl
use strict;
use warnings;

use File::Temp;
use Log::Simple;
use Test::More;

{ # set/get
    my $log = Log::Simple->new;

    is ($log->print, 1, "printing is enabled by default");
    $log->print(0);
    is ($log->print, 0, "printing can be disabled");
    $log->print(1);
    is ($log->print, 1, "...and enabled again");
}
{ # print vs return
    my $log = Log::Simple->new;

    my $fn = _fname();
    $log->file($fn);

    $log->_generate_entry('debug', 'testing print');
    $log->file(0);

    open my $fh, '<', $fn or die $!;
    like (<$fh>, qr/debug.*testing print/, "print(1) prints log entry");
    close $fh;

    $log->print(0);

    my $msg = $log->_generate_entry('debug', 'no print');
    like ($msg, qr/debug.*no print/, "print(0) returns with no print");
}

sub _fname {
    my $fh = File::Temp->new(UNLINK => 1);
    my $fn = $fh->filename;
    close $fh;
    return $fn;
}
done_testing();

