#! /bin/bash
#
# This is a shell script to get bandwidth info of web streams
#
# Input file(s):
#
#	SESSION_TRAF.out
#
# Output file(s):
#

# Script directory
scrdir=`dirname $0`

# getAvgWebBW2.awk
getAvgWebBW2_awk=$scrdir/getAvgWebBW2.awk

if [ -e SESSION_TRAF.out ]; then
	awk -f $getAvgWebBW2_awk SESSION_TRAF.out
fi

