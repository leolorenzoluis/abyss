#! /usr/bin/perl 

#use warnings;
#use strict;
use Fcntl qw/:flock/;

open SELF, "< $0" or die ;
flock SELF, LOCK_EX | LOCK_NB  or die "Another instance of the same program is already running: $!";

require "../../env.pl";                            # Sets up environment varilables for all agents

#setpriority(0,$$,19);                          # Uncomment if running script at a lower priority


#$SIG{INT} = \&signal_handler;
#$SIG{TERM} = \&signal_handler;

my @data = ();                                  # array to store metrics
my $now = `date +%s`;                           # metrics are sent with date stamp to graphite server

open(GRAPHITE, "| ../../common/nc -w 25 $carbon_server $carbon_port") || die "failed to send: $!\n";

# ------------------------------agent specific sub routines-------------------

my @stats;
my @rpercentile;
my @wpercentile;

while (1) {
   open (PERF, " ./diskstats|")|| die print "failed to get data: $!\n";
   $now = `date +%s`;
   while (<PERF>) {
   #print;
  @stats= split;
  #print "stats:$stats[0]\n";
  push (@rpercentile, $stats[1]) if ($stats[0] =~ /R/);
  push (@wpercentile, $stats[1]) if ($stats[0] =~ /W/);
  push (@rSize, $stats[1]) if ($stats[0] =~ /Size-*R/);
  push (@wSize, $stats[1]) if ($stats[0] =~ /Size-*W/);
  }
 close(PERF);

# Sort
@rpercentile = sort {$a <=> $b} @rpercentile;
@wpercentile = sort {$a <=> $b} @wpercentile;
@rSize = sort {$a <=> $b} @rSize;
@wSize = sort {$a <=> $b} @wSize;

# ---- Read Write Latency
push @data, "$server.$host.system.io.Latency.Read.min $rpercentile[0] $now \n";
push @data, "$server.$host.system.io.Latency.Read.max $rpercentile[-1] $now \n";
push @data, "$server.$host.system.io.Latency.Write.min $wpercentile[0] $now \n";
push @data, "$server.$host.system.io.Latency.Write.max $wpercentile[-1] $now \n";
# Print 95% percentile
my $tmp = $rpercentile[sprintf("%.0f",(0.95*($#rpercentile)))];
 push @data, "$server.$host.system.io.Latency.Read.95th $tmp $now \n";
my $tmp = $wpercentile[sprintf("%.0f",(0.95*($#wpercentile)))];
 push @data, "$server.$host.system.io.Latency.Write.95th $tmp $now \n";
# Print 99% percentile
my $tmp = $rpercentile[sprintf("%.0f",(0.99*($#rpercentile)))];
 push @data, "$server.$host.system.io.Latency.Read.99th $tmp $now \n";
my $tmp = $wpercentile[sprintf("%.0f",(0.99*($#wpercentile)))];
 push @data, "$server.$host.system.io.Latency.Write.99th $tmp $now \n";

#----Read Write Size
push @data, "$server.$host.system.io.Size.Read.min $rSize[0] $now \n";
push @data, "$server.$host.system.io.Size.Read.max $rSize[-1] $now \n";
push @data, "$server.$host.system.io.Size.Write.min $wSize[0] $now \n";
push @data, "$server.$host.system.io.Size.Write.max $wSize[-1] $now \n";
# Print 95% percentile
my $tmp = $rSize[sprintf("%.0f",(0.95*($#rSize)))];
 push @data, "$server.$host.system.io.Size.Read.95th $tmp $now \n";
my $tmp = $wSize[sprintf("%.0f",(0.95*($#wSize)))];
 push @data, "$server.$host.system.io.Size.Write.95th $tmp $now \n";
# Print 99% percentile
my $tmp = $rSize[sprintf("%.0f",(0.99*($#rSize)))];
 push @data, "$server.$host.system.io.Size.Read.99th $tmp $now \n";
my $tmp = $wSize[sprintf("%.0f",(0.99*($#wSize)))];
 push @data, "$server.$host.system.io.Size.Write.99th $tmp $now \n";



  #print @data; 			# For Testing only 
  #print "\n------\n"; 			# For Testing only
  print GRAPHITE  @data;  		# Ship metrics to carbon server
  @data=();     			# Initialize for next set of metrics
  @rpercentile=();
  @wpercentile=();

  sleep $interval;
}

