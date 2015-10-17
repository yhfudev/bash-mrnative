# This file provides docsis cable network configuration information.

# Bonding group IDs
set BG0 0
set BG1 1
set BG2 2
set BG3 3
set BG4 4
set BG5 5
set BG6 6
set BG7 7
set BG8 8
set BG9 9
set BG10 10
set BG11 11
set BG12 12
set BG13 13
set BG14 14

# Configuration files
set curDir [pwd]
set CmBgUs "$curDir/CMBGUS.dat"
set CmBgDs "$curDir/CMBGDS.dat"
set BgProp "$curDir/BG.dat"
set ChProp "$curDir/channels.dat"

# Default DS / US channels for every node in the list
set defaultDSChannel 0	; # must be a DS channel defined in 'channels.dat'
set defaultUSChannel 10	; # must be a US channel defined in 'channels.dat'

# Debug switches
set TCL_DEBUG 0
set CM0_DEBUG		0	; # boolean flag to turn on/off debug of first CM node
set CM_DEBUG		0	; # boolean flag to turn on/off debug of CM nodes
set CM_BKOFF		1

# Flags
set CONCAT_FLAG 1
#set CONCAT_THRESHOLD 5
set CONCAT_THRESHOLD 50
set FRAG_FLAG 1
set PIGGYBACKING_FLAG 1

set NUMBER_CONTENTION_SLOTS 18
set NUMBER_MANAGEMENT_SLOTS 3

#WARNING: POWER OF 2!!!
set BKOFF_START 5
set BKOFF_END 8

#40 is enough to fit a full size IP packet
set MAP_LOOKAHEAD 255
set MAP_TIME .002
set MAP_FREQUENCY .002

# Scheduling class
set UGSSCHED 0
set RTPSSCHED 1
set BESCHED 2

#
# Upstream sched params
#
set USSchedMode $RR
#
set USSCHEDQType $FIFOQ
#set USSCHEDQSize 256
#set USSCHEDQSize 2048
set USSCHEDQSize 16384
set USSCHEDQDiscipline $USSchedMode
#
set USMinRate 0
set USMinLatency 0

#
# Downstream sched params
#
#set DSSchedMode $DRR
#set DSSchedMode $globalSCFQ
#set DSSchedMode $channelSCFQ
#set DSSchedMode $bestDRR
#set DSSchedMode $HDRR
#set DSSchedMode $HOSTBASED
#set DSSchedMode $TSNTS
#set DSSchedMode $FAIRSHARE
#set DSSchedModeFairshareParams "fairshare ExtendedHighConsumptionStateThreshold=0.95 MonitorPeriod=60 SubscriberProvisionedBW=12.0"
#set DSSchedModeFairshareParams "fairshare MonitorPeriod=10"
#set DSSchedModeFairshareParams "fairshare ExtendedHighConsumptionStateThreshold=0.80 ExtendedHighConsumptionStateExitThreshold=0.60 PriorityAllocation=0.95 Adaptive=1"
#set DSSchedModeFairshareParams "fairshare Adaptive=1"
set DSSchedMode $BROADBANDAQM
set DSSchedModeBROADBANDParams "BROADBANDAQM PriorityAllocation=0.95 MonitorPeriod=1 Multitier=1"
#
#set DSSCHEDQType $FIFOQ
#set DSSCHEDQType $RedQ
#set DSSCHEDQType $AdaptiveRedQ
#set DSSCHEDQType $DelayBasedRedQ
#set DSSCHEDQType $BAQM
set DSSCHEDQType $CoDelAQMQ
#
#set DSSCHEDQSize 1024	; # 2 queue of 1024
set DSSCHEDQSize  8192	; # 2 queue of 8192
#
set DSSCHEDQDiscipline $DSSchedMode
#set DSSCHEDQDiscipline 7
#set DSSCHEDQDiscipline 3
#
set DSMinRate 0
set DSMinLatency 0

# Flow mapping to packet flows (see common/packet.h)
set PT_TCP 0
set PT_UDP 1
set PT_CBR 2
set PT_ICMP  44
set PT_LOSS_MON 63
set PT_WILDCARD 255

# Flow IDs
set INACTIVE_FLOWID 0
set FLOWID_1 1
set FLOWID_2 2
set FLOWID_3 3

# Flow priority, quantum, and weight
set FlowPriorityLOW -1
set FlowPriority0 0
set FlowPriority1 1
set FlowPriority2 2
set FlowPriority3 3
set FlowPriority4 4
#
set FlowQuantum0  3000
set FlowQuantum1  2000
set FlowQuantum2  1020
set FlowQuantum3  1000
set FlowQuantum4  500
set FlowQuantum5  100
#
set FlowWeightLP  .01
set FlowWeightHP  .002
set FlowWeight1  1.0
set FlowWeight2  0.9
set FlowWeight3  0.7
set FlowWeight4  0.5
set FlowWeight5  0.3
set FlowWeight6  0.1
set FlowWeightT1  1.0
set FlowWeightT2  2.0
set FlowWeightT4  4.0

# ???
set MAXp 0.10

# ???
set AdaptiveMode 0

# ???
set PHS_SUPRESS_ALL   0
set PHS_SUPRESS_TCPIP 1
set PHS_SUPRESS_UDPIP 2
set PHS_SUPRESS_MAC   3
set PHS_NO_SUPRESSION 4

# Define this in bps to be for the cable/lan network
#
# This is with 8% for FEC
#set UPSPEED 200000000
#set UPSPEED 4710000
#set UPSPEED 5120000
set UPSPEED 10240000
#This assumes  1.6Mbhs channel, 16Qam
#set RAW_UPSPEED 5120000
#set RAW_UPSPEED 200000000
set RAW_UPSPEED 10240000
# DOCSIS2.0 raw speed 30.72Mbps assumes 64Qam, 6.4Mzh channel
#set UPSPEED 30720000
# adjust for 8%FEC
#set RAW_UPSPEED 28262400

# Adjust for 4.7%FEC
#set DOWNSPEED 200000000
#set RAW_DOWNSPEED 200000000
#set DOWNSPEED 30340000
#set RAW_DOWNSPEED 30340000
# DOCSIS 2.0 with 256 Qam 40.455528MBPS
#set DOWNSPEED 40455520
# and after FEC
#set RAW_DOWNSPEED 38554118
set DOWNSPEED 42880000
set RAW_DOWNSPEED 42880000

# Upstream rate control
set UPSTREAM_SID_QUEUE_SIZE 64
set UPSTREAM_RATE_CONTROL 0
#set UPSTREAM_SERVICE_RATE 2000000
set UPSTREAM_SERVICE_RATE 10000000

# Downstream rate control
set DOWNSTREAM_SID_QUEUE_SIZE 2048
#set DOWNSTREAM_SERVICE_RATE 10000000
set DOWNSTREAM_SERVICE_RATE 12000000
set DOWNSTREAM_RATE_CONTROL  0
set DOWNSTREAM_RATE_CONTROL_n1	$DOWNSTREAM_RATE_CONTROL
set DOWNSTREAM_RATE_CONTROL_f	$DOWNSTREAM_RATE_CONTROL
set DOWNSTREAM_RATE_CONTROL_l	$DOWNSTREAM_RATE_CONTROL

# Resequencing queues
set ReseqFlow 0
set ReseqWindow 1000
set ReseqTimeout .020

# Bucket length (in bits ... 2 packets)
set BUCKET_LENGTH 24448


