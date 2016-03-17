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

Log::Simple - Perl extension for simple logging.

=for html
<a href="http://travis-ci.org/stevieb9/p5-log-simple"><img src="https://secure.travis-ci.org/stevieb9/p5-log-simple.png"/>
<a href='https://coveralls.io/github/stevieb9/p5-log-simple?branch=master'><img src='https://coveralls.io/repos/stevieb9/p5-log-simple/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

  perl -MLog::Simple -e 'info "hey"'

  use Log::Simple;
  $Log::Simple::VERBOSITY=3;
  debug "stuff"; # won't be printed
  info "here is the info message"; # won't be printed
  warning "wow! beware!";
  error "something terrible happend !";
  msg "this message will be displayed whatever the verbosity level";
  sep "a separator";
  fatal "fatal error: $!";

=head1 DESCRIPTION

Log::Simple displays formatted messages according to the defined verbosity level (default:4).

=head2 Format

Log messages are formatted as: `[<level>] <date> - <message>`.
Dates are formatted as: `YYYY-MM-DD hh:mm:ss`.
Your message could be whatever you what.

=head2 Levels

Verbosity and associated levels are:

=over

=item - level 1, `msg`

=item - level 2, `error`

=item - level 3, `warn`

=item - level 4, `info`

=item - level 5, `debug`

=item - no level, `fatal`

=back

Setting verbosity to 3 will print `warn`, `info`, and `msg` only.

=head2 Special cases

`fatal` is a special level, corresponding to perl's `die()`.

Separator is a special functions which display a line of 80 dashes, with your message eventually.

=head2 Saving to file

All messages will also be appended to a file. If a `./log/` folder exists, a `$$.$0.log` file is created within this folder, otherwise the `$$.$0.log` file is created in the current directory.

=head1 EXPORT

debug info warning error msg sep fatal

=head1 AUTHOR

Kevin Gravouil, E<lt>k.gravouil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Kevin Gravouil

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

