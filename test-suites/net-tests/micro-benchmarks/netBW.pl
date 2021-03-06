#! /usr/bin/perl 

#use warnings;
#use strict;
use Fcntl qw/:flock/;

open SELF, "< $0" or die ;
flock SELF, LOCK_EX | LOCK_NB  or die "Another instance of the same program is already running: $!";

require "../../../env.pl";                            # Sets up environment varilables for all agents

#setpriority(0,$$,19);                          # Uncomment if running script at a lower priority

# ------ End of Config options ---

#$SIG{INT} = \&signal_handler;
#$SIG{TERM} = \&signal_handler;

my @data = ();                                  # array to store metrics
my $now = `date +%s`;                           # metrics are sent with date stamp to graphite server

open(GRAPHITE, "| ../../../common/nc -w 25 $carbon_server $carbon_port") || die "failed to send: $!\n";

# ------------------------------agent specific sub routines-------------------
my @stats;
my @percentile;

# Start Capturing
my @args = ("./sysnet.pl", "$now");
  if (my $pid = fork) {
     # No waiting for child 
     #  waitpid($pid);  
  }
  else {
     # I am child, now execute external command in context of new process.
     exec(@args);
  }

#while ($iterations-- > 0 ) {
while (1) {
$now = `date +%s`;
open (INTERFACE, "netperf -H $peer -j -v 2 -l 10 -D 1 -p $net_dport -- -P $net_cport |")|| die print "failed to get data: $!\n";

  while (<INTERFACE>) {
  next if (/^$/ );
  next if !(/^Interim/);
  s/:/ /g;
  @stats= split;
  push (@percentile, $stats[2]);
 }
 close(INTERFACE);

@percentile = sort {$a <=> $b} @percentile; 

push @data, "$server-netbench.$host.benchmark.BW.min $percentile[0] $now \n";
push @data, "$server-netbench.$host.benchmark.BW.max $percentile[-1] $now \n";
my $tmp = $percentile[sprintf("%.0f",(0.95*($#percentile)))];
 push @data, "$server-netbench.$host.benchmark.BW.95th $tmp $now \n";
my $tmp = $percentile[sprintf("%.0f",(0.99*($#percentile)))];
 push @data, "$server-netbench.$host.benchmark.BW.99th $tmp $now \n";

# Ship Metrics to carbon server --- 
  #print @data; 			# For Testing only 
  #print "\n------\n"; 			# For Testing only
  print GRAPHITE  @data;  		# Ship metrics to carbon server
  @data=();     			# Initialize for next set of metrics
  @percentile=();
} # while
`sudo pkill -9 sysnet.pl`;
