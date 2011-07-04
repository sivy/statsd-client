# ABSTRACT: Client library for sending stats to a StatsD server

=head1 SYNOPSIS

    use Net::StatsD::Client;

    my $client = Net::StatsD::Client->new();

    $client->timing('perl_test.timing',500);
    $client->increment('perl_test.inc_int');
    $client->decrement('perl_test.inc_int');


=head1 DESCRIPTION

The brilliant devops folks at Etsy released (and posted about) an awesome little
node.js-based stats server called statsd.

Statsd sits in front of the Graphite metrics server, providing a simple API for
applications to send stats over UDP. UDP is "old tech" but is fire-and-forget
-- clients don't have to wait for a response to keep processing.

=head1 METHODS

=cut

package Net::StatsD::Client;

use strict;
use warnings;

our $VERSION = '0.5';

=head2 new

    my $client = Net::StatsD::Client->new( host => ?, port => ? );

Instantiates a new L<Net::StatsD::Client> object.

The paramaters are optional, host defaults to 'localhost' and port defaults to
'8125', if not provided.

=cut

sub new {
    my $class = shift;
    my %options = @_;
    $options{host} ||= 'localhost';
    $options{port} ||= 8125;
    my $self = bless \%options, $class;

    $self;
}

=head2 timiing

    $client->timing( $stat, $time, $sample_rate );

Sends a timing packet to the StatsD server. Sample rate should be a between 0
and 1 and will default to 1, if not provided.

=cut

sub timing {
    my $self = shift;
    my ($stat, $time, $sample_rate) = @_;

    my $stats = { "$stat" => "$time|ms" };
    $self->send($stats, $sample_rate);
}

=head2 increment

    $client->increment( $stat, $sameple_rate );

Send an increment packet to a counter in the StatsD server. Sameple rate should be
between 0 and 1 and will default to 1, if not provided.

=cut

sub increment {
    my $self = shift;
    my ($stats, $sample_rate) = @_;

    $self->update_stats($stats, 1, $sample_rate);
}

=head2 decrement

    $client->decrement( $stat, $sample_rate );

Send an decrement packet to a counter in the StatsD server. Sameple rate should be
between 0 and 1 and will default to 1, if not provided.


=cut

sub decrement {
    my $self = shift;
    my ($stats, $sample_rate) = @_;

    $self->update_stats($stats, -1, $sample_rate);
}

# Any required stats munging
sub update_stats {
    my $self = shift;
    my ($stats, $delta, $sample_rate) = @_;

    unless (ref($stats) eq 'ARRAY_REF') {
        $stats = [$stats];
    }

    $delta ||= 1;
    $sample_rate ||= 1;

    my $data = {};
    for my $stat (@{$stats}) {
        $data->{$stat} = "$delta|c";
    }
    $self->send($data, $sample_rate);
}

# Send the packet
sub send {
    my $self = shift;

    my ($data, $sample_rate) = @_;
    $sample_rate ||= 1;

    my $sampled_data = {};

    if ($sample_rate < 1) {
        if (rand() <= $sample_rate) {
            for my $stat (keys %{$data}) {
                my $value = $data->{$stat};
                $sampled_data->{$stat} = sprintf("%s|@%s", $value, $sample_rate);
            }
        }
    }
    else {
        $sampled_data = $data;
    }

    my $addr = sprintf("%s:%d", $self->{host}, $self->{port});
    my $socket = new IO::Socket::INET (
        PeerAddr   => $addr,
        Proto        => 'udp'
    ) or die "ERROR in Socket Creation : $!\n";

    eval {
        for my $stat (keys %{$sampled_data}) {
            my $value = $sampled_data->{$stat};
            my $send_data = "$stat:$value";
            $socket->send($send_data);
        }
    };

}
1;
