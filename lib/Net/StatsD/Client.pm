package Net::StatsD::Client;

use strict;
use warnings;

$VERSION = '0.2';

=head1 NAME

Net::StatsD::Client - client library for sending stats to Etsy'd StatsD server

=head1 SYNOPSIS

The brilliant devops folks at Etsy released (and posted about) an awesome little node.js-based stats server called statsd.

Statsd sits in front of the Graphite metrics server, providing a simple API for applications to send stats over UDP. UDP is "old tech" but is fire-and-forget -- clients don't have to wait for a response to keep processing.

=cut

use IO:Socket::INET;

sub new {
    my $class = shift;
    my %options = @_;
    $options{host} ||= 'localhost';
    $options{port} ||= 8125;
    my $self = bless \%options, $class;
    
    $self;
}

sub update_stats {
    my $self = shift;
    my ($stats, $delta, $sample_rate) = @_;
    $delta ||= 1;
    $sample_rate ||= 1;

    my $data = {};
    for my $stat (@{$stats}) {
        $data->{$stat} = "$delta|c";
    }
    $self->send($data, $sample_rate);
}

# send the data
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
    $socket = new IO::Socket::INET (
        PeerAddr   => $addr,
        Proto        => 'udp'
    ) or die "ERROR in Socket Creation : $!\n";
    
    eval {
        for my $stat (keys %{$sample_data}) {
            $value = $sample_data->{$stat};
            $send_data = "$stat:$value";
            $socket->send($send_data);
        }
    };
        
}
1;