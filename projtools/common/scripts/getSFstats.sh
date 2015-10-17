#! /bin/bash
#
# This is a shell script to get service flow stats
#
#
# Input file(s):
#
#	DSSIDstats.out
#
# Output file(s):
#

# Script directory
scrdir=`dirname $0`

# getSFstats.awk
getSFstats_awk=$scrdir/getSFstats.awk

# getBGSFstats.awk
getBGSFstats_awk=$scrdir/getBGSFstats.awk


if [ -e DSSIDstats.out ]; then
	echo "SF stats"

	#$1: the BG to examine , 1000 indicates look at all BG
	#$2: If not zero, then look at BGs in the range Param2 through Param3
	# param1:BGID of interest
	# param2:BGID range start 
	# param3:BGID range stop
	#awk -v Param1=$1 -v Param2=$2 -v Param3=$3 -f getSFstats.awk DSSIDstats.out
	awk -v Param1=0 -v Param2=0 -v Param3=0 -f $getBGSFstats_awk DSSIDstats.out
	awk -v Param1=1 -v Param2=0 -v Param3=0 -f $getBGSFstats_awk DSSIDstats.out
	awk -v Param1=2 -v Param2=0 -v Param3=0 -f $getBGSFstats_awk DSSIDstats.out
	awk -v Param1=3 -v Param2=0 -v Param3=0 -f $getBGSFstats_awk DSSIDstats.out
	awk -v Param1=4 -v Param2=0 -v Param3=0 -f $getBGSFstats_awk DSSIDstats.out
	awk -v Param1=5 -v Param2=0 -v Param3=0 -f $getBGSFstats_awk DSSIDstats.out
	awk -v Param1=6 -v Param2=0 -v Param3=0 -f $getBGSFstats_awk DSSIDstats.out
	awk -v Param1=7 -v Param2=0 -v Param3=0 -f $getBGSFstats_awk DSSIDstats.out
	awk -v Param1=8 -v Param2=0 -v Param3=0 -f $getBGSFstats_awk DSSIDstats.out
	awk -v Param1=9 -v Param2=0 -v Param3=0 -f $getBGSFstats_awk DSSIDstats.out

fi


