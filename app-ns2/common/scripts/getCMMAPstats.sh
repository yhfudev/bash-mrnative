#! /bin/bash
#
# This is a shell script to get CM stats
#
#
# Input file(s):
#
#	CMMAP.out
#
# Output file(s):
#

# Script directory
scrdir=`dirname $0`

# getCMMAPstats.awk
getCMMAPstats_awk=$scrdir/getCMMAPstats.awk


if [ -e CMMAP.out ]; then
	#echo "CMMAPstats ..."
	awk -f $getCMMAPstats_awk CMMAP.out 
fi

