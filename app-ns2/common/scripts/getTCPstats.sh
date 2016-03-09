#! /bin/bash
#
# This is a shell script to get TCP flows stats
#
#
# Input file(s):
#
#	TCPstats.out
#	DSFTPTCPstats.out
#	VIDEOTCPstats.out
#	IPTVTCPstats.out
#	P2PTCPstats.out
#	DSP2PTCPstats.out
#	USP2PTCPstats.out
#
# Output file(s):
#

# Script directory
scrdir=`dirname $0`

# getTCPstats.awk
getTCPstats_awk=$scrdir/getTCPstats.awk

if [ -e TCPstats.out ]; then
	echo "TCPstats ...."
	awk -f $getTCPstats_awk TCPstats.out 
fi

if [ -e DSFTPTCPstats.out ]; then
	echo "DSFTPTCPstats ...."
	awk -f $getTCPstats_awk DSFTPTCPstats.out 
fi
if [ -e DSFTPTCPstatsT1.out ]; then
	echo "DSFTPTCPstatsT1 ...."
	awk -f $getTCPstats_awk DSFTPTCPstatsT1.out 
fi
if [ -e DSFTPTCPstatsT2.out ]; then
	echo "DSFTPTCPstatsT2 ...."
	awk -f $getTCPstats_awk DSFTPTCPstatsT2.out 
fi
if [ -e DSFTPTCPstatsT3.out ]; then
	echo "DSFTPTCPstatsT3 ...."
	awk -f $getTCPstats_awk DSFTPTCPstatsT3.out 
fi

if [ -e VIDEOTCPstats.out ]; then
	echo "VideoTCPstats ...."
	awk -f $getTCPstats_awk VIDEOTCPstats.out 
fi

if [ -e IPTVTCPstats.out ]; then
	echo "IPTVTCPstats ...."
	awk -f $getTCPstats_awk IPTVTCPstats.out 
fi

if [ -e P2PTCPstats.out ]; then
	echo "P2PTCPstats ...."
	awk -f $getTCPstats_awk P2PTCPstats.out 
fi

if [ -e DSP2PTCPstats.out ]; then
	echo "DP2PTCPstats ...."
	awk -f $getTCPstats_awk DSP2PTCPstats.out 
fi

if [ -e USP2PTCPstats.out ]; then
	echo "USP2PTCPstats ...."
	awk -f $getTCPstats_awk USP2PTCPstats.out 
fi


