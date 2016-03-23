package Logging::Simple;
use 5.007;
use strict;
use warnings;

use Carp qw(croak confess);
use POSIX qw(strftime);
use Time::HiRes qw(time);

our $VERSION = '0.10';

BEGIN {

    sub _sub_names {
        my @levels = qw(
            emergency alert critical
            error warning notice info debug
        );
        my @short = qw(emerg crit err warn);
        my @nums = qw(_0 _1 _2 _3 _4 _5 _6 _7);

        my @all;
        push @all, @levels, @short, @nums;

        return \@all;
    }

    my $sub_names = _sub_names();

    {
        no strict 'refs';

        for (@$sub_names) {
            my $sub = $_;

            *$_ = sub {
                my ($self, $msg) = @_;

                return if $self->level == -1;

                $self->level($ENV{LS_LEVEL}) if defined $ENV{LS_LEVEL};

                if ($sub =~ /^_(\d)$/){
                    if (defined $self->_log_only){
                        return if $1 != $self->_log_only;
                    }
                    return if $1 > $self->level;
                }
                if (defined $self->_log_only){
                    return if $self->_level_value($sub) != $self->_log_only;
                }

                return if $self->_level_value($sub) > $self->level;

                my $proc = join '|', (caller(0))[1..2];

                my %log_entry = (
                    label => $sub,
                    proc => $proc,
                    msg => $msg,
                );

                $self->_generate_entry(%log_entry);
            }
        }
    }
}
sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    if (defined $args{level}) {
        $self->level($args{level});
    }
    else {
        my $lvl = defined $ENV{LS_LEVEL} ? $ENV{LS_LEVEL} : 4;
        $self->level($lvl);
    }

    if ($args{file}){
        $self->file($args{file}, $args{write_mode});
    }

    my $print = defined $args{print} ? $args{print} : 1;
    $self->print($print);

    $self->display(
            time  => 1,
            label => 1,
            name  => 1,
            pid   => 0,
            proc  => 0,
    );

    if (defined $args{display}){
        $self->display($args{display});
    }

    $self->name($args{name});

    return $self;
}
sub level {
    my ($self, $level) = @_;

    my %levels = $self->levels;
    my %rev = reverse %levels;

    $self->{level} = $ENV{LS_LEVEL} if defined $ENV{LS_LEVEL};
    my $lvl;

    if (defined $level && $level =~ /^-1$/){
        $self->{level} = $level;
    }
    elsif (defined $level){

        my $log_only;

        if ($level =~ /^=/){
            $level =~ s/=//;
            $log_only = 1;
        }
        if ($level =~ /^\d$/ && defined $levels{$level}){
            $self->{level} = $level;
        }
        elsif ($level =~ /^\w{3}/ && defined($lvl = $self->_translate($level))){
            $self->{level} = $lvl;
        }
        else {
            CORE::warn
                "invalid level $level specified, using default 'warning'/4\n";
        }

        if ($log_only){
            $self->_log_only($self->{level});
        }
        else {
            $self->_log_only(-1);
        }
    }

    return $self->{level};
}
sub file {
    my ($self, $file, $mode) = @_;

    if (! defined $file){
        return $self->{file};
    }
    if ($file =~ /^0$/){
        if (tell($self->{fh}) != -1) {
            close $self->{fh};
        }
        delete $self->{file};
        delete $self->{fh};
        return;
    }
    if (defined $file && $self->{file} && $file ne $self->{file}){
        close $self->{fh};
    }
    $mode = 'a' if ! defined $mode;
    my $op = $mode =~ /^a/ ? '>>' : '>';

    open $self->{fh}, $op, $file or die "can't open log file for writing: $!";
    $self->{file} = $file;

    return $self->{file};
}
sub name {
    my ($self, $name) = @_;
    $self->{name} = $name if defined $name;
    return $self->{name};
}
sub timestamp {
	my $t = time;
    my $date = strftime "%Y-%m-%d %H:%M:%S", localtime $t;
    $date .= sprintf ".%03d", ($t-int($t))*1000; # without rounding
    return $date;
}
sub levels {
    my ($self, $want) = @_;

    my %levels = (
        0 => 'emergency',
        1 => 'alert',
        2 => 'critical',
        3 => 'error',
        4 => 'warning',
        5 => 'notice',
        6 => 'info',
        7 => 'debug',
    );

    if (defined $want && $want eq 'names'){
        my @level_list;
        for (0..7){
            push @level_list, $levels{$_};
        }
        return @level_list;
    }

    return %levels;
}
sub display {
    my $self = shift;
    my ($tag, %tags);

    if (@_ == 1){
        $tag = shift;
    }
    else {
        %tags = @_;
    }

    if (defined $tag){
        if ($tag =~ /^0$/){
            for (keys %{ $self->{display} }){
                $self->{display}{$_} = 0;
            }
            return 0;
        }
        if ($tag =~ /^1$/){
            for (keys %{ $self->{display} }){
                $self->{display}{$_} = 1;
            }
            return 1;
        }

        return $self->{display}{$tag};
    }

    my %valid = (
        name => 0,
        time => 0,
        label => 0,
        pid => 0,
        proc => 0,
    );

    for (keys %tags) {
        if (! defined $valid{$_}){
            CORE::warn "$_ is an invalid tag...skipping\n";
            next;
        }
        $self->{display}{$_} = $tags{$_};
    }


    return %{ $self->{display} };
}
sub print {
    $_[0]->{print} = $_[1] if defined $_[1];
    return $_[0]->{print};
}
sub child {
    my ($self, $name) = @_;
    my $child = bless { %$self }, ref $self;
    $name = $self->name . ".$name" if defined $self->name;
    $child->name($name);
    return $child;
}
sub custom_display {
    my ($self, $disp) = @_;

    if (defined $disp) {
        if ($disp =~ /^0$/) {
            delete $self->{custom_display};
            return 0;
        }
        else {
            $self->{custom_display} = $disp;
        }
    }
    return $self->{custom_display};
}
sub fatal {
    my ($self, $msg) = @_;

    $self->display(1);
    confess("\n" . $self->_0("$msg"));
}
sub _level_value {
    my ($self, $level) = @_;

    if ($level =~ /^_(\d)$/){
        return $1;
    }
    else {
        return $self->_translate($level);
    }
}
sub _translate {
    my ($self, $label) = @_;

    my %levels = $self->levels;

    if ($label =~ /^_?(\d)$/){
        return $levels{$1};
    }
    else {
        my %rev = reverse %levels;
        my ($lvl) = grep /^$label/, keys %rev;
        return $rev{$lvl};
    }
}
sub _generate_entry {
    my $self = shift;
    my %entry = @_;

    my $label = $entry{label};
    my $proc = $entry{proc};
    my $msg = $entry{msg};

    my $subs = $self->_sub_names;
    if (! grep { $label eq $_ } @$subs){
        croak "_generate_entry() requires a sub/label name as its first param\n";
    }

    if ($label =~ /^_(\d)$/){
        $label = $self->_translate($1);
    }

    $msg = $msg ? "$msg\n" : "\n";

    my $log_entry;
    $log_entry .= $self->custom_display if defined $self->custom_display;
    $log_entry .= "[".$self->timestamp()."]" if $self->display('time');
    $log_entry .= "[$label]" if $self->display('label');
    $log_entry .= "[".$self->name."]" if $self->display('name') && $self->name;
    $log_entry .= "[$$]" if $self->display('pid');
    $log_entry .= "[$proc]" if $self->display('proc');
    $log_entry .= " " if $log_entry;
    $log_entry .= $msg;

    return $log_entry if ! $self->print;

    if ($self->{fh}){
        print { $self->{fh} } $log_entry;
    }
    else {
        print $log_entry;
    }
}
sub _log_only {
    my ($self, $level) = @_;
    if (defined $level && $level == -1){
        $self->{log_only} = undef;
    }
    else {
        $self->{log_only} = $level if defined $level;
    }
    return $self->{log_only};
}

1;
__END__

=head1 NAME

Logging::Simple - A simple but flexible logging mechanism.

=for html
<a href="http://travis-ci.org/stevieb9/p5-logging-simple"><img src="https://secure.travis-ci.org/stevieb9/p5-logging-simple.png"/>
<a href='https://coveralls.io/github/stevieb9/p5-logging-simple?branch=master'><img src='https://coveralls.io/repos/stevieb9/p5-logging-simple/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Logging::Simple;

    my $log = Logging::Simple->new(name => 'whatever'); # name is optional

    $log->warning("default level (4)");

    $log->_4("all levels can be called by number. This is warning()");

    $log->_7("this is debug(). Default level is 4, so this won't print");

    $log->level(7);

    $log->debug("same as _7(). It'll print now");

    $log->level('=3');
    $log->_3("with a prepending '=' on level, we'll log this level ONLY");

    $log->fatal("log a message along with confess() output, and terminate");

    $log->level(-1); # disables all levels from doing anything

    $log->file('file.log');
    $log->info("this will go to file");
    $log->file(0); # back to STDOUT

    $log->_6("info facility, example output");
    #[2016-03-17 16:49:32.491][info][whatever] info facility, example output

    $log->display(0);
    $log->info("display(0) disables all output but this msg");
    $log->info("see display() method for disabling, enabling individual tags");

    $log->display(1);
    $log->info("all tags enabled");
    #[2016-03-17 16:52:06.356][info][whatever][5689][t/syn.pl|29] all tags enabled

    $log->print(0);
    my $log_entry = $log->info("print(0) disables printing and returns the entry");


=head1 DESCRIPTION

Lightweight (core-only) and very simple yet flexible debug tool for printing or
writing to file log type entries based on a configurable level (0-7).

It provides the ability to programmatically change which output tags to display,
provides numbered methods so you don't have to remember the name to number
level translation, provides the ability to create descendent children, easily
enable/disable file output, levels, display etc.

=head2 Logging entry format

By default, log entries appear as such, with a timestamp, the name of the
facility, the name (if specified in the constructor) and finally the actual
log entry message.

    [2016-03-17 17:01:21.959][info][whatever] info facility, example output

All of the above tags can be enabled/disabled programatically at any time, and
there are others that are not enabled by default. See L<display> method for
details.

=head2 Levels

Verbosity levels and associated named equivalents:

=over 4

=item   -1, disables all levels

=item   0, 'emergency|emerg'

=item   1, 'alert'

=item   2, 'critical|crit'

=item   3, 'error|err'

=item   4, 'warning|warn'

=item   5, 'notice'

=item   6, 'info'

=item   7, 'debug'

=back

Note that all named level methods have an associated _N method, so you don't
have to remember the names at all. Using the numbers is often much easier.

Setting the C<level> will display all messages related to that level and below.

=head1 INITIALIZATION METHODS

=head2 new(%args)

Builds and returns a new C<Logging::Simple> object. All arguments are optional, and
they can all be set using accessor methods after instantiation. These params
are:

    name        => $str  # optional, default is undef
    level       => $num  # default 4, options, 0..7, -1 to disable all
    file        => $str  # optional, default undef, send in a filename
    write_mode  => $str  # defaults to append, other option is 'write'
    print       => $bool # default on, enable/disable output and return instead
    display     => $bool # default on, enable/disable log message tags

Each of the above parameters have associated methods described below with more
details.

=head2 level($num)

Set and return the facility level. Will return the current value with a param
sent in or not. It can be changed at any time. Note that you can set this with
the C<LS_LEVEL> environment variable, at any time. the next method call
regardless of what it is will set it appropriately.

=head2 file('file.log', 'mode')

By default, we write to STDOUT. Send in the name of a file to write there
instead. Mode is optional; we'll append to the file by default. Send in 'w' or
'write' to overwrite the file.

=head2 display(%hash|$bool)

List of log entry tags, and default printing status:

    name  => 1, # specified in new() or name()
    time  => 1, # timestamp
    label => 1, # the string value of the level being called
    pid   => 0, # process ID
    proc  => 0, # "filename|line number" of the caller

In hash param mode, send in any or all of the tags with 1 (enable) or 0
(disable).

You can also send in 1 to enable all of the tags, or 0 to disable them all.

=head2 custom_display($str|$false)

This will create a custom tag in your output, and place it at the first column
of the output. Send in 0 (false) to disable/clear it.

=head2 print($bool)

Default is enabled. If disabled, we won't print at all, and instead, return the
log entry as a scalar string value.

=head2 child($name)

This method will create a clone of the existing C<Logging::Simple> object, and
then concatenate the parent's name with the optional name sent in here for easy
identification in the logs.

All settings employed by the parent will be used in the child, unless explicity
changed via the methods.

In a module or project, you can create a top-level log object, then in all
subs, create a child with the sub's name to easily identify flow within the
log. In an OO project, stuff the parent log into the main object, and clone it
from there.

=head1 LOGGING METHODS

=head2 emergency($msg)

Level 0

aka: C<_0()>, C<emerg()>

=head2 alert($msg)

Level 1

aka: C<_1()>

=head2 critical($msg)

Level 2

aka: C<_2()>, C<crit()>

=head2 error($msg)

Level 3

aka: C<_3()>, C<err()>

=head2 warning($msg)

Level 4

aka: C<_4()>, C<warn()>

=head2 notice($msg)

Level 5

aka: C<_5()>

=head2 info($msg)

Level 6

aka: C<_6()>

=head2 debug($msg)

Level 7

aka: C<_7()>

=head2 fatal($msg)

Log the message, along with the trace C<confess()> produces, and die
immediately.

=head1 HELPER METHODS

These methods may be handy to the end user, but aren't required for end-use.

=head2 levels('names')

Returns the hash of level_num => level_name mapping.

If the optional string C<names> is sent in, we'll return an array of just the
names, in numeric order from lowest to highest.

=head2 timestamp

Returns the current time in the following format: C<2016-03-17 17:51:02.241>

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/stevieb9/p5-logging-simple/issues>

=head1 REPOSITORY

L<https://github.com/stevieb9/p5-logging-simple>

=head1 BUILD RESULTS (THIS VERSION)

CPAN Testers: L<http://matrix.cpantesters.org/?dist=Logging-Simple>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Logging::Simple

=head1 SEE ALSO

There are too many other logging modules to list here, but the idea for this
one came from L<Log::Basic>. However, this one was written completely from
scratch.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

