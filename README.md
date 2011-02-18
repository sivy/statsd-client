# NAME

Net::StatsD::Client - client library for sending stats to Etsy'd StatsD server

# SYNOPSIS

The brilliant devops folks at Etsy released (and posted about) an awesome little node.js-based stats server called statsd.

Statsd sits in front of the Graphite metrics server, providing a simple API for applications to send stats over UDP. UDP is "old tech" but is fire-and-forget -- clients don't have to wait for a response to keep processing.

# USAGE

    use Net::StatsD::Client;

    my $client = Net::StatsD::Client->new();

    $client->timing('perl_test.timing',500);
    $client->increment('perl_test.inc_int');
    $client->decrement('perl_test.inc_int');

# License

This code is released under the same license as Perl itself.