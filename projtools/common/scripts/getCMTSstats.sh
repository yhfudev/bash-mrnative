#! /bin/bash
#
# This is a shell script to get CMTS stats
#
#
# Input file(s):
#
#	CMTSstats.out
#
# Output file(s):
#

# Script directory
scrdir=`dirname $0`

# getCMTSstats.awk
getCMTSstats_awk=$scrdir/getCMTSstats.awk

if [ -e CMTSstats.out ]; then
	#echo "CMTSstats ..."
	awk -f $getCMTSstats_awk CMTSstats.out
fi

