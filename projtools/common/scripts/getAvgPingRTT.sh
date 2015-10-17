#! /bin/bash
#
# This is a shell script to get WRT (web response time)
#
#
# Input file(s):
#
#	ping1.out
#
# Output file(s):
#
#	pingRTT.out
#

#echo "The script you are running has basename `basename $0`, dirname `dirname $0`"
#echo "The present working directory is `pwd`"

# Script directory
scrdir=`dirname $0`

# Ping
if [ -e ping1.out ]; then
	awk -f $scrdir/getAvgPingRTT.awk ping1.out
	awk -f $scrdir/getAvgPingRTTSilent.awk ping1.out > pingRTT.out
fi

# DS Loss Monitor
if [ -e DSLossMon.out ]; then
	echo 'And Downstream Loss Monitor is : '
	cat DSLossMon.out
fi

# US Loss Monitor
if [ -e USLossMon.out ]; then
	echo 'And Upstream Loss Monitor is : '
	cat USLossMon.out
fi

