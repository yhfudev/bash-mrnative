#
# Awk script to get TCP flow stats
#

BEGIN { FS = " "; delayDS = 0; lossRateDS = 0; thruputDS = 0; } 

{x++}
{cxID = $1}
{DS++}
{delayDS=delayDS+$8} 
{lossRateDS=lossRateDS+$5} 
{thruputDS=thruputDS+$9} 

END {
    print "number Flows: " x;
    print "avg RTT: " delayDS/DS;
    print "avg loss rate: " lossRateDS/DS;
    print "avg thruput: " thruputDS/DS;
    printf("Aggregate Throughput:%12d,  Avg Throughput:%12d, avg RTT:%3.3f, avgLossRate:%3.3f \n",thruputDS, thruputDS/DS, delayDS/DS,lossRateDS/DS);
}


