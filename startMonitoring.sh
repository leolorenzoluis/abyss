#!/bin/bash
killall()
{
 kill  `pgrep systats.pl`   2>/dev/null
 kill  `pgrep tcpstats.pl`  2>/dev/null
 kill  `pgrep iolatency.pl` 2>/dev/null
 kill  `pgrep cassandra.pl` 2>/dev/null
 kill  `pgrep elasticsearch` 2> /dev/null
 kill  `pgrep tomcat.pl` 2>/dev/null
 kill  `ps -elf|grep CLOUDSTAT|grep -v grep |awk '{print $4}'` 2>/dev/null

for PID in $PIDLIST
 do
        kill -9 $PID 2>/dev/null
 done
exit
}

trap "killall" HUP INT QUIT KILL TERM USR1 USR2 EXIT

# Agent to monitor system stats: cpu, io, disk, net, mem
cd monitor
nohup ./loop-systats.sh &
PIDLIST="$PIDLIST $!"
cd ..

# Agent to monitor Storage IO size and latencies
# check if perf is installed
if [[ ( -f "/usr/bin/perf") || ( -f "/bin/perf") ]]
then
 cd sniffer/IO
 nohup ./loop-iolatency.sh &
 PIDLIST="$PIDLIST $!"
 cd ../../
else
  echo "perf is not available. iolatency agent is not started"
fi

# Agent to monitor low level tcp stats: per connection RTT, Throughput, Retransmit, Congestion, etc..
#if [ -f "/usr/bin/make" ] 
#then
#   cd sniffer/NET
#   nohup ./loop-tcpstats.sh &
#   PIDLIST="$PIDLIST $!"
#   cd ../../ 
#fi
#
# Agent to monitor Application stats via JMX port. 
# We can monitor only one java app per instance or system
#
# cassandra Agent
found=0
pid=`sudo jps|egrep "DseDaemon|DseModule|CassandraDaemon"|awk '{print $1}'` >> /dev/null
if ps --pid $pid &>/dev/null
then
 found=1
 cd java-apps/cassandra
 nohup ./loop-cassandra30.sh &
 PIDLIST="$PIDLIST $!"
 cd ../..
fi
# Kafka Agent
if [ $found == 0 ] 
then
 pid=`jps|grep Kafka|awk '{print $1}'` >> /dev/null
 if ps --pid $pid &>/dev/null
 then
   found=1
   cd java-apps/kafka
   nohup ./loop-kafka.sh &
   PIDLIST="$PIDLIST $!"
   cd ../..
 fi
fi

# ElasticSearch Agent
if [ $found == 0 ]
then
 pid=`sudo jps|grep Elastic|awk '{print $1}'` >> /dev/null
 if ps --pid $pid &>/dev/null
 then
   found=1
   cd java-apps/elasticsearch
   nohup ./loop-elasticsearch.sh &
   PIDLIST="$PIDLIST $!"
   cd ../..
 fi
fi


# Tomcat Agent
#if [ $found == 0 ]
#then
# pid=`jps|grep Bootstrap|awk '{print $1}'` >> /dev/null
# if ps --pid $pid &>/dev/null
# then
#  cd java-apps/tomcat
#  nohup ./loop-tomcat.sh &
#  PIDLIST="$PIDLIST $!"
#  cd ../..
# fi
#fi

wait

