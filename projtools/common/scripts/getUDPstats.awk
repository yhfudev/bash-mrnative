#
# Awk script to get UDP flow stats
#

BEGIN { FS = " "; latency = 0; jitter = 0; throughput = 0; lossRate = 0; x=0; aggregateBytes = 0; } 

{
    x++;
    cxID = $1;
    latency=latency+$9;
    jitter=jitter+$8;
    aggregateThroughput=aggregateThroughput + $7;
    throughput=throughput+$7;
    lossRate=lossRate+$6;
    aggregateBytes = aggregateBytes + $2;
}

END {
    printf("number UDP Flows: %d,   aggregate bytes delivered: %d, aggregate throughput:%d bps\n",x,aggregateBytes,aggregateThroughput);
    print "avg UDP latency (sec): " latency/x; 
    print "avg UDP jitter (sec): " jitter/x; 
    print "avg UDP loss rate: " lossRate/x; 
    print "avg UDP throughput (bps): " throughput/x; 
}
