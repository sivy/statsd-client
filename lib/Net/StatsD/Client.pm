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

    return $self;
}

=head2 timiing

    $client->timing( $stat, $time, $sample_rate );

Sends a timing packet to the StatsD server. Sample rate should be a between 0
and 1 and will default to 1, if not provided.

=cut

sub timing {
    my $self = shift;
    my ( $stat, $time, $sample_rate ) = @_;

    my $stats = { "$stat" => "$time|ms" };
    $self->_send( $stats, $sample_rate );
}

=head2 increment

    $client->increment( $stats, $sameple_rate );

Send an increment packet to a counter in the StatsD server.

Stats should be either a scalar statistics name or an array ref of statistics to
increment.

Sameple rate should be between 0 and 1 and will default to 1, if not provided.

=cut

sub increment {
    my $self = shift;
    my ( $stats, $sample_rate ) = @_;

    $self->_update_stats( $stats, 1, $sample_rate );
}

=head2 decrement

    $client->decrement( $stats, $sample_rate );

Send a decrement packet to a counter in the StatsD server.

Stats should be either a scalar statistics name or an array ref of statistics to
decrement.

Sameple rate should be between 0 and 1 and will default to 1, if not provided.

=cut

sub decrement {
    my $self = shift;
    my ( $stats, $sample_rate ) = @_;

    $self->_update_stats( $stats, -1, $sample_rate );
}

# Any required stats munging
sub _update_stats {
    my $self = shift;
    my ( $stats, $delta, $sample_rate ) = @_;

    unless (ref($stats) eq 'ARRAY_REF') {
        $stats = [$stats];
    }

    $delta ||= 1;
    $sample_rate ||= 1;

    my $data = {};
    for my $stat (@{$stats}) {
        $data->{$stat} = "$delta|c";
    }
    $self->_send( $data, $sample_rate );
}

# Send the packet
sub _send {
    my $self = shift;
    my ( $data, $sample_rate ) = @_;
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

    my $addr   = sprintf("%s:%d", $self->{host}, $self->{port});
    my $socket = IO::Socket::INET->new(
        PeerAddr => $addr,
        Proto    => 'udp'
    ) or die "ERROR in Socket Creation : $!\n";

    eval {
        for my $stat (keys %{$sampled_data}) {
            my $value = $sampled_data->{$stat};
            my $send_data = "$stat:$value";
            $socket->send( $send_data );
        }
    };

}

=head1 CONTRIBUTORS

Adam Taylor <ajct@cpan.org> - additional documentation.

=head1 SEE ALSO

L<http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/>
Etsy blog post introducting StatsD.

L<https://github.com/etsy/statsd> - StatsD github repository.

=cut

1;
