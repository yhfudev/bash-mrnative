#! /bin/bash
#
# This is the main shell script that drives many other scripts
# to get all statistics of a simulation run
#

#echo "The script you are running has basename `basename $0`, dirname `dirname $0`"
#echo "The present working directory is `pwd`"

# Scripts directory
scrdir=./Scripts

# Clear out old output file if any
#truncate --size=0 getall.out
:>getall.out

# ---------------------

# Call getBW script (output: allBWstats.out, allTSBWstats.out, allNTSBWstats.out)
$scrdir/getBW.sh

# ----------------------

echo "create getall.out" >> getall.out
grep "Total CM" log.out >> getall.out

# Get web stream stats if any
$scrdir/getAvgWebBW.sh >> getall.out

# Get web response time stats if any
$scrdir/getWRT.sh >> getall.out

# Get ping stats if any
$scrdir/getAvgPingRTT.sh >> getall.out

# Get TCP/UDP stats if any
$scrdir/getTCPstats.sh >> getall.out
$scrdir/getUDPstats.sh >> getall.out

# Get CM stats if any
$scrdir/getCMConcatstats.sh >> getall.out
$scrdir/getCMMAPstats.sh >> getall.out
$scrdir/getCMTSMAPstats.sh >> getall.out
$scrdir/getCMstats.sh >> getall.out

# Get SF stats if any
$scrdir/getSFstats.sh >> getall.out

# ???
$scrdir/proc1.sh >> getall.out

# Get CMTS stats if any
$scrdir/getCMTSstats.sh >> getall.out

# Channel stats
grep "CHANNEL STATS" log.out >> getall.out

# Get CMTS stats per channel
$scrdir/getCMTSstatsperchannel.sh >> getall.out

echo "done with new getall.out" 

