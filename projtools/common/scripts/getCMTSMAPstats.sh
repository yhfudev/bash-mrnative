#! /bin/bash
#
# This is a shell script to get CM stats
#
#
# Input file(s):
#
#	CMTSMAP.out
#
# Output file(s):
#

# Script directory
scrdir=`dirname $0`

# getCMTSMAPstats.awk
getCMTSMAPstats_awk=$scrdir/getCMTSMAPstats.awk


if [ -e CMTSMAP.out ]; then
	#echo "CMTSMAPstats ..."
	awk -f $getCMTSMAPstats_awk CMTSMAP.out
fi

