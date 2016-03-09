#! /bin/bash
#
# This is a shell script to get bandwidth info of a simulation run
#
# Output files:
#
#	allBWstats.out
#	allTSBWstats.out	-- For TS flows only
#	allNTSBWstats.out	-- For NTS flows only
#

#echo "The script you are running has basename `basename $0`, dirname `dirname $0`"
#echo "The present working directory is `pwd`"

# Script directory
scrdir=`dirname $0`

# truncate output files to zero length
#truncate --size=0 allBWstats.out
:>allBWstats.out
#truncate --size=0 allTSBWstats.out
:>allTSBWstats.out
#truncate --size=0 allNTSBWstats.out
:>allNTSBWstats.out

# Get average web flow bandwidth
$scrdir/getAvgWebBW.sh >> allBWstats.out
$scrdir/getAvgWebBW.sh >> allTSBWstats.out

# Copy TCP stats
if [ -e TCPstats.out ]; then
	cat TCPstats.out >> allBWstats.out
	cat TCPstats.out >> allTSBWstats.out
fi

# Copy video stream stats
if [ -e VIDEOTCPstats.out ]; then
	cat VIDEOTCPstats.out >> allBWstats.out
	cat VIDEOTCPstats.out >> allTSBWstats.out
fi

# Copy downstream FTP stats
if [ -e DSFTPTCPstats.out ]; then
	cat DSFTPTCPstats.out >> allBWstats.out
	cat DSFTPTCPstats.out >> allNTSBWstats.out
fi
if [ -e DSFTPTCPstatsT1.out ]; then
	cat DSFTPTCPstatsT1.out >> allBWstats.out
	cat DSFTPTCPstatsT1.out >> allNTSBWstats.out
fi
if [ -e DSFTPTCPstatsT2.out ]; then
	cat DSFTPTCPstatsT2.out >> allBWstats.out
	cat DSFTPTCPstatsT2.out >> allNTSBWstats.out
fi
if [ -e DSFTPTCPstatsT3.out ]; then
	cat DSFTPTCPstatsT3.out >> allBWstats.out
	cat DSFTPTCPstatsT3.out >> allNTSBWstats.out
fi

# Copy downstream P2P stream stats
if [ -e DSP2PTCPstats.out ]; then
	cat DSP2PTCPstats.out >> allBWstats.out
	cat DSP2PTCPstats.out >> allNTSBWstats.out
fi

# Copy UDP stats
if [ -e UDPstats.out ]; then
	awk -f $scrdir/udp2tcpstats.awk UDPstats.out >> allBWstats.out
	awk -f $scrdir/udp2tcpstats.awk UDPstats.out >> allTSBWstats.out
fi
if [ -e DSUDPstats.out ]; then
	awk -f $scrdir/udp2tcpstats.awk DSUDPstats.out >> allBWstats.out
	awk -f $scrdir/udp2tcpstats.awk DSUDPstats.out >> allTSBWstats.out
fi

