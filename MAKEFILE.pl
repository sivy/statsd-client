#!/usr/bin/perl
#
#   Perl Makefile for Perlbal
#   $Id: Makefile.PL 554 2006-09-03 09:18:05Z hachi $
#
#   Invoke with 'perl Makefile.PL'
#
#   See ExtUtils::MakeMaker (3) for more information on how to influence
#    the contents of the Makefile that is written
#

use ExtUtils::MakeMaker;

WriteMakefile(
              NAME           => 'Net::StatsD::Client',
              VERSION_FROM   => 'lib/Net/StatsD/Client.pm',
              EXE_FILES      => ['net_statsd_client'],
              AUTHOR         => 'Steve Ivy <steveivy@gmail.com>',
              ABSTRACT_FROM  => 'lib/Net/StatsD/Client.pm',
              );