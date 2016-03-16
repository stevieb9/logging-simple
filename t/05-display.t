use strict;
use warnings;

use Data::Dumper;
use Log::Simple;
use Test::More;

{ # entire list
    my $log = Log::Simple->new;

    my %h = $log->display;
    is (keys %h, 4, "display() with no params returns the correct hash");

    for (qw(pid label time proc)){
        if ($_ eq 'proc' || $_ eq 'pid'){
            is ($h{$_}, 0, "$_ defaults to disabled");
        }
        else {
            is ($h{$_}, 1, "$_ defaults to enabled");
        }
    }
}
{ # all
    my $log = Log::Simple->new;
    is ($log->display('all'), 1, "display() returns true with 'all' param");
}
{ # get single
    my $log = Log::Simple->new;

    my %ret = $log->display(pid => 0, label => 0, time => 0, proc => 0);

    for (qw(pid label time proc)){
        is ($log->display($_), 0, "disabling $_ tag works");
        is ($ret{$_}, 0, "and full return works for $_");
        $log->display($_ => 1);
        is ($log->display($_), 1, "so does re-enabling $_");
    }
}
{ # invalid display tag
    my $log = Log::Simple->new;

    my $warn;
    local $SIG{__WARN__} = sub { $warn = shift; };

    my $ret = $log->display(blah => 1);
    like ($warn, qr/blah is an invalid tag/, "invalid tags get squashed");
}
done_testing();
