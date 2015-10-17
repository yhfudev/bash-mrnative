#! /bin/bash
#
# This is a shell script to get stats for a CM
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

# proc1.awk
proc1_awk=$scrdir/proc1.awk

if [ -e CMstats.out ]; then
	#echo "stats for a single CM ..."
	awk -f $proc1_awk CMstats.out
fi

