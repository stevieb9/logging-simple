package Log::Simple;
use 5.007;
use strict;
use warnings;

use Carp qw(croak);
use POSIX qw(strftime);
use Time::HiRes qw(time);

our $VERSION = '0.05';

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

                $self->level($ENV{LS_LEVEL}) if defined $ENV{LS_LEVEL};

                if ($sub =~ /^_(\d)$/){
                    return if $1 > $self->level;
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

    if (defined $level) {
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
    $mode = 'w' if ! defined $mode;
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
    $child->name($self->name .".$name");
    return $child;
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

1;
__END__

=head1 NAME

Log::Simple - A simple but featureful logging mechanism.

=for html
<a href="http://travis-ci.org/stevieb9/p5-log-simple"><img src="https://secure.travis-ci.org/stevieb9/p5-log-simple.png"/>
<a href='https://coveralls.io/github/stevieb9/p5-log-simple?branch=master'><img src='https://coveralls.io/repos/stevieb9/p5-log-simple/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Log::Simple;

    my $log = Log::Simple->new(name => 'whatever'); # name is optional

    $log->warning("default level (4)");

    $log->_4("all levels can be called by number. This is warning()");

    $log->_7("this is debug(). Default level is 4, so this won't print");

    $log->level(7);
    $log->debug("same as _7(). It'll print now");

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

Lightweight (core-only) and very simple yet powerful debug tool for printing or
writing to file log type entries based on a configurable level (0-7).

It provides the ability to programmatically change which output tags to display,
provides numbered methods so you don't have to remember the name to number
level translation, provides the ability to create descendent children, easily
enable/disable file output, levels, display etc.

=head2 Log entry format

By default, log entries appear as such, with a timestamp, the name of the
facility, the name (if specified in the constructor) and finally the actual
log entry message.

    [2016-03-17 17:01:21.959][info][whatever] info facility, example output

All of the above tags can be enabled/disabled programatically at any time, and
there are others that are not enabled by default. See L<display> method for
details.

=head2 Levels

Verbosity and associated levels are:

=over

=item - level 0, 'emergency|emerg'
=item - level 1, `alert`
=item - level 2, `critical|crit`
=item - level 3, `error|err`
=item - level 4, `warning|warn`
=item - level 5, `notice`
=item - level 6, `info`
=item - level 7, `debug`

=back

Note that all named level methods have an associated _N method, so you don't
have to remember the names at all.

Setting the C<level> will display all messages related to that level and below.


=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/stevieb9/p5-log-simple/issues>

=head1 REPOSITORY

L<https://github.com/stevieb9/p5-log-simple>

=head1 BUILD RESULTS (THIS VERSION)

CPAN Testers: L<http://matrix.cpantesters.org/?dist=Log-Simple>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Simple

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

