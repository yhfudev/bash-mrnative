#! /bin/bash
#
# This is a shell script to get CM stats
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

# getCMstats.awk
getCMstats_awk=$scrdir/getCMstats.awk

if [ -e CMstats.out ]; then
	#echo "CMstats ..."
	awk -f $getCMstats_awk CMstats.out
fi

