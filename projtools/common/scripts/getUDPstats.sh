#! /bin/bash
#
# This is a shell script to get UDP flows stats
#
#
# Input file(s):
#
#	UDPstats.out
#	IPTVUDPstats.out
#	DSUDPstats.out
#
# Output file(s):
#

# Script directory
scrdir=`dirname $0`

# getUDPstats.awk
getUDPstats_awk=$scrdir/getUDPstats.awk


if [ -e UDPstats.out ]; then
	echo "UDPstats ..."
	awk -f $getUDPstats_awk UDPstats.out 
fi

if [ -e IPTVUDPstats.out ]; then
	echo "IPTVUDPstats ..."
	awk -f $getUDPstats_awk IPTVUDPstats.out 
fi

if [ -e DSUDPstats.out ]; then
	echo "DSUDPstats ..."
	awk -f $getUDPstats_awk DSUDPstats.out 
fi

