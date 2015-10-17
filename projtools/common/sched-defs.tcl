# Scheduling queue types
# Note: must agree with simsched.tcl and C++ code in globalDefines.h
set FIFOQ		0
set OrderedQ		1
set RedQ		2
set BlueQ		3
set AdaptiveRedQ	4
set DelayBasedRedQ	5
set AQM3Q		6
set BAQMQ		10
set FSAQMQ              12
set CoDelAQMQ		13
set PIEAQMQ		14
set SFQCoDelQ		16
set PBCoDelQ		17

# Scheduling disciplines
set FCFS		0
set RR			1
set WRR			2
set DRR			3
set SCFQ		4
set WFQ			5
set W2FQ		6

set HDRR		16
set HOSTBASED		17
set TSNTS		18
set FAIRSHARE		19
set BROADBANDAQM	21

set globalDRR		32
set channelDRR		33
set bondingGroupDRR	34
set bestDRR		35

set globalSCFQ		64
set channelSCFQ		65
set bondingGroupSCFQ	66
set bestSCFQ		67

set TSFQ		68

set DS3SM_DS_PF   70

# TS/NTS
set PRIORITY_HIGH 0
set PRIORITY_LOW 1

# FAIRSHARE
set PRIORITY_WELL_BEHAVED 0
set PRIORITY_NOT_WELL_BEHAVED 1


