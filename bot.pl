#!/usr/bin/perl
use strict;
use warnings;

use IO::Socket::INET;

my $server = 'irc.ephasic.org';
my $port = 6667;
my $nickname = 'Cat';
my @channels = ('#Lobby', '#Perl');

my $responses_file = 'responses.txt';

my %responses;
open my $fh, '<', $responses_file or die "Can't open $responses_file: $!\n";
while (my $line = <$fh>) {
    chomp $line;
    my ($wildcard, $responses_str) = split /\s*:\s*/, $line, 2;
    my @responses = split /\s*,\s*/, $responses_str;
    $responses{$wildcard} = \@responses;
}
close $fh;

my %variables = (
    CITY => ['New York', 'Los Angeles', 'London', 'Paris', 'Tokyo'],
    WEATHER => ['sunny', 'cloudy', 'rainy', 'snowy', 'windy'],
    TEMP => ['20', '25', '30', '35', '40'],
    MOVIE => ['The Godfather', 'Star Wars', 'The Shawshank Redemption', 'The Lord of the Rings', 'Pulp Fiction'],
    GENRE => ['rock', 'pop', 'hip-hop', 'jazz', 'classical'],
    BAND => ['The Beatles', 'Led Zeppelin', 'Pink Floyd', 'The Rolling Stones', 'Queen'],
    SONG => ['Stairway to Heaven', 'Bohemian Rhapsody', 'Hotel California', 'Thriller', 'Sweet Child O\' Mine'],
    FOOD => ['pizza', 'sushi', 'tacos', 'pasta', 'burger'],
    DRINK => ['beer', 'wine', 'cocktail', 'coffee', 'tea'],
    HOLIDAY => ['Christmas', 'Thanksgiving', 'Halloween', 'Easter', 'New Year\'s Day'],
    SPORT => ['soccer', 'basketball', 'football', 'tennis', 'baseball'],
    TEAM => ['Real Madrid', 'Los Angeles Lakers', 'Manchester United', 'New England Patriots', 'New York Yankees'],
    COLOR => ['red', 'blue', 'green', 'yellow', 'purple'],
    ANIMALS => ['elephants', 'penguins', 'dolphins', 'lions', 'pandas'],
    TIME => ['10:00 AM', '2:30 PM', '6:45 PM', '9:15 AM', '1:00 PM'],
    HOUR => ['10', '2', '6', '9', '1'],
    MINUTE => ['00', '30', '45', '15', '20'],
    AMPM => ['AM', 'PM'],
);

# Read the responses file
my %responses;
open(my $fh, '<', 'responses.txt') or die "Could not open file 'responses.txt': $!";
while (my $line = <$fh>) {
    chomp($line);
    my ($wildcard, $responses_str) = split(/:/, $line, 2);
    my @responses = split(/,/, $responses_str);
    $responses{$wildcard} = \@responses;
}
close($fh);

# Generate the variable data for each wildcard
foreach my $wildcard (keys %responses) {
    foreach my $response (@{$responses{$wildcard}}) {
        $response =~ s/%($_)%/$variables{$_}[rand @{$variables{$_}}]/eg for keys %variables;
    }
}

# Print the variable data for each wildcard
foreach my $wildcard (keys %responses) {
    print "$wildcard:\n";
    foreach my $response (@{$responses{$wildcard}}) {
        print "  $response\n";
    }
    print "\n";
}

my $socket = IO::Socket::INET->new(
    PeerAddr => $server,
    PeerPort => $port,
    Proto    => 'tcp'
) or die "Can't connect: $!\n";

print "Connected to server $server\n";

print $socket "USER $nickname 8 * :Perl IRC Bot\n";
print $socket "NICK $nickname\n";
print $socket "JOIN $_\n" for @channels;

print "Joined channels: @channels\n";

while (my $data = <$socket>) {
    chomp $data;
    print "Received data: $data\n";

    if ($data =~ /^PING(.*)$/i) {
        print $socket "PONG $1\n";
    }
    elsif ($data =~ /PRIVMSG ([\w#]+) :(.+)/) {
        my ($channel, $msg) = ($1, $2);
        for my $wildcard (keys %responses) {
            if ($msg =~ /$wildcard/i) {
                my $responses = $responses{$wildcard};
                my $response = $responses->[rand @$responses];
                print $socket "PRIVMSG $channel :$response\n";
                last;
            }
        }
    }
}
