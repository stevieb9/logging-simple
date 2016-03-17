package One;
#!/usr/bin/perl
use strict;
use warnings;

use Log::Simple;

run();

sub run {
    my $log = Log::Simple->new( print => 0, display => 0, level => 7 );
    $log->display( proc => 1 );

    my $msg = $log->info( 'test' );

    print $msg;
}
1;
