#!/usr/bin/perl -w

# USAGE:
#
# /RSAY <text>
#  - same as /say, but outputs a coloured text
#
# /RME <text>
#  - same as /me, but outputs a coloured text
#
# /RTOPIC <text>
#  - same as /topic, but outputs a coloured text :)
#
# /RKICK <nick> [reason]
#  - kicks nick from the current channel with coloured reason
#
# rainbow:<word> followed by <TAB>
#  - Replaces <word> with rainbow-colored word inline

# Written by Jakub Jankowski <shasta@atn.pl>
# for Irssi 0.7.98.4 and newer
# Tab completion by Benjamin Staffin <benley@gmail.com>

use strict;
use vars qw($VERSION %IRSSI);

$VERSION = "1.5-z1";
%IRSSI = (
    authors     => 'Jakub Jankowski',
    contact     => 'shasta@atn.pl',
    name        => 'rainbow',
    description => 'Prints colored text. Rather simple than sophisticated.',
    license     => 'GNU GPLv2 or later',
    url         => 'http://irssi.atn.pl/',
);

use Irssi;
use Irssi qw/signal_add_last/;
use Irssi::Irc;

# colors list
#  0 == white
#  4 == light red
#  8 == yellow
#  9 == light green
# 11 == light cyan
# 12 == light blue
# 13 == light magenta
my @colors = ('4', '8', '9', '11', '12', '13');

# str make_colors($string)
# returns random-coloured string
sub make_colors {
    my ($string, $stretch) = @_;
    my $newstr = "";
    my $last = 255;
    my $color = 0;

    unless (defined $stretch) {
      $stretch = Irssi::settings_get_int('rainbow_stretch');
    }

    my $step;
    if ($stretch > 0) {
      $step = length($string) / (@colors-1); # int(this line)
#      $step = 1 if $step < 1;
      $step = $stretch if $step > $stretch;
    } else {
      $step = 1;
    }
    my $err = 0;
    for (my $c = 0; $c < length($string); $c += 1) { # += $step
#        my $section = substr($string, $c, $step);
        my $curcol = int($c/$step+$err+0.25+0.5*rand());
        $err = $err + 0.5*($c/$step - $curcol);
        my $nexterr = $err;
	my $steplen = 1;
        for (my $d = 0; $d < $step; $d += 1) {
          my $nextcol = int(($c+$d)/$step+$nexterr+0.25+0.5*rand());
          $nexterr = $nexterr + 0.5*(($c+$d)/$step-$nextcol);
          if ($nextcol == $curcol) {
            $steplen += 1;
            $err = $nexterr;
          }
          else {
            last;
	  }
        }
	my $section = substr($string, $c, $steplen);
        $c += $steplen - 1; # advance in the string.
        if ($section eq ' ') {
            $newstr .= $section;
            next;
        }

        $newstr .= "\003";
        $newstr .= sprintf("%d", $colors[$curcol % @colors]); # $color % @colors
        $newstr .= $section;
        $color++;
    }

    return $newstr . "\003"; # One last ^C to return to normal text color.
}

# void rsay($text, $server, $destination)
# handles /rsay
sub rsay {
    my ($text, $server, $dest) = @_;

    if (!$server || !$server->{connected}) {
        Irssi::print("Not connected to server");
        return;
    }

    return unless $dest;

    if ($dest->{type} eq "CHANNEL" || $dest->{type} eq "QUERY") {
        $dest->command("/msg " . $dest->{name} . " " . make_colors($text));
    }
}

# void rme($text, $server, $destination)
# handles /rme
sub rme {
    my ($text, $server, $dest) = @_;

    if (!$server || !$server->{connected}) {
        Irssi::print("Not connected to server");
        return;
    }

    if ($dest && ($dest->{type} eq "CHANNEL" || $dest->{type} eq "QUERY")) {
        $dest->command("/me " . make_colors($text));
    }
}

# void rtopic($text, $server, $destination)
# handles /rtopic
sub rtopic {
    my ($text, $server, $dest) = @_;

    if (!$server || !$server->{connected}) {
        Irssi::print("Not connected to server");
        return;
    }

    if ($dest && $dest->{type} eq "CHANNEL") {
        $dest->command("/topic " . make_colors($text));
    }
}

# void rkick($text, $server, $destination)
# handles /rkick
sub rkick {
    my ($text, $server, $dest) = @_;

    if (!$server || !$server->{connected}) {
        Irssi::print("Not connected to server");
        return;
    }

    if ($dest && $dest->{type} eq "CHANNEL") {
        my ($nick, $reason) = split(/ +/, $text, 2);
        return unless $nick;
        $reason = "Irssi power!" if ($reason =~ /^[\ ]*$/);
        $dest->command("/kick " . $nick . " " . make_colors($reason));
    }
}

# Bind tab completion: typing rainbow:<whatevertext> -> colorize <whatevertext>
signal_add_last 'complete word' => sub {
    my ($complist, $window, $word, $linestart, $want_space) = @_;

    if($word =~ /^rainbow:(.*)$/) {
      my($text) = $1;
      push @$complist, make_colors($text);
    }
};

Irssi::settings_add_int('rainbow', 'rainbow_stretch', 20);

Irssi::command_bind("rsay", "rsay");
Irssi::command_bind("rtopic", "rtopic");
Irssi::command_bind("rme", "rme");
Irssi::command_bind("rkick", "rkick");

# changes:
#
# 25.01.2002: Initial release (v1.0)
# 26.01.2002: /rtopic added (v1.1)
# 29.01.2002: /rsay works with dcc chats now (v1.2)
# 02.02.2002: make_colors() doesn't assign any color to spaces (v1.3)
# 23.02.2002: /rkick added
# 26.04.2012: Tab completion binding (v1.4-benley1)
# 25.09.2012: Change stretching techniques
