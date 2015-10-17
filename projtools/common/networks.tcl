# Create a basic cable network topology (adding routers 
#                                        and any ftp servers
#                                        and any dash servers
#					 and any web servers)
#
# 	n2 -------- n0 ------------- n1
#            1Gbps       Cable Net   CM(1)
#            0.5ms                   CM(2)
#
# WARNING - BE EXTREMELY CAREFUL ABOUT THE CONSISTENCY AMONG:
#
#	Configuration files (channels.dat, BG.dat, CMBGUS.dat, CMBGUS.dat)
#       Node default upstream configure ($lan configure-defaultup ...)
#	Node default downstream configure ($lan configure-defaultdown ...)
#
# How this cable network is configured?
#
#	Cable Net is created with -
#		Default DS channel: 0
#		Default US channel: 10
#
#	Default upstream flow for n1, CM(1), CM(2) ...
#		is set to use BG2, which is set to channel 8 in BG.dat
#
#	Default downstream flow for n1, CM(1), CM(2) ...
#		is set to use BG1, which is set to channel 1 in BG.dat
#
proc create_cable_topology_1G { nFTPsvrs nDASHsvrs nWEBsvrs NUM_CM delay2 } {
	puts "nFTPsvrs = $nFTPsvrs"
	puts "nDASHsvrs = $nDASHsvrs"
	puts "nWEBsvrs = $nWEBsvrs"
	puts "NUM_CM = $NUM_CM"

	#values are 1 - 7 - see preliminary results 1.1 
	set SCENARIO	1

	# global variables this proc relies on
	global ns		; # ns simulator object
	
	# global variables for BGs
	global BG1
	global BG2
	
	#
	global UDP_MONITOR_TYPE

	# global variables for make-docsislan call
	global defaultDSChannel defaultUSChannel
	global CmBgDs CmBgUs BgProp ChProp
	global TCL_DEBUG CM0_DEBUG CM_DEBUG CM_BKOFF
	
	# global variables for configure-defaultup / config-defaultdown
	global BESCHED PT_WILDCARD INACTIVE_FLOWID PHS_NO_SUPRESSION
	global FRAG_FLAG CONCAT_FLAG CONCAT_THRESHOLD PIGGYBACKING_FLAG
	global UPSTREAM_SID_QUEUE_SIZE UPSTREAM_RATE_CONTROL UPSTREAM_SERVICE_RATE USSCHEDQType USSCHEDQSize USSCHEDQDiscipline
	global DOWNSTREAM_RATE_CONTROL DOWNSTREAM_SERVICE_RATE DOWNSTREAM_SID_QUEUE_SIZE BUCKET_LENGTH DSSCHEDQType DSSCHEDQSize DSSCHEDQDiscipline
	global DOWNSTREAM_RATE_CONTROL_n1 DOWNSTREAM_RATE_CONTROL_f DOWNSTREAM_RATE_CONTROL_l
	global FlowPriority0 FlowQuantum2 FlowWeight1 MAXp AdaptiveMode USMinRate USMinLatency DSMinRate DSMinLatency ReseqFlow ReseqWindow ReseqTimeout
	
	# global variables for CMTS configuration
	global MAP_TIME MAP_FREQUENCY NUMBER_MANAGEMENT_SLOTS NUMBER_CONTENTION_SLOTS 55 66 BKOFF_START BKOFF_END 0.5 MAP_LOOKAHEAD
	
	# global variables for scheduler-related stuff
	global DSSchedMode DSSCHEDQSize DSSCHEDQType
	global USSchedMode USSCHEDQSize USSCHEDQType
	global FAIRSHARE
	
	#
	global RANDOM_FTP_PATH_RTT SAME_FTP_PATH_RTT VAR_FTP_PATH_RTT
	global DEFAULT_BUFFER_CAPACITY
	
	#
	global RAW_DOWNSPEED RAW_UPSPEED
	
	# global variables for timelines
	global printtime stoptime
	
	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY
	
	# global variables this proc generates
	global n0 n1 n2 n4 n5	; # wired nodes
	global ftp_server
	global dash_server
	global web_server
	global CM		; # CM nodes
	global CMnodelist	; # list of CM nodes (CMTS, Monitor CM, other CM nodes)
	global lan		; # cable network object
	
	# path queue size
	set PATH_QSIZE		$DEFAULT_BUFFER_CAPACITY

	# Create nodes
	set n0 [$ns node]	; # used as CMTS
	set n1 [$ns node]	; # used as special monitor CM
	set n2 [$ns node]	; # special wired test node
	set n4 [$ns node]
	set n5 [$ns node]
	
	# Create two routers
	set midRouter [$ns node]
	set endRouter [$ns node]
	
	# Create two edge routers
	set ftpRouter [$ns node]
	set dashRouter [$ns node]
	set webRouter [$ns node]

	# Create specified number of ftp server nodes
	for {set i 1} {$i <= $nFTPsvrs} {incr i} {
		set ftp_server($i)	[$ns node]
	}
	
	# Create specified number of dash server nodes
	for {set i 1} {$i <= $nDASHsvrs} {incr i} {
		set dash_server($i)	[$ns node]
	}
	
	# Create specified number of web server nodes
	for {set i 1} {$i <= $nWEBsvrs} {incr i} {
		set web_server($i)	[$ns node]
	}
	
	# Set link: midRouter ----- n0 (CMTS)
	#	speed, delay, drop policy
	$ns simplex-link $midRouter $n0 10000Mb 1ms DropTail	; # 10Gbps
	$ns simplex-link $n0 $midRouter 10000Mb 1ms DropTail	; # 10Gbps
	$ns queue-limit $midRouter $n0 $PATH_QSIZE 
	$ns queue-limit $n0 $midRouter $PATH_QSIZE
	
	# Set link: midRouter ----- endRouter
	#	speed, delay, drop policy
	$ns simplex-link $midRouter $endRouter 10000Mb ${delay2}ms DropTail	; # 10Gbps
	$ns simplex-link $endRouter $midRouter 10000Mb ${delay2}ms DropTail	; # 10Gbps
	$ns queue-limit $midRouter $endRouter $PATH_QSIZE 
	$ns queue-limit $endRouter $midRouter $PATH_QSIZE

	#Adjust the prop delay to make it be 60ms rtt
	#for this model, make it 1.5mbps (a T1 link)
	#$ns duplex-link $n0 $n2 1.5Mb 24ms DropTail

	# Set link: n2 ----- endRouter
	#	speed, delay, drop policy
	$ns simplex-link $n2 $endRouter 1000Mb 32ms DropTail	; # 1Gbps
	$ns simplex-link $endRouter $n2 1000Mb 32ms DropTail	; # 1Gbps
	$ns queue-limit $n2 $endRouter $PATH_QSIZE
	$ns queue-limit $endRouter $n2 $PATH_QSIZE
	
	# Add a loss module on the link: n2 ------ endRouter
	#	......
	set loss_modulexnet [new ErrorModel]
	$loss_modulexnet set errModelId 2
	$loss_modulexnet set rate_ 0.0
	#$loss_modulexnet set rate_ 0.01	; 1%
	$loss_modulexnet unit pkt
	$loss_modulexnet ranvar [new RandomVariable/Uniform]
	$loss_modulexnet drop-target [new Agent/Null]
	$ns lossmodel $loss_modulexnet $endRouter $n2
	
	# Link n4 and n5 to endRouter
	#
	$ns duplex-link $endRouter $n4 1000Mb 24ms DropTail	; # 1Gbps
	$ns queue-limit $endRouter $n4 $PATH_QSIZE
	$ns queue-limit $n4 $endRouter $PATH_QSIZE
	$ns duplex-link $endRouter $n5 1000Mb 24ms DropTail	; # 1Gbps
	$ns queue-limit $endRouter $n5 $PATH_QSIZE
	$ns queue-limit $n5 $endRouter $PATH_QSIZE
	
	# Link edge routers to endRouter
	#
	$ns duplex-link $endRouter $ftpRouter 10000Mb 2ms DropTail	; # 10Gbps
	$ns queue-limit $endRouter $ftpRouter $PATH_QSIZE
	$ns queue-limit $ftpRouter $endRouter $PATH_QSIZE
	$ns duplex-link $endRouter $dashRouter 10000Mb 2ms DropTail	; # 10Gbps
	$ns queue-limit $endRouter $dashRouter $PATH_QSIZE
	$ns queue-limit $dashRouter $endRouter $PATH_QSIZE
	$ns duplex-link $endRouter $webRouter 10000Mb 2ms DropTail	; # 10Gbps
	$ns queue-limit $endRouter $webRouter $PATH_QSIZE
	$ns queue-limit $webRouter $endRouter $PATH_QSIZE

	# Link from ftp server to ftpRouter
	set PATH_RTT	0.030	; # 30ms
	set QSIZE	$PATH_QSIZE
	set LSDS 1000000000	; # 1000Mb
	set LSUS 1000000000	; # 1000Mb
    if { [info exists RANDOM_FTP_PATH_RTT] } {
    	# random path delay
	for {set i 1} {$i <= $nFTPsvrs} {incr i} {
		if { $RANDOM_FTP_PATH_RTT == 1 } {
    		set delay [uniform 0.002 0.070]
    		puts "Random FTP path RTT enabled - $delay!"
    		} else {
    		set delay $PATH_RTT
    		puts "No - random FTP path RTT is off - $delay."
    		}
    		$ns simplex-link $ftpRouter $ftp_server($i) $LSUS $delay DropTail
    		$ns simplex-link $ftp_server($i) $ftpRouter $LSDS $delay DropTail
		$ns queue-limit $ftpRouter $ftp_server($i) $QSIZE
		$ns queue-limit $ftp_server($i) $ftpRouter $QSIZE
    	}
    } elseif { [info exists SAME_FTP_PATH_RTT] } {
	# same path delay
	for {set i 1} {$i <= $nFTPsvrs} {incr i} {
		puts "Same FTP path RTT always - $PATH_RTT."
    		$ns simplex-link $ftpRouter $ftp_server($i) $LSUS $PATH_RTT DropTail
    		$ns simplex-link $ftp_server($i) $ftpRouter $LSDS $PATH_RTT DropTail
		$ns queue-limit $ftpRouter $ftp_server($i) $QSIZE
		$ns queue-limit $ftp_server($i) $ftpRouter $QSIZE
    	}
    } elseif { [info exists VAR_FTP_PATH_RTT] } {
    	# varied path delay
	puts "Varied FTP path RTT from ??ms to ??ms for $nFTPsvrs ftps."
	set ddd 0
	set qqq 0
	for {set i 1} {$i <= $nFTPsvrs} {incr i} {
		incr qqq
		if { [expr $qqq % 2] } {
			set delay [expr $PATH_RTT + $ddd / 1000.0]
		} else {
			set delay [expr $PATH_RTT - $ddd / 1000.0]
		}
		puts "Varied FTP path delay $i = $delay!"
    		$ns simplex-link $ftpRouter $ftp_server($i) $LSUS $delay DropTail
    		$ns simplex-link $ftp_server($i) $ftpRouter $LSDS $delay DropTail
		$ns queue-limit $ftpRouter $ftp_server($i) $QSIZE
		$ns queue-limit $ftp_server($i) $ftpRouter $QSIZE
		if { [expr $qqq % 2] } {
			set ddd [expr $ddd + 5]
			if { $ddd == 30 } {
				set ddd 0
				set qqq 0
			}
		}
    	}
    } else {
	# explicitly specified varied path delay
	puts "Explicitly specified varied FTP path RTT."
	$ns duplex-link $ftpRouter $ftp_server(1) $LSDS 5ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(2) $LSDS 10ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(3) $LSDS 15ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(4) $LSDS 20ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(5) $LSDS 25ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(6) $LSDS 30ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(7) $LSDS 35ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(8) $LSDS 40ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(9) $LSDS 45ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(10) $LSDS 50ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(11) $LSDS 55ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(12) $LSDS 60ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(13) $LSDS 65ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(14) $LSDS 70ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(15) $LSDS 75ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(16) $LSDS 80ms DropTail
	puts "Error!"
	exit 1
    }

	# Link from dash server to dashRouter
    if { [info exists SAME_FTP_PATH_RTT] } {
	# same path delay
	for {set i 1} {$i <= $nDASHsvrs} {incr i} {
		puts "Same DASH path RTT always - $PATH_RTT."
    		$ns simplex-link $dashRouter $dash_server($i) $LSUS $PATH_RTT DropTail
    		$ns simplex-link $dash_server($i) $dashRouter $LSDS $PATH_RTT DropTail
		$ns queue-limit $dashRouter $dash_server($i) $QSIZE
		$ns queue-limit $dash_server($i) $dashRouter $QSIZE
    	}
    } else {
	# varied path delay
	set delay 5
	for {set i 1} {$i <= $nDASHsvrs} {incr i} {
		puts "Varied DASH path delay $i = $delay!"

		$ns simplex-link $dashRouter $dash_server($i) $LSUS ${delay}ms DropTail
		$ns simplex-link $dash_server($i) $dashRouter $LSDS ${delay}ms DropTail
		$ns queue-limit $dashRouter $dash_server($i) $QSIZE
		$ns queue-limit $dash_server($i) $dashRouter $QSIZE
	
		set delay [expr $delay + 5]
	}
    }

	# Link from web server to webRouter

	# Build cable network node list (...)
	lappend CMnodelist $n0		; # first must be CMTS nodes
	lappend CMnodelist $n1		; # first CM node in the list
					; # neither n0 or n1 are in the CM array
	for {set i 1} {$i <= $NUM_CM} {incr i} {
		set CM($i) [$ns node]	; # create CM node
		lappend CMnodelist $CM($i)
	}

	#
	# Create the DOCSIS cable network with the nodes in 'CMnodelist'
	#
	set lan [$ns make-docsislan $CMnodelist $defaultDSChannel $defaultUSChannel 2ms LL $CmBgDs $CmBgUs $BgProp $ChProp $TCL_DEBUG]

	# Configure CMs with these parameters
	#	<node> <priority> rng_msg_interval status_msg_freq
	#       <debug on/off> cm_backoff_scale
	$lan configure-cm $n1 1 1.0 200.0 $CM0_DEBUG $CM_BKOFF
	for {set i 1} {$i <= $NUM_CM} {incr i} {
		$lan configure-cm $CM($i) 1 1.0 200.0 $CM_DEBUG $CM_BKOFF
	}

	# Configure default upstream flows with these parameters:
	#	<node> <flow params>
	# where <flow params> is a string of these fields (see vlan.tcl for details)
	#	f0: sched type
	#	f1: src node	(old: ??)
	#	f2: dst node	(old: pkt type)
	#	f3: flow type
	#	f4: flow ID
	#	f5: phs
	#	f6: bg		<=== this specifies which US bonding group to use
	#	f7: frag
	#	f8: concat flag
	#	f9: concat threshold
	#	f10: piggybacking
	#	f11:
	#	f12:
	#	f13: queue size
	#	f14: debug on/off
	#	f15: upstream rate control
	#	f16: upstream rate
	#	f17: upstream sched queue type
	#	f18: upstream sched queue size
	#	f19: upstream sched queue discipline
	#	f20: flow priority
	#	f21: flow quantum
	#	f22: flow weight
	#	f23: max p
	#	f24: adaptive mode
	#	f25: upstream min rate
	#	f26: upstream min latency
	puts "<<<<< Configure default upstream on BG2 for monitor CM n1"
	$lan configure-defaultup $n1 "$BESCHED $n1 $n2 $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG2 $FRAG_FLAG $CONCAT_FLAG $CONCAT_THRESHOLD $PIGGYBACKING_FLAG 0 0 $UPSTREAM_SID_QUEUE_SIZE $CM0_DEBUG $UPSTREAM_RATE_CONTROL $UPSTREAM_SERVICE_RATE $USSCHEDQType $USSCHEDQSize $USSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $USMinRate $USMinLatency"
	for {set i 1} {$i <= $NUM_CM} {incr i} {
		puts "<<<<< Configure default upstream on BG2 for CM $i"
		$lan configure-defaultup $CM($i) "$BESCHED $CM($i) $n2 $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG2 $FRAG_FLAG $CONCAT_FLAG $CONCAT_THRESHOLD $PIGGYBACKING_FLAG 0 0 $UPSTREAM_SID_QUEUE_SIZE $CM_DEBUG $UPSTREAM_RATE_CONTROL $UPSTREAM_SERVICE_RATE $USSCHEDQType $USSCHEDQSize $USSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $USMinRate $USMinLatency"
	}
	
	# optional upstream code missing here ...
	if { $UDP_MONITOR_TYPE == 1 } {
		puts "UGS flow code missing!"
		exit 0
	}
	if { $UDP_MONITOR_TYPE == 3 } {
		puts "VBR flow code missing"
		exit 0
	}

	# Configure default downstream flows with these parameters:
	#	<node> <flow params>
	# where <flow params> is a string of these fields (see vlan.tcl for details)
	#	f0: src node	(old: ??)
	#	f1: dst node	(old: pkt type)
	#	f2: flow type
	#	f3: flow ID
	#	f4: phs
	#	f5: bg		<=== this specifies which DS bonding group to use
	#	f6: downstream rate control
	#	f7: downstream rate
	#	f8: downstream queue size
	#	f9: bucket length
	#	f10: downstream sched type
	#	f11: downstream sched queue size
	#	f12: downstream sched queue discipline
	#	f13: flow priority
	#	f14: flow quantum
	#	f15: flow weight
	#	f16: max p
	#	f17: adaptive mode
	#	f18: downstream min rate
	#	f19: downstream min latency
	#	f20: reseq flag
	#	f21: reseq window
	#	f22: reseq timeout
	puts ">>>>> Configure default downstream on BG1 for monitor CM n1"
	$lan configure-defaultdown $n1 "$n2 $n1 $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG1 $DOWNSTREAM_RATE_CONTROL_n1 $DOWNSTREAM_SERVICE_RATE $DOWNSTREAM_SID_QUEUE_SIZE $BUCKET_LENGTH $DSSCHEDQType $DSSCHEDQSize $DSSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $DSMinRate $DSMinLatency $ReseqFlow $ReseqWindow $ReseqTimeout"

	for {set i 1} {$i <= $NUM_CM} {incr i} {
	#	puts ">>>>> Configure default downstream for CM $i"

		if {$SCENARIO == 1} {
			puts ">>>>> Configure default downstream #$i on BG #$BG1 for CM #$i"
			if {$i == 1} {
				# WARNING: original code has "$n2 $n1 ..." <-- n1 looks like a cut-and-paste bug
				$lan configure-defaultdown $CM($i) "$n2 $CM($i) $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG1 $DOWNSTREAM_RATE_CONTROL_f $DOWNSTREAM_SERVICE_RATE $DOWNSTREAM_SID_QUEUE_SIZE $BUCKET_LENGTH $DSSCHEDQType $DSSCHEDQSize $DSSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $DSMinRate $DSMinLatency $ReseqFlow $ReseqWindow $ReseqTimeout"
				# to make this stream high priority, use $FlowPriority1
			} elseif {$i == $NUM_CM} {
				# WARNING: original code has "$n2 $n1 ..." <-- n1 looks like a cut-and-paste bug
				$lan configure-defaultdown $CM($i) "$n2 $CM($i) $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG1 $DOWNSTREAM_RATE_CONTROL_l $DOWNSTREAM_SERVICE_RATE $DOWNSTREAM_SID_QUEUE_SIZE $BUCKET_LENGTH $DSSCHEDQType $DSSCHEDQSize $DSSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $DSMinRate $DSMinLatency $ReseqFlow $ReseqWindow $ReseqTimeout"
			} else {
				# WARNING: original code has "$n2 $n1 ..." <-- n1 looks like a cut-and-paste bug
				$lan configure-defaultdown $CM($i) "$n2 $CM($i) $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG1 $DOWNSTREAM_RATE_CONTROL $DOWNSTREAM_SERVICE_RATE $DOWNSTREAM_SID_QUEUE_SIZE $BUCKET_LENGTH $DSSCHEDQType $DSSCHEDQSize $DSSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $DSMinRate $DSMinLatency $ReseqFlow $ReseqWindow $ReseqTimeout"
			}
		}
		
		if {$SCENARIO == 7} {
			puts "Code missing!"
			exit 0
		}

	}

	#
	# Configure CMTS (n0)
	#
	puts "Configure CMTS (n0) ......"
	#
	# Management params (see vlan.tcl and mac/configMgr.cc)
	#	cmts_node, sync_msg_interval, rng_msg_interval, ucd_msg_interval
	$lan configure-mgmtparams $n0 2.0 1.0 3.0
	#
	# Map params (see vlan.tcl and mac/configMgr.cc)
	#	cmts_node, time_covered, map_interval, num_contention_slots, num_sm_slots,
	#	short_grant_limit, long_grant_limit, bkoff_start, bkoff_end,
	#	proportion, MAP_LOOKAHEAD
	$lan configure-mapparams $n0 $MAP_TIME $MAP_FREQUENCY $NUMBER_MANAGEMENT_SLOTS $NUMBER_CONTENTION_SLOTS 55 66 $BKOFF_START $BKOFF_END 0.5 $MAP_LOOKAHEAD
	#
	puts "Configuring DS scheduler to mode $DSSchedMode ..."
	$lan configure-DSScheduler $n0 $DSSchedMode $DSSCHEDQSize $DSSCHEDQType
	puts "Configuring US scheduler to mode $USSchedMode ..."
	$lan configure-USScheduler $n0 $USSchedMode $USSCHEDQSize $USSCHEDQType
	#
	# if sched mode is fairshare, make sure all priorities set to 0
	if {$DSSchedMode == $FAIRSHARE} {
		set PRIORITY_HIGH 0
		set PRIORITY_LOW 0
		set FLOW_PRIORITY $PRIORITY_HIGH
	}
	#
	puts "Done configuring CMTS."

	#
	# Trace CM bandwidth
	#    Params: mac ns CMnode interval filename
	#
	# For monitor CM
	TraceCMBW $lan $ns $n1 2.0 CM-BW-n1.out
	$ns at $printtime "dumpCMStats $lan $ns $n1 CMstats.out"
	# For other CMs
	for {set i 1} {$i <= $NUM_CM} {incr i} {
		set outfilename "CM-BW-CM[expr $i + 0].out"
		TraceCMBW $lan $ns $CM($i) 1.0 $outfilename
		$ns at $printtime "dumpCMStats $lan $ns $CM($i) CMstats.out"
	}

	#
	# Trace CMTS throughput
	#    Params: mac ns CMTSnode interval filename
	#
	#    Note: this calls dumpBWCMTS which also calls dumpUGSJitter creating
	#          entries in UGSJitterCMTS.out
	#
	#    Note: dumpCMTSStats produces "DSSIDstats.out"
	#
	TraceCMTSBW $lan $ns $n0 1.0 CMTS-BW.out
	$ns at $stoptime "dumpCMTSStats $lan $ns $n0 CMTSstats.out"
	
	#
	# Trace DOCSIS downstream and upstream queues
	#
	# CMTS
	TraceDOCSISQueue $lan $ns $n0 1 CMTS-DS-QUEUE.out
	#
	# CM
	#set NUM_FLOWS $NUM_CM
	if { $NUM_CM > 0 } {
		TraceDOCSISQueue $lan $ns $CM(1) 1 CMQUEUE.out
	} else {
		TraceDOCSISQueue $lan $ns $n1 1 CMQUEUE.out
	}

	# Trace the DS and US utilization as observed by the CMTS
	TraceDOCSISUtilization $lan $ns $n0 1.0 CMTS-DS-util.out $RAW_DOWNSPEED $RAW_UPSPEED

	# Start the simulation (starts the registration phase)
	puts "Start DOCSIS LAN simulation now ......"
	$lan startsim

	puts "Basic cable topology with additional routers and ftp servers created!"
}

proc create_cable_topology_1G_tiers { NUM_LCM NUM_MCM NUM_HCM NUM_UCM delay2 } {
	puts "NUM_LCM = $NUM_LCM"
	puts "NUM_MCM = $NUM_MCM"
	puts "NUM_HCM = $NUM_HCM"

	#values are 1 - 7 - see preliminary results 1.1 
	set SCENARIO	1

	# global variables this proc relies on
	global ns		; # ns simulator object
	
	# global variables for BGs
	global BG1
	global BG2
	
	#
	global UDP_MONITOR_TYPE

	# global variables for make-docsislan call
	global defaultDSChannel defaultUSChannel
	global CmBgDs CmBgUs BgProp ChProp
	global TCL_DEBUG CM0_DEBUG CM_DEBUG CM_BKOFF
	
	# global variables for configure-defaultup / config-defaultdown
	global BESCHED PT_WILDCARD INACTIVE_FLOWID PHS_NO_SUPRESSION
	global FRAG_FLAG CONCAT_FLAG CONCAT_THRESHOLD PIGGYBACKING_FLAG
	global UPSTREAM_SID_QUEUE_SIZE UPSTREAM_RATE_CONTROL UPSTREAM_SERVICE_RATE USSCHEDQType USSCHEDQSize USSCHEDQDiscipline
	global DOWNSTREAM_RATE_CONTROL DOWNSTREAM_SERVICE_RATE DOWNSTREAM_SID_QUEUE_SIZE BUCKET_LENGTH DSSCHEDQType DSSCHEDQSize DSSCHEDQDiscipline
	global DOWNSTREAM_RATE_CONTROL_n1
	global FlowPriority0 FlowQuantum2 FlowWeight1 MAXp AdaptiveMode USMinRate USMinLatency DSMinRate DSMinLatency ReseqFlow ReseqWindow ReseqTimeout
	global FlowWeightT1 FlowWeightT2 FlowWeightT4
	
	# global variables for CMTS configuration
	global MAP_TIME MAP_FREQUENCY NUMBER_MANAGEMENT_SLOTS NUMBER_CONTENTION_SLOTS 55 66 BKOFF_START BKOFF_END 0.5 MAP_LOOKAHEAD
	
	# global variables for scheduler-related stuff
	global DSSchedMode DSSCHEDQSize DSSCHEDQType
	global USSchedMode USSCHEDQSize USSCHEDQType
	global FAIRSHARE
	
	#
	global RANDOM_FTP_PATH_RTT SAME_FTP_PATH_RTT VAR_FTP_PATH_RTT
	global DEFAULT_BUFFER_CAPACITY
	
	#
	global RAW_DOWNSPEED RAW_UPSPEED
	
	# global variables for timelines
	global printtime stoptime
	
	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY
	
	# global variables this proc generates
	global n0 n1 n2 n4 n5	; # wired nodes
	global ftp_server mftp_server hftp_server
	global dash_server mdash_server hdash_server
	global udp_server
	global LCM MCM HCM UCM	; # CM nodes
	global CMnodelist	; # list of CM nodes (CMTS, Monitor CM, other CM nodes)
	global lan		; # cable network object

#modified
	set DOWNSTREAM_SERVICE_RATE_L	$DOWNSTREAM_SERVICE_RATE
	set DOWNSTREAM_RATE_CONTROL_L	$DOWNSTREAM_RATE_CONTROL
	set DOWNSTREAM_SERVICE_RATE_M	9000000
	set DOWNSTREAM_RATE_CONTROL_M	$DOWNSTREAM_RATE_CONTROL
	set DOWNSTREAM_SERVICE_RATE_H	12000000
	set DOWNSTREAM_RATE_CONTROL_H	$DOWNSTREAM_RATE_CONTROL
#modified

	# path queue size
	set PATH_QSIZE		$DEFAULT_BUFFER_CAPACITY

	# Create nodes
	set n0 [$ns node]	; # used as CMTS
	set n1 [$ns node]	; # used as special monitor CM
	set n2 [$ns node]	; # special wired test node
	set n4 [$ns node]
	set n5 [$ns node]
	
	# Create two routers
	set midRouter [$ns node]
	set endRouter [$ns node]
	
	# Create two edge routers
	set ftpRouter [$ns node]
	set dashRouter [$ns node]
	set webRouter [$ns node]
	set udpRouter [$ns node]
	
	# Set number of servers
	set nFTPsvrs	$NUM_LCM  
	set nM_FTPsvrs	$NUM_MCM
	set nH_FTPsvrs	$NUM_HCM
	set nDASHsvrs	16
	set nM_DASHsvrs	16
	set nH_DASHsvrs	16
	set nUDPsvrs	3
	#set NUM_UCM	$nUDPsvrs

	# Create specified number of ftp server nodes
	for {set i 1} {$i <= $nFTPsvrs} {incr i} {
		set ftp_server($i)	[$ns node]
	}
	
	# Create specified number of ftp server nodes
	for {set i 1} {$i <= $nM_FTPsvrs} {incr i} {
		set mftp_server($i)	[$ns node]
	}
	
	# Create specified number of ftp server nodes
	for {set i 1} {$i <= $nH_FTPsvrs} {incr i} {
		set hftp_server($i)	[$ns node]
	}
	
	# Create specified number of dash server nodes
	for {set i 1} {$i <= $nDASHsvrs} {incr i} {
		set dash_server($i)	[$ns node]
	}
	
	# Create specified number of dash server nodes
	for {set i 1} {$i <= $nM_DASHsvrs} {incr i} {
		set mdash_server($i)	[$ns node]
	}
	
	# Create specified number of dash server nodes
	for {set i 1} {$i <= $nH_DASHsvrs} {incr i} {
		set hdash_server($i)	[$ns node]
	}
	
	# Create specified number of udp server nodes
	for {set i 1} {$i <= $nUDPsvrs} {incr i} {
		set udp_server($i)	[$ns node]
	}
	
	# Set link: midRouter ----- n0 (CMTS)
	#	speed, delay, drop policy
	$ns simplex-link $midRouter $n0 10000Mb 1ms DropTail	; # 10Gbps
	$ns simplex-link $n0 $midRouter 10000Mb 1ms DropTail	; # 10Gbps
	$ns queue-limit $midRouter $n0 $PATH_QSIZE 
	$ns queue-limit $n0 $midRouter $PATH_QSIZE
	
	# Set link: midRouter ----- endRouter
	#	speed, delay, drop policy
	$ns simplex-link $midRouter $endRouter 10000Mb ${delay2}ms DropTail	; # 10Gbps
	$ns simplex-link $endRouter $midRouter 10000Mb ${delay2}ms DropTail	; # 10Gbps
	$ns queue-limit $midRouter $endRouter $PATH_QSIZE 
	$ns queue-limit $endRouter $midRouter $PATH_QSIZE

	#Adjust the prop delay to make it be 60ms rtt
	#for this model, make it 1.5mbps (a T1 link)
	#$ns duplex-link $n0 $n2 1.5Mb 24ms DropTail

	# Set link: n2 ----- endRouter
	#	speed, delay, drop policy
	$ns simplex-link $n2 $endRouter 1000Mb 32ms DropTail	; # 1Gbps
	$ns simplex-link $endRouter $n2 1000Mb 32ms DropTail	; # 1Gbps
	$ns queue-limit $n2 $endRouter $PATH_QSIZE
	$ns queue-limit $endRouter $n2 $PATH_QSIZE
	
	# Add a loss module on the link: n2 ------ endRouter
	#	......
	set loss_modulexnet [new ErrorModel]
	$loss_modulexnet set errModelId 2
	$loss_modulexnet set rate_ 0.0
	#$loss_modulexnet set rate_ 0.01	; 1%
	$loss_modulexnet unit pkt
	$loss_modulexnet ranvar [new RandomVariable/Uniform]
	$loss_modulexnet drop-target [new Agent/Null]
	$ns lossmodel $loss_modulexnet $endRouter $n2
	
	# Link n4 and n5 to endRouter
	#
	$ns duplex-link $endRouter $n4 1000Mb 24ms DropTail	; # 1Gbps
	$ns queue-limit $endRouter $n4 $PATH_QSIZE
	$ns queue-limit $n4 $endRouter $PATH_QSIZE
	$ns duplex-link $endRouter $n5 1000Mb 24ms DropTail	; # 1Gbps
	$ns queue-limit $endRouter $n5 $PATH_QSIZE
	$ns queue-limit $n5 $endRouter $PATH_QSIZE
	
	# Link edge routers to endRouter
	#
	$ns duplex-link $endRouter $ftpRouter 10000Mb 2ms DropTail	; # 10Gbps
	$ns queue-limit $endRouter $ftpRouter $PATH_QSIZE
	$ns queue-limit $ftpRouter $endRouter $PATH_QSIZE
	$ns duplex-link $endRouter $dashRouter 10000Mb 2ms DropTail	; # 10Gbps
	$ns queue-limit $endRouter $dashRouter $PATH_QSIZE
	$ns queue-limit $dashRouter $endRouter $PATH_QSIZE
	$ns duplex-link $endRouter $udpRouter 10000Mb 2ms DropTail	; # 10Gbps
	$ns queue-limit $endRouter $udpRouter $PATH_QSIZE
	$ns queue-limit $udpRouter $endRouter $PATH_QSIZE

	# Link from ftp server to ftpRouter
	set PATH_RTT	0.030	; # 30ms
	set QSIZE	$PATH_QSIZE
	set LSDS 1000000000	; # 1000Mb
	set LSUS 1000000000	; # 1000Mb
    if { [info exists RANDOM_FTP_PATH_RTT] } {
    	# random path delay
	for {set i 1} {$i <= $nFTPsvrs} {incr i} {
		if { $RANDOM_FTP_PATH_RTT == 1 } {
    		set delay [uniform 0.002 0.070]
    		puts "Random FTP path RTT enabled - $delay!"
    		} else {
    		set delay $PATH_RTT
    		puts "No - random FTP path RTT is off - $delay."
    		}
    		$ns simplex-link $ftpRouter $ftp_server($i) $LSUS $delay DropTail
    		$ns simplex-link $ftp_server($i) $ftpRouter $LSDS $delay DropTail
		$ns queue-limit $ftpRouter $ftp_server($i) $QSIZE
		$ns queue-limit $ftp_server($i) $ftpRouter $QSIZE
    	}
    } elseif { [info exists SAME_FTP_PATH_RTT] } {
	# same path delay
	for {set i 1} {$i <= $nFTPsvrs} {incr i} {
		puts "Same FTP path RTT always - $PATH_RTT."
    		$ns simplex-link $ftpRouter $ftp_server($i) $LSUS $PATH_RTT DropTail
    		$ns simplex-link $ftp_server($i) $ftpRouter $LSDS $PATH_RTT DropTail
		$ns queue-limit $ftpRouter $ftp_server($i) $QSIZE
		$ns queue-limit $ftp_server($i) $ftpRouter $QSIZE
    	}
	for {set i 1} {$i <= $nM_FTPsvrs} {incr i} {
		puts "Same FTP path RTT always - $PATH_RTT."
    		$ns simplex-link $ftpRouter $mftp_server($i) $LSUS $PATH_RTT DropTail
    		$ns simplex-link $mftp_server($i) $ftpRouter $LSDS $PATH_RTT DropTail
		$ns queue-limit $ftpRouter $mftp_server($i) $QSIZE
		$ns queue-limit $mftp_server($i) $ftpRouter $QSIZE
    	}
	for {set i 1} {$i <= $nH_FTPsvrs} {incr i} {
		puts "Same FTP path RTT always - $PATH_RTT."
    		$ns simplex-link $ftpRouter $hftp_server($i) $LSUS $PATH_RTT DropTail
    		$ns simplex-link $hftp_server($i) $ftpRouter $LSDS $PATH_RTT DropTail
		$ns queue-limit $ftpRouter $hftp_server($i) $QSIZE
		$ns queue-limit $hftp_server($i) $ftpRouter $QSIZE
    	}
    } elseif { [info exists VAR_FTP_PATH_RTT] } {
    	# varied path delay
	puts "Varied FTP path RTT from ??ms to ??ms for $nFTPsvrs Tier1 ftps."
	set ddd 0
	set qqq 0
	for {set i 1} {$i <= $nFTPsvrs} {incr i} {
		incr qqq
		if { [expr $qqq % 2] } {
			set delay [expr $PATH_RTT + $ddd / 1000.0]
		} else {
			set delay [expr $PATH_RTT - $ddd / 1000.0]
		}
		puts "Varied FTP path delay $i = $delay!"
    		$ns simplex-link $ftpRouter $ftp_server($i) $LSUS $delay DropTail
    		$ns simplex-link $ftp_server($i) $ftpRouter $LSDS $delay DropTail
		$ns queue-limit $ftpRouter $ftp_server($i) $QSIZE
		$ns queue-limit $ftp_server($i) $ftpRouter $QSIZE
		if { [expr $qqq % 2] } {
			set ddd [expr $ddd + 5]
			if { $ddd == 30 } {
				set ddd 0
				set qqq 0
			}
		}
    	}
        #
	puts "Varied M FTP path RTT from ??ms to ??ms for $nM_FTPsvrs Tier2 ftps."
	set ddd 0
	set qqq 0
	for {set i 1} {$i <= $nM_FTPsvrs} {incr i} {
		incr qqq
		if { [expr $qqq % 2] } {
			set delay [expr $PATH_RTT + $ddd / 1000.0]
		} else {
			set delay [expr $PATH_RTT - $ddd / 1000.0]
		}
		puts "Varied FTP path delay $i = $delay!"
    		$ns simplex-link $ftpRouter $mftp_server($i) $LSUS $delay DropTail
    		$ns simplex-link $mftp_server($i) $ftpRouter $LSDS $delay DropTail
		$ns queue-limit $ftpRouter $mftp_server($i) $QSIZE
		$ns queue-limit $mftp_server($i) $ftpRouter $QSIZE
		if { [expr $qqq % 2] } {
			set ddd [expr $ddd + 5]
			if { $ddd == 30 } {
				set ddd 0
				set qqq 0
			}
		}
    	}
	#	
	puts "Varied H FTP path RTT from ??ms to ??ms for $nH_FTPsvrs ftps."
	set ddd 0
	set qqq 0
	for {set i 1} {$i <= $nH_FTPsvrs} {incr i} {
		incr qqq
		if { [expr $qqq % 2] } {
			set delay [expr $PATH_RTT + $ddd / 1000.0]
		} else {
			set delay [expr $PATH_RTT - $ddd / 1000.0]
		}
		puts "Varied FTP path delay $i = $delay!"
    		$ns simplex-link $ftpRouter $hftp_server($i) $LSUS $delay DropTail
    		$ns simplex-link $hftp_server($i) $ftpRouter $LSDS $delay DropTail
		$ns queue-limit $ftpRouter $hftp_server($i) $QSIZE
		$ns queue-limit $hftp_server($i) $ftpRouter $QSIZE
		if { [expr $qqq % 2] } {
			set ddd [expr $ddd + 5]
			if { $ddd == 30 } {
				set ddd 0
				set qqq 0
			}
		}
    	}
    } else {
	# explicitly specified varied path delay
	puts "Explicitly specified varied FTP path RTT."
	$ns duplex-link $ftpRouter $ftp_server(1) $LSDS 5ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(2) $LSDS 10ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(3) $LSDS 15ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(4) $LSDS 20ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(5) $LSDS 25ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(6) $LSDS 30ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(7) $LSDS 35ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(8) $LSDS 40ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(9) $LSDS 45ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(10) $LSDS 50ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(11) $LSDS 55ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(12) $LSDS 60ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(13) $LSDS 65ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(14) $LSDS 70ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(15) $LSDS 75ms DropTail
	$ns duplex-link $ftpRouter $ftp_server(16) $LSDS 80ms DropTail
	
	#queue_limit ???
	puts "Error!"
	exit 1
    }

	# Link from udp server to udpRouter
	for {set i 1} {$i <= $nUDPsvrs} {incr i} {
		puts "Same UDP path RTT always - $PATH_RTT."
    		$ns simplex-link $udpRouter $udp_server($i) $LSUS $PATH_RTT DropTail
    		$ns simplex-link $udp_server($i) $udpRouter $LSDS $PATH_RTT DropTail
		$ns queue-limit $udpRouter $udp_server($i) $QSIZE
		$ns queue-limit $udp_server($i) $udpRouter $QSIZE
	}

	# Link from dash server to dashRouter
    if off {
	# same path delay
	$ns duplex-link $dashRouter $dash_server(1) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(1) $QSIZE
	$ns queue-limit $dash_server(1) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(2) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(2) $QSIZE
	$ns queue-limit $dash_server(2) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(3) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(3) $QSIZE
	$ns queue-limit $dash_server(3) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(4) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(4) $QSIZE
	$ns queue-limit $dash_server(4) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(5) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(5) $QSIZE
	$ns queue-limit $dash_server(5) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(6) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(6) $QSIZE
	$ns queue-limit $dash_server(6) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(7) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(7) $QSIZE
	$ns queue-limit $dash_server(7) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(8) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(8) $QSIZE
	$ns queue-limit $dash_server(8) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(9) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(9) $QSIZE
	$ns queue-limit $dash_server(9) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(10) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(10) $QSIZE
	$ns queue-limit $dash_server(10) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(11) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(11) $QSIZE
	$ns queue-limit $dash_server(11) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(12) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(12) $QSIZE
	$ns queue-limit $dash_server(12) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(13) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(13) $QSIZE
	$ns queue-limit $dash_server(13) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(14) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(14) $QSIZE
	$ns queue-limit $dash_server(14) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(15) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(15) $QSIZE
	$ns queue-limit $dash_server(15) $dashRouter $QSIZE
	$ns duplex-link $dashRouter $dash_server(16) $LSDS 2ms DropTail
	$ns queue-limit $dashRouter $dash_server(16) $QSIZE
	$ns queue-limit $dash_server(16) $dashRouter $QSIZE
    } else {
	# varied path delay
	
	set delay 5
	for {set i 1} {$i <= $nDASHsvrs} {incr i} {
		puts "Varied DASH path delay $i = $delay!"

		$ns simplex-link $dashRouter $dash_server($i) $LSUS ${delay}ms DropTail
		$ns simplex-link $dash_server($i) $dashRouter $LSDS ${delay}ms DropTail
		$ns queue-limit $dashRouter $dash_server($i) $QSIZE
		$ns queue-limit $dash_server($i) $dashRouter $QSIZE
	
		set delay [expr $delay + 5]
	}
	
	set delay 5
	for {set i 1} {$i <= $nM_DASHsvrs} {incr i} {
		puts "Varied M DASH path delay $i = $delay!"

		$ns simplex-link $dashRouter $mdash_server($i) $LSUS ${delay}ms DropTail
		$ns simplex-link $mdash_server($i) $dashRouter $LSDS ${delay}ms DropTail
		$ns queue-limit $dashRouter $mdash_server($i) $QSIZE
		$ns queue-limit $mdash_server($i) $dashRouter $QSIZE
	
		set delay [expr $delay + 5]
	}
	
	set delay 5
	for {set i 1} {$i <= $nH_DASHsvrs} {incr i} {
		puts "Varied H DASH path delay $i = $delay!"

		$ns simplex-link $dashRouter $hdash_server($i) $LSUS ${delay}ms DropTail
		$ns simplex-link $hdash_server($i) $dashRouter $LSDS ${delay}ms DropTail
		$ns queue-limit $dashRouter $hdash_server($i) $QSIZE
		$ns queue-limit $hdash_server($i) $dashRouter $QSIZE
	
		set delay [expr $delay + 5]
	}
    }

	# Build cable network node list (...)
	lappend CMnodelist $n0		; # first must be CMTS nodes
	lappend CMnodelist $n1		; # first CM node in the list
					; # neither n0 or n1 are in the CM array
	for {set i 1} {$i <= $NUM_LCM} {incr i} {
		set LCM($i) [$ns node]	; # create CM node
		lappend CMnodelist $LCM($i)
	}

	for {set i 1} {$i <= $NUM_MCM} {incr i} {
		set MCM($i) [$ns node]	; # create CM node
		lappend CMnodelist $MCM($i)
	}

	for {set i 1} {$i <= $NUM_HCM} {incr i} {
		set HCM($i) [$ns node]	; # create CM node
		lappend CMnodelist $HCM($i)
	}

	for {set i 1} {$i <= $NUM_UCM} {incr i} {
		set UCM($i) [$ns node]	; # create CM node (for UDP flows)
		lappend CMnodelist $UCM($i)
	}

	#
	# Create the DOCSIS cable network with the nodes in 'CMnodelist'
	#
	set lan [$ns make-docsislan $CMnodelist $defaultDSChannel $defaultUSChannel 2ms LL $CmBgDs $CmBgUs $BgProp $ChProp $TCL_DEBUG]

	# Configure CMs with these parameters
	#	<node> <priority> rng_msg_interval status_msg_freq
	#       <debug on/off> cm_backoff_scale
	$lan configure-cm $n1 1 1.0 200.0 $CM0_DEBUG $CM_BKOFF
	for {set i 1} {$i <= $NUM_LCM} {incr i} {
		$lan configure-cm $LCM($i) 1 1.0 200.0 $CM_DEBUG $CM_BKOFF
	}
	for {set i 1} {$i <= $NUM_MCM} {incr i} {
		$lan configure-cm $MCM($i) 1 1.0 200.0 $CM_DEBUG $CM_BKOFF
	}
	for {set i 1} {$i <= $NUM_HCM} {incr i} {
		$lan configure-cm $HCM($i) 1 1.0 200.0 $CM_DEBUG $CM_BKOFF
	}
	for {set i 1} {$i <= $NUM_UCM} {incr i} {
		$lan configure-cm $UCM($i) 1 1.0 200.0 $CM_DEBUG $CM_BKOFF
	}

	# Configure default upstream flows with these parameters:
	#	<node> <flow params>
	# where <flow params> is a string of these fields (see vlan.tcl for details)
	#	f0: sched type
	#	f1: src node	(old: ??)
	#	f2: dst node	(old: pkt type)
	#	f3: flow type
	#	f4: flow ID
	#	f5: phs
	#	f6: bg		<=== this specifies which US bonding group to use
	#	f7: frag
	#	f8: concat flag
	#	f9: concat threshold
	#	f10: piggybacking
	#	f11:
	#	f12:
	#	f13: queue size
	#	f14: debug on/off
	#	f15: upstream rate control
	#	f16: upstream rate
	#	f17: upstream sched queue type
	#	f18: upstream sched queue size
	#	f19: upstream sched queue discipline
	#	f20: flow priority
	#	f21: flow quantum
	#	f22: flow weight
	#	f23: max p
	#	f24: adaptive mode
	#	f25: upstream min rate
	#	f26: upstream min latency
	puts "<<<<< Configure default upstream on BG2 for monitor CM n1"
	$lan configure-defaultup $n1 "$BESCHED $n1 $n2 $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG2 $FRAG_FLAG $CONCAT_FLAG $CONCAT_THRESHOLD $PIGGYBACKING_FLAG 0 0 $UPSTREAM_SID_QUEUE_SIZE $CM0_DEBUG $UPSTREAM_RATE_CONTROL $UPSTREAM_SERVICE_RATE $USSCHEDQType $USSCHEDQSize $USSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $USMinRate $USMinLatency"
	for {set i 1} {$i <= $NUM_LCM} {incr i} {
		puts "<<<<< Configure default upstream on BG2 for LCM $i"
		$lan configure-defaultup $LCM($i) "$BESCHED $LCM($i) $n2 $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG2 $FRAG_FLAG $CONCAT_FLAG $CONCAT_THRESHOLD $PIGGYBACKING_FLAG 0 0 $UPSTREAM_SID_QUEUE_SIZE $CM_DEBUG $UPSTREAM_RATE_CONTROL $UPSTREAM_SERVICE_RATE $USSCHEDQType $USSCHEDQSize $USSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $USMinRate $USMinLatency"
	}
	for {set i 1} {$i <= $NUM_MCM} {incr i} {
		puts "<<<<< Configure default upstream on BG2 for MCM $i"
		$lan configure-defaultup $MCM($i) "$BESCHED $MCM($i) $n2 $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG2 $FRAG_FLAG $CONCAT_FLAG $CONCAT_THRESHOLD $PIGGYBACKING_FLAG 0 0 $UPSTREAM_SID_QUEUE_SIZE $CM_DEBUG $UPSTREAM_RATE_CONTROL $UPSTREAM_SERVICE_RATE $USSCHEDQType $USSCHEDQSize $USSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $USMinRate $USMinLatency"
	}
	for {set i 1} {$i <= $NUM_HCM} {incr i} {
		puts "<<<<< Configure default upstream on BG2 for HCM $i"
		$lan configure-defaultup $HCM($i) "$BESCHED $HCM($i) $n2 $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG2 $FRAG_FLAG $CONCAT_FLAG $CONCAT_THRESHOLD $PIGGYBACKING_FLAG 0 0 $UPSTREAM_SID_QUEUE_SIZE $CM_DEBUG $UPSTREAM_RATE_CONTROL $UPSTREAM_SERVICE_RATE $USSCHEDQType $USSCHEDQSize $USSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $USMinRate $USMinLatency"
	}
	for {set i 1} {$i <= $NUM_UCM} {incr i} {
		puts "<<<<< Configure default upstream on BG2 for UCM $i"
		$lan configure-defaultup $UCM($i) "$BESCHED $UCM($i) $n2 $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG2 $FRAG_FLAG $CONCAT_FLAG $CONCAT_THRESHOLD $PIGGYBACKING_FLAG 0 0 $UPSTREAM_SID_QUEUE_SIZE $CM_DEBUG $UPSTREAM_RATE_CONTROL $UPSTREAM_SERVICE_RATE $USSCHEDQType $USSCHEDQSize $USSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $USMinRate $USMinLatency"
	}
	
	# optional upstream code missing here ...
	if { $UDP_MONITOR_TYPE == 1 } {
		puts "UGS flow code missing!"
		exit 0
	}
	if { $UDP_MONITOR_TYPE == 3 } {
		puts "VBR flow code missing"
		exit 0
	}

	# Configure default downstream flows with these parameters:
	#	<node> <flow params>
	# where <flow params> is a string of these fields (see vlan.tcl for details)
	#	f0: src node	(old: ??)
	#	f1: dst node	(old: pkt type)
	#	f2: flow type
	#	f3: flow ID
	#	f4: phs
	#	f5: bg		<=== this specifies which DS bonding group to use
	#	f6: downstream rate control
	#	f7: downstream rate
	#	f8: downstream queue size
	#	f9: bucket length
	#	f10: downstream sched type
	#	f11: downstream sched queue size
	#	f12: downstream sched queue discipline
	#	f13: flow priority
	#	f14: flow quantum
	#	f15: flow weight
	#	f16: max p
	#	f17: adaptive mode
	#	f18: downstream min rate
	#	f19: downstream min latency
	#	f20: reseq flag
	#	f21: reseq window
	#	f22: reseq timeout
	puts ">>>>> Configure default downstream on BG1 for monitor CM n1"
	$lan configure-defaultdown $n1 "$n2 $n1 $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG1 $DOWNSTREAM_RATE_CONTROL_n1 $DOWNSTREAM_SERVICE_RATE $DOWNSTREAM_SID_QUEUE_SIZE $BUCKET_LENGTH $DSSCHEDQType $DSSCHEDQSize $DSSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeight1 $MAXp $AdaptiveMode $DSMinRate $DSMinLatency $ReseqFlow $ReseqWindow $ReseqTimeout"

	for {set i 1} {$i <= $NUM_LCM} {incr i} {
	#	puts ">>>>> Configure default downstream for LCM $i"

		if {$SCENARIO == 1} {
			puts ">>>>> Configure default downstream #$i on BG #$BG1 for LCM #$i"
			# WARNING: original code has "$n2 $n1 ..." <-- n1 looks like a cut-and-paste bug
			$lan configure-defaultdown $LCM($i) "$n2 $LCM($i) $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG1 $DOWNSTREAM_RATE_CONTROL_L $DOWNSTREAM_SERVICE_RATE_L $DOWNSTREAM_SID_QUEUE_SIZE $BUCKET_LENGTH $DSSCHEDQType $DSSCHEDQSize $DSSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeightT1 $MAXp $AdaptiveMode $DSMinRate $DSMinLatency $ReseqFlow $ReseqWindow $ReseqTimeout"
		}
		
		if {$SCENARIO == 7} {
			puts "Code missing!"
			exit 0
		}

	}

	for {set i 1} {$i <= $NUM_MCM} {incr i} {
	#	puts ">>>>> Configure default downstream for MCM $i"

		if {$SCENARIO == 1} {
			puts ">>>>> Configure default downstream #$i on BG #$BG1 for MCM #$i"
			# WARNING: original code has "$n2 $n1 ..." <-- n1 looks like a cut-and-paste bug
			$lan configure-defaultdown $MCM($i) "$n2 $MCM($i) $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG1 $DOWNSTREAM_RATE_CONTROL_M $DOWNSTREAM_SERVICE_RATE_M $DOWNSTREAM_SID_QUEUE_SIZE $BUCKET_LENGTH $DSSCHEDQType $DSSCHEDQSize $DSSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeightT2 $MAXp $AdaptiveMode $DSMinRate $DSMinLatency $ReseqFlow $ReseqWindow $ReseqTimeout"
		}
		
		if {$SCENARIO == 7} {
			puts "Code missing!"
			exit 0
		}

	}

	for {set i 1} {$i <= $NUM_HCM} {incr i} {
	#	puts ">>>>> Configure default downstream for HCM $i"

		if {$SCENARIO == 1} {
			puts ">>>>> Configure default downstream #$i on BG #$BG1 for HCM #$i"
			# WARNING: original code has "$n2 $n1 ..." <-- n1 looks like a cut-and-paste bug
			$lan configure-defaultdown $HCM($i) "$n2 $HCM($i) $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG1 $DOWNSTREAM_RATE_CONTROL_H $DOWNSTREAM_SERVICE_RATE_H $DOWNSTREAM_SID_QUEUE_SIZE $BUCKET_LENGTH $DSSCHEDQType $DSSCHEDQSize $DSSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeightT4 $MAXp $AdaptiveMode $DSMinRate $DSMinLatency $ReseqFlow $ReseqWindow $ReseqTimeout"
		}
		
		if {$SCENARIO == 7} {
			puts "Code missing!"
			exit 0
		}

	}

	for {set i 1} {$i <= $NUM_UCM} {incr i} {
	#	puts ">>>>> Configure default downstream for UCM $i"

		if {$SCENARIO == 1} {
			puts ">>>>> Configure default downstream #$i on BG #$BG1 for UCM #$i"
			# WARNING: original code has "$n2 $n1 ..." <-- n1 looks like a cut-and-paste bug
			if {$i == 1} {
			$lan configure-defaultdown $UCM($i) "$n2 $UCM($i) $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG1 $DOWNSTREAM_RATE_CONTROL_L $DOWNSTREAM_SERVICE_RATE_L $DOWNSTREAM_SID_QUEUE_SIZE $BUCKET_LENGTH $DSSCHEDQType $DSSCHEDQSize $DSSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeightT1 $MAXp $AdaptiveMode $DSMinRate $DSMinLatency $ReseqFlow $ReseqWindow $ReseqTimeout"
			} elseif {$i == 2} {
			$lan configure-defaultdown $UCM($i) "$n2 $UCM($i) $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG1 $DOWNSTREAM_RATE_CONTROL_M $DOWNSTREAM_SERVICE_RATE_M $DOWNSTREAM_SID_QUEUE_SIZE $BUCKET_LENGTH $DSSCHEDQType $DSSCHEDQSize $DSSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeightT2 $MAXp $AdaptiveMode $DSMinRate $DSMinLatency $ReseqFlow $ReseqWindow $ReseqTimeout"
			} else {
			$lan configure-defaultdown $UCM($i) "$n2 $UCM($i) $PT_WILDCARD $INACTIVE_FLOWID $PHS_NO_SUPRESSION $BG1 $DOWNSTREAM_RATE_CONTROL_H $DOWNSTREAM_SERVICE_RATE_H $DOWNSTREAM_SID_QUEUE_SIZE $BUCKET_LENGTH $DSSCHEDQType $DSSCHEDQSize $DSSCHEDQDiscipline $FlowPriority0 $FlowQuantum2 $FlowWeightT4 $MAXp $AdaptiveMode $DSMinRate $DSMinLatency $ReseqFlow $ReseqWindow $ReseqTimeout"
			}
		}
		
		if {$SCENARIO == 7} {
			puts "Code missing!"
			exit 0
		}

	}

	#
	# Configure CMTS (n0)
	#
	puts "Configure CMTS (n0) ......"
	#
	# Management params (see vlan.tcl and mac/configMgr.cc)
	#	cmts_node, sync_msg_interval, rng_msg_interval, ucd_msg_interval
	$lan configure-mgmtparams $n0 2.0 1.0 3.0
	#
	# Map params (see vlan.tcl and mac/configMgr.cc)
	#	cmts_node, time_covered, map_interval, num_contention_slots, num_sm_slots,
	#	short_grant_limit, long_grant_limit, bkoff_start, bkoff_end,
	#	proportion, MAP_LOOKAHEAD
	$lan configure-mapparams $n0 $MAP_TIME $MAP_FREQUENCY $NUMBER_MANAGEMENT_SLOTS $NUMBER_CONTENTION_SLOTS 55 66 $BKOFF_START $BKOFF_END 0.5 $MAP_LOOKAHEAD
	#
	puts "Configuring DS scheduler to mode $DSSchedMode ..."
	$lan configure-DSScheduler $n0 $DSSchedMode $DSSCHEDQSize $DSSCHEDQType
	puts "Configuring US scheduler to mode $USSchedMode ..."
	$lan configure-USScheduler $n0 $USSchedMode $USSCHEDQSize $USSCHEDQType
	#
	# if sched mode is fairshare, make sure all priorities set to 0
	if {$DSSchedMode == $FAIRSHARE} {
		set PRIORITY_HIGH 0
		set PRIORITY_LOW 0
		set FLOW_PRIORITY $PRIORITY_HIGH
	}
	#
	puts "Done configuring CMTS."

	#
	# Trace CM bandwidth
	#    Params: mac ns CMnode interval filename
	#
	# For monitor CM
	TraceCMBW $lan $ns $n1 2.0 CM-BW-n1.out
	$ns at $printtime "dumpCMStats $lan $ns $n1 CMstats.out"
	# For other CMs
	for {set i 1} {$i <= $NUM_LCM} {incr i} {
		set outfilename "CM-BW-LCM[expr $i + 0].out"
		TraceCMBW $lan $ns $LCM($i) 1.0 $outfilename
		$ns at $printtime "dumpCMStats $lan $ns $LCM($i) CMstats.out"
	}
	for {set i 1} {$i <= $NUM_MCM} {incr i} {
		set outfilename "CM-BW-MCM[expr $i + 0].out"
		TraceCMBW $lan $ns $MCM($i) 1.0 $outfilename
		$ns at $printtime "dumpCMStats $lan $ns $MCM($i) CMstats.out"
	}
	for {set i 1} {$i <= $NUM_HCM} {incr i} {
		set outfilename "CM-BW-HCM[expr $i + 0].out"
		TraceCMBW $lan $ns $HCM($i) 1.0 $outfilename
		$ns at $printtime "dumpCMStats $lan $ns $HCM($i) CMstats.out"
	}

	#
	# Trace CMTS throughput
	#    Params: mac ns CMTSnode interval filename
	#
	#    Note: this calls dumpBWCMTS which also calls dumpUGSJitter creating
	#          entries in UGSJitterCMTS.out
	#
	#    Note: dumpCMTSStats produces "DSSIDstats.out"
	#
	TraceCMTSBW $lan $ns $n0 1.0 CMTS-BW.out
	$ns at $stoptime "dumpCMTSStats $lan $ns $n0 CMTSstats.out"
	
	#
	# Trace DOCSIS downstream and upstream queues
	#
	# CMTS
	TraceDOCSISQueue $lan $ns $n0 1 CMTS-DS-QUEUE.out
	#
	# CM
	#set NUM_FLOWS $NUM_CM
	if { $NUM_LCM > 0 } {
		TraceDOCSISQueue $lan $ns $LCM(1) 1 CMQUEUE.out
	} else {
		TraceDOCSISQueue $lan $ns $n1 1 CMQUEUE.out
	}

	# Trace the DS and US utilization as observed by the CMTS
	TraceDOCSISUtilization $lan $ns $n0 1.0 CMTS-DS-util.out $RAW_DOWNSPEED $RAW_UPSPEED

	# Start the simulation (starts the registration phase)
	puts "Start DOCSIS LAN simulation now ......"
	$lan startsim

	puts "Basic cable topology with additional routers and ftp servers created!"
}


