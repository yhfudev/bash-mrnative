#! /bin/bash
#
# This is a shell script to get CM concatenation stats
#
#
# Input file(s):
#
#	CMstats.out
#
# Output file(s):
#

# Script directory
scrdir=`dirname $0`

# getCMConcatstats.awk
getCMConcatstats_awk=$scrdir/getCMConcatstats.awk


if [ -e CMstats.out ]; then
	#echo "CMConcatstats ..."
	awk -f $getCMConcatstats_awk CMstats.out 
fi

