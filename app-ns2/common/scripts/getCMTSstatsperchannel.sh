#! /bin/bash
#
# This is a shell script to get CMTS stats per channel
#
#
# Input file(s):
#
#	CMTSstatsperchannel.out
#
# Output file(s):
#

# Script directory
scrdir=`dirname $0`

# getCMTSstatsperchannel.awk
getCMTSstatsperchannel_awk=$scrdir/getCMTSstatsperchannel.awk

if [ -e CMTSstatsperchannel.out ]; then
	#echo "CMTSstatsperchannel ..."
	awk -f $getCMTSstatsperchannel_awk CMTSstatsperchannel.out
fi

