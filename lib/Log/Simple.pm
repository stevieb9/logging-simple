package Log::Simple;
use 5.020002;
use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    if (defined $args{level}) {
        $self->level($args{level});
    }
    else {
        $self->{level} = 4;
    }

    $self->{file} = defined $args{file}
        ? $args{file}
        : '';

    if ($self->{file}){
        $self->file($self->{file});
    }

    $self->{print} = 1;

    $self->{display} = {
        time => 1,
        label => 1,
        pid => 0,
        proc => 0,
    };

    return $self;
}
sub level {
    my ($self, $level) = @_;

    my %levels = $self->labels;
    my %rev = reverse %levels;

    if (defined $level) {
        if ($level =~ /^\d$/ && defined $levels{$level}) {
            $self->{level} = $level;
            $self->{display_level} = "$level:$levels{$level}";
        }
        elsif ($level =~ /^\w{3}/ && (my ($l_name) = grep /^$level/, keys %rev)){
            $self->{level} = $rev{$l_name};
            $self->{display_level} = "$rev{$l_name}:$l_name";
        }
        else {
            warn "invalid level specified, using default 'warning' (4)\n";
        }
    }
    return $self->{display_level};
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
sub timestamp {
	my ($S,$M,$H,$d,$m,$y) = localtime(time);
	return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $y+1900, $m+1 ,$d,$H,$M,$S);
}
sub labels {
    my ($self, $want) = @_;

    my %levels = (
        0 => 'emergency',
        1 => 'alert',
        2 => 'crititcal',
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

    return 1 if defined $tags{all} || defined $tag && $tag eq 'all';
    return $self->{display}{$tag} if defined $tag;

    if ($tag){
        return $self->{display}{$tag};
    }
    for (keys %tags) {
        if (! defined $self->{display}{$_}) {
            warn "$_ is an invalid tag...skipping\n";
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
my $VERBOSITY = 5;

sub _build {
    my $self = shift;
    my $label = shift;

    my @labels = $self->labels('names');

    if (! grep { $label eq $_ } @labels){
        croak "_build() requires a label name as its first param\n";
    }

    my $msg;
    $msg .= "[".$self->timestamp()."]" if $self->display('time');
    $msg .= "[$label]" if $self->display('label');
    $msg .= "[pid:$$]" if $self->display('pid');
    $msg .= "[proc:]" if $self->display('proc');
    $msg .= " @_\n";

    return $msg if ! $self->print;

    if ($self->{fh}){
        print { $self->{fh} } $msg;
    }
    else {
        print $msg;
    }
}
sub debug {
    my $self = shift;
    print "[".$self->timestamp()."]" if $self->display('time');
    print "[debug]" if $self->display('label');
    print "[pid:$$]" if $self->display('pid');
    print "[proc:]" if $self->display('proc');
    print " @_\n" if $VERBOSITY > 4;
}
sub info {
	print "[info]  [proc:$$] [".timestamp()."] @_\n" if $VERBOSITY > 3;
	print OUT "[info]  [proc:$$] [".timestamp()."] @_\n" if(fileno(OUT));
}
sub warning {
	print "[warn]  [proc:$$] [".timestamp()."] @_\n" if $VERBOSITY > 2;
	print OUT "[warn]  [proc:$$] [".timestamp()."] @_\n" if(fileno(OUT));
}
sub error {
	print "[error] [proc:$$] [".timestamp()."] @_\n" if $VERBOSITY > 1;
	print OUT "[error] [proc:$$] [".timestamp()."] @_\n" if(fileno(OUT));
}
sub msg {
	print "[msg]   [proc:$$] [".timestamp()."] @_\n" if $VERBOSITY > 0;
	print OUT "[msg]   [proc:$$] [".timestamp()."] @_\n" if(fileno(OUT));
}
sub fatal {
	print OUT "[fatal] [proc:$$] [".timestamp()."] @_\n" if(fileno(OUT));
	die "[fatal] [proc:$$] [".timestamp()."] @_\n";
}
sub sep {
	my $str = join(' ', "[proc:$$]", @_);
	print '---', $str, '-' x (80 - (3 + length $str)), "\n";
	print OUT '---', $str, '-' x (80 - (3 + length $str)), "\n";
}
END {
	#close $self->{fh};
}
1;
__END__

=head1 NAME

Log::Simple - Perl extension for simple logging.

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

