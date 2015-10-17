#
# This script is intended for simulation configuration settings.
# It should be sourced the last from the main script so that
# any settings here will be final by overwrite any other settings
# from other sourced scripts.
#

# Simulation timeline
set starttime	0.0
set starttime1	[expr $starttime + 0.001]
set stoptime	1000.5
#set printtime	[expr $stoptime - .000001]
set printtime 	[expr $stoptime - .00000001]

# Bad guy UDP flow
#set BADGUY_UDP_FLOWS_START_TIME	100
#set BADGUY_UDP_FLOWS_STOP_TIME  300

# Number of CMs (not including monitor CM)
set NUM_FTPs	10
set NUM_DASHs	0
set NUM_WEBs	0
set NUM_UDPs	0
set NUM_CM      [expr $NUM_FTPs + $NUM_DASHs + $NUM_WEBs + $NUM_UDPs]

#
# Application traffic selection
#

# ???
set CMBKSCALE 1

# PING monitor flow on/off
set PING_MONITOR_ON     1

# UDP monitor flow type:
#	this variable sets the details of the UDP flow
#	attached to the 'n1' monitor CM
#
#  Value:0 no UDP monitor
#  Value:1 CBR traffic source to a UGS service flow
#  Value:2 CBR traffic source to the default BE service flow
#  Value:3 CBR traffic source to a VBR service flow
set UDP_MONITOR_TYPE    0

# LOSS monitor flow on/off
set LOSS_MONITOR_ON 1
set LOSS_MONITOR_DS 1
set LOSS_MONITOR_US 1

# TCP/UDP throughput monitor on/off
set TCPUDP_THROUGHPUT_MONITORS_ON 0
set THROUGHPUT_MONITOR_INTERVAL 30.0

# TCP or UDP?
#  (0: TCP, 1: UDP)
set ALL_UDP             0

# Traffic type
set EXPONENTIAL_TRAFFIC_MODE    0
set CBR_TRAFFIC_MODE            1
set FTP_TRAFFIC_MODE            2
set PARETO_TRAFFIC_MODE         3
set TRAFFIC_TYPE                $CBR_TRAFFIC_MODE
if {$ALL_UDP == 0} {
        # If TCP, change traffic type to FTP
        set TRAFFIC_TYPE $FTP_TRAFFIC_MODE
}

# Traffic direction (0: upstream, 1: downstream)
set TRAFFIC_DIRECTION           1

#
# flow settings
#

# Path RTT (one of the following or none)
#set RANDOM_FTP_PATH_RTT		1
#set SAME_FTP_PATH_RTT			1
set VAR_FTP_PATH_RTT			1

# Link queue buffer size
set DEFAULT_BUFFER_CAPACITY	4096

# Priority
set PRIORITY_HIGH 0
set PRIORITY_LOW 1
set FLOW_PRIORITY $PRIORITY_LOW

# Packet Size
set PACKETSIZE 1000
if {$ALL_UDP == 0} {
        # If TCP, change packet size
        set PACKETSIZE  1460
}

#
# TCP Protocol ID
#       1: Reno
#       2: Newreno
#       3: Vegas (CAM only)
#       7: ECN
#       8: Full TCP
#	9: TCP Sack
set TCP_PROT_ID 9

# Window size
#set WINDOW 512
set WINDOW 1000
#set WINDOW 685
#set WINDOW 100
#set WINDOW 44

# Burst
set BURSTTIME   .08
#set BURSTTIME  .008
set IDLETIME    .5
set BURSTRATE   10000000
set SHAPE       0

# Interval and data rate
#       1000 bytes and .008 seconds is 1 mbps
#       1000 bytes and .004 seconds is 2 mbps
#       1000 bytes and .002 seconds is 4 mbps
#       1000 bytes and .0008 seconds is 10 mbps
#       1000 bytes and .0004 seconds is 20 mbps
#       1000 bytes and .0003 seconds is 26.7 mbps
#       1000 bytes and .0002 seconds is 40 mbps
#       1000 bytes and .0001 seconds is 80 mbps
#       1460 bytes at .04 = 292,000 bps
# 4.0Mbps
#set INTERVAL .002
# 12.0Mbps
set INTERVAL .000666666
#set CBR_INTERVAL               $INTERVAL
#
set GOOD_TARGET_VIDEO_RATE       50000000.0
set BAD_TARGET_VIDEO_RATE       100000000.0
set TARGET_VIDEO_RATE            12000000.0
#set CBR_INTERVAL                [expr 8.0 * $PACKETSIZE / $TARGET_VIDEO_RATE]
set CBR_INTERVAL		$INTERVAL

#set MYSEED 304320221
set MYSEED 973272912
#if 0, ns seeds each run
set MYWEBSEED 2125204119
#set MYSEED 0

