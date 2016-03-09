#! /bin/bash
#
# This is a shell script to get WRT (web response time)
#
# Input file(s):
#
#	wrt.out
#
# Output file(s):
#
#	WRT.out
#

#echo "The script you are running has basename `basename $0`, dirname `dirname $0`"
#echo "The present working directory is `pwd`"

# Script directory
scrdir=`dirname $0`

# awk scripts
getWRTSilent_awk=$scrdir/getWRTSilent.awk
getWRT_awk=$scrdir/getWRT.awk

if [ -e wrt.out ]; then
	awk -f $getWRTSilent_awk wrt.out > WRT.out
	awk -f $getWRT_awk wrt.out
fi

