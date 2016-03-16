#!/usr/bin/perl
use strict;
use warnings;

use File::Temp;
use Test::More;

my $mod = 'Log::Simple';
use_ok($mod);

{ # obj is in correct class
    my $log = $mod->new;
    is (ref $log, $mod, "obj is in the right class");
}
{ # new() and defaults
    my $log = $mod->new;

    is (exists $log->{level}, 1, "level attr exists");
    is ($log->{level}, 4, "default level is ok");
    is (exists $log->{file}, 1, "the file attr exists");
    is ($log->{file}, '', "no file is set by default");
}
{ # new() with level (num)
    my $i = 0;
    for(0..7) {
        my $log = $mod->new(level => $_);
        is ( $log->{level}, $i, "int level $_ is set to $i correctly" );
        $i++;
    }
}
{ # new() with level (str)
    my $i = 0;
    for(qw(emer alert crit err warn notice info debug)) {
        my $log = $mod->new(level => $_);
        is ( $log->{level}, $i, "str level $_ is set to $i correctly" );
        $i++;
    }
}
{ # new() with file
    my $fh = File::Temp->new(UNLINK => 1);
    my $fname = $fh->filename;
    close $fh;

    my $log = $mod->new(file => $fname);

    is ($log->{file}, $fname, "filename is set ok");
    is (ref $log->{fh}, 'GLOB', "a file handle is created ok");
    close $log->{fh};
}
done_testing();

