package Net::StatsD::Client;

use strict;
use warnings;

our $VERSION = '0.4';

=head1 NAME

Net::StatsD::Client - client library for sending stats to Etsy'd StatsD server

=head1 SYNOPSIS

The brilliant devops folks at Etsy released (and posted about) an awesome little node.js-based stats server called statsd.

Statsd sits in front of the Graphite metrics server, providing a simple API for applications to send stats over UDP. UDP is "old tech" but is fire-and-forget -- clients don't have to wait for a response to keep processing.

=cut

use IO::Socket::INET;

sub new {
    my $class = shift;
    my %options = @_;
    $options{host} ||= 'localhost';
    $options{port} ||= 8125;
    my $self = bless \%options, $class;
    
    $self;
}

sub timing {
    my $self = shift;
    my ($stat, $time, $sample_rate) = @_;
    
    my $stats = { "$stat" => "$time|ms" };
    $self->send($stats, $sample_rate);
}

sub increment {
    my $self = shift;
    my ($stats, $sample_rate) = @_;
    
    $self->update_stats($stats, 1, $sample_rate);
}

sub decrement {
    my $self = shift;
    my ($stats, $sample_rate) = @_;
    
    $self->update_stats($stats, -1, $sample_rate);
}

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