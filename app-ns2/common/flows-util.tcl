#
# TCL helper functions for creating flows
#

proc create_flow_set0 { NUM_FLOWS ALL_UDP TRAFFIC_DIRECTION TRAFFIC_TYPE CBR_INTERVAL TARGET_VIDEO_RATE TCP_PROT_ID } {

	puts "Build a $NUM_FLOWS-flow set ..."
	
	# global variables this proc relies on
	global ns		; # ns simulator object
	global n2		; # wired node
	global CM		; # CM nodes

	# global variables for timeline
	global starttime1
	global printtime
	
	# global variables for TCP/UDP connections
	global PACKETSIZE BURSTTIME IDLETIME
	global WINDOW SHAPE FLOW_PRIORITY
	
	#
	# Configure UDP/TCP flows
	#
	for {set i 1} {$i <= $NUM_FLOWS} {incr i} {

		set CXN [expr $i + 10]
		set flowStartTime [expr $starttime1 + [uniform 0 2]]

		if { $ALL_UDP == 1 } {

			set thruputFileOut "CMUDP[expr $CXN + 0].out"
			set statsFileOut "UDPstats.out"

			if { $TRAFFIC_DIRECTION == 0 } {	; # upstream
				puts "Configure UDP upstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
      				BuildUDPCxWithMode $ns $CM($i) $n2 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
			} else {				; # downstream
				if { $i == 4 } {
					puts "Configure UDP downstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
					#puts "Let this UDP downstream flow be a BADGUY session (index:$i)"
					#set BADflowStartTime $BADGUY_UDP_FLOWS_START_TIME
					#set BADflowStopTime $BADGUY_UDP_FLOWS_STOP_TIME
					#set BAD_PACKETSIZE 1460
					#set BAD_TARGET_VIDEO_RATE 24000000.0
					#set BAD_CBR_INTERVAL [expr $BAD_PACKETSIZE * 8 / $BAD_TARGET_VIDEO_RATE ]
					#set BAD_BURSTTIME $BURSTTIME
					#set BAD_IDLETIME $IDLETIME
					#set BAD_SHAPE $SHAPE
					#set BAD_MODE $CBR_TRAFFIC_MODE
					#BuildUDPCxWithMode $ns $n2 $CM($i) 1 $BAD_PACKETSIZE $BAD_BURSTTIME $BAD_IDLETIME  $BAD_CBR_INTERVAL $BAD_TARGET_VIDEO_RATE  $CXN $BADflowStartTime $BADflowStopTime $thruputFileOut $statsFileOut $BAD_SHAPE $BAD_MODE $FLOW_PRIORITY
					BuildUDPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
				} else {
					puts "Configure UDP downstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
					BuildUDPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
				}
			}
			
		} else {

			set thruputFileOut "CMTCP[expr $CXN + 0].out"
			set statsFileOut "TCPstats.out"

			if { $TRAFFIC_DIRECTION == 0 } {	; # upstream flow
				BuildTCPCxWithMode $ns $CM($i) $n2 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime  $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
			} else {				; # downstream flow
				if { $i == 1 } {
					BuildTCPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
				} else {
					BuildTCPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
				}
			}
			
		}
	}
	
	puts "Basic flow set created!"
}

proc create_flow_set0_9ftp_1udp { NUM_FLOWS ALL_UDP TRAFFIC_DIRECTION TRAFFIC_TYPE CBR_INTERVAL TARGET_VIDEO_RATE TCP_PROT_ID BADGUY_FLOWS_START_TIME BADGUY_FLOWS_STOP_TIME } {

	puts "Build a $NUM_FLOWS-flow set ..."
	
	# global variables this proc relies on
	global ns		; # ns simulator object
	global n2		; # wired node
	global ftp_server	; # wired node
	global CM		; # CM nodes

	# global variables for timeline
	global starttime1
	global printtime
	
	# global variables for TCP/UDP connections
	global PACKETSIZE BURSTTIME IDLETIME
	global WINDOW SHAPE FLOW_PRIORITY
	global CBR_TRAFFIC_MODE
	
	#
	# Configure UDP/TCP flows
	#
	for {set i 1} {$i <= $NUM_FLOWS} {incr i} {

		set CXN [expr $i + 10]
		set flowStartTime [expr $starttime1 + [uniform 0 2]]

		if { $ALL_UDP == 1 } {

			set thruputFileOut "CMUDP[expr $CXN + 0].out"
			set statsFileOut "UDPstats.out"

			if { $TRAFFIC_DIRECTION == 0 } {	; # upstream
				puts "Configure UDP upstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
      				BuildUDPCxWithMode $ns $CM($i) $n2 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
			} else {				; # downstream
				if { $i == 4 } {
					puts "Configure UDP downstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
					#puts "Let this UDP downstream flow be a BADGUY session (index:$i)"
					#set BADflowStartTime $BADGUY_UDP_FLOWS_START_TIME
					#set BADflowStopTime $BADGUY_UDP_FLOWS_STOP_TIME
					#set BAD_PACKETSIZE 1460
					#set BAD_TARGET_VIDEO_RATE 24000000.0
					#set BAD_CBR_INTERVAL [expr $BAD_PACKETSIZE * 8 / $BAD_TARGET_VIDEO_RATE ]
					#set BAD_BURSTTIME $BURSTTIME
					#set BAD_IDLETIME $IDLETIME
					#set BAD_SHAPE $SHAPE
					#set BAD_MODE $CBR_TRAFFIC_MODE
					#BuildUDPCxWithMode $ns $n2 $CM($i) 1 $BAD_PACKETSIZE $BAD_BURSTTIME $BAD_IDLETIME  $BAD_CBR_INTERVAL $BAD_TARGET_VIDEO_RATE  $CXN $BADflowStartTime $BADflowStopTime $thruputFileOut $statsFileOut $BAD_SHAPE $BAD_MODE $FLOW_PRIORITY
					BuildUDPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
				} else {
					puts "Configure UDP downstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
					BuildUDPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
				}
			}
			
		} else {

			set thruputFileOut "CMTCP[expr $CXN + 0].out"
			set statsFileOut "TCPstats.out"

			if { $TRAFFIC_DIRECTION == 0 } {	; # upstream flow
				BuildTCPCxWithMode $ns $CM($i) $n2 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime  $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
			} else {				; # downstream flow
				if { $i == 4 } {
					puts "Build a DS UDP BADGUY session (index:$i) ";
					set thruputFileOut "CMUDP[expr $CXN + 0].out"
					set statsFileOut "UDPstats.out"
					set BADflowStartTime $BADGUY_FLOWS_START_TIME
					set BADflowStopTime $BADGUY_FLOWS_STOP_TIME
					set BAD_PACKETSIZE 1460
					set BAD_TARGET_VIDEO_RATE 24000000.0
					set BAD_CBR_INTERVAL [expr $BAD_PACKETSIZE * 8 / $BAD_TARGET_VIDEO_RATE ]
					set BAD_BURSTTIME $BURSTTIME
					set BAD_IDLETIME $IDLETIME
					set BAD_SHAPE $SHAPE
					set BAD_MODE $CBR_TRAFFIC_MODE
					BuildUDPCxWithMode $ns $n2 $CM($i) 1 $BAD_PACKETSIZE $BAD_BURSTTIME $BAD_IDLETIME  $BAD_CBR_INTERVAL $BAD_TARGET_VIDEO_RATE $CXN $BADflowStartTime $BADflowStopTime $thruputFileOut $statsFileOut $BAD_SHAPE $BAD_MODE $FLOW_PRIORITY
					#BuildTCPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
				} else {
					BuildTCPCxWithMode $ns $ftp_server(1) $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
				}
			}
			
		}
	}
	
	puts "Basic flow set created!"
}

proc create_flow_set0_src_ftp_servers { NUM_FLOWS ALL_UDP TRAFFIC_DIRECTION TRAFFIC_TYPE CBR_INTERVAL TARGET_VIDEO_RATE TCP_PROT_ID } {

	puts "Build a $NUM_FLOWS-flow set ..."
	
	# global variables this proc relies on
	global ns		; # ns simulator object
	global ftp_server	; # wired node
	global CM		; # CM nodes

	# global variables for timeline
	global starttime1
	global printtime
	
	# global variables for TCP/UDP connections
	global PACKETSIZE BURSTTIME IDLETIME
	global WINDOW SHAPE FLOW_PRIORITY
	
	puts "WINDOW = $WINDOW"
	
	#
	# Configure UDP/TCP flows
	#
	for {set i 1} {$i <= $NUM_FLOWS} {incr i} {

		set CXN [expr $i + 10]
		set flowStartTime [expr $starttime1 + [uniform 0 2]]

		if { $ALL_UDP == 1 } {

			set thruputFileOut "CMUDP[expr $CXN + 0].out"
			set statsFileOut "UDPstats.out"

			if { $TRAFFIC_DIRECTION == 0 } {	; # upstream
				puts "Configure UDP upstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
      				BuildUDPCxWithMode $ns $CM($i) $n2 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
			} else {				; # downstream
				if { $i == 4 } {
					puts "Configure UDP downstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
					#puts "Let this UDP downstream flow be a BADGUY session (index:$i)"
					#set BADflowStartTime $BADGUY_UDP_FLOWS_START_TIME
					#set BADflowStopTime $BADGUY_UDP_FLOWS_STOP_TIME
					#set BAD_PACKETSIZE 1460
					#set BAD_TARGET_VIDEO_RATE 24000000.0
					#set BAD_CBR_INTERVAL [expr $BAD_PACKETSIZE * 8 / $BAD_TARGET_VIDEO_RATE ]
					#set BAD_BURSTTIME $BURSTTIME
					#set BAD_IDLETIME $IDLETIME
					#set BAD_SHAPE $SHAPE
					#set BAD_MODE $CBR_TRAFFIC_MODE
					#BuildUDPCxWithMode $ns $n2 $CM($i) 1 $BAD_PACKETSIZE $BAD_BURSTTIME $BAD_IDLETIME  $BAD_CBR_INTERVAL $BAD_TARGET_VIDEO_RATE  $CXN $BADflowStartTime $BADflowStopTime $thruputFileOut $statsFileOut $BAD_SHAPE $BAD_MODE $FLOW_PRIORITY
					BuildUDPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
				} else {
					puts "Configure UDP downstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
					BuildUDPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
				}
			}
			
		} else {

			set thruputFileOut "CMTCP[expr $CXN + 0].out"
			set statsFileOut "TCPstats.out"

			if { $TRAFFIC_DIRECTION == 0 } {	; # upstream flow
				BuildTCPCxWithMode $ns $CM($i) $n2 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime  $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
			} else {				; # downstream flow
				if { $i == 1 } {
					BuildTCPCxWithMode $ns $ftp_server($i) $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
				} else {
					BuildTCPCxWithMode $ns $ftp_server($i) $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
				}
			}
			
		}
	}
	
	puts "Basic flow set created!"
}

proc create_flow_set0_varied_rates { NUM_FLOWS ALL_UDP TRAFFIC_DIRECTION TRAFFIC_TYPE CBR_INTERVAL_ARRLIST TARGET_VIDEO_RATE TCP_PROT_ID } {

	puts "Build a $NUM_FLOWS-flow set ..."
	
	global CBR_TRAFFIC_MODE
	
	# global variables this proc relies on
	global ns		; # ns simulator object
	global n2		; # wired node
	global CM		; # CM nodes

	# global variables for timeline
	global starttime1
	global printtime
	
	# global variables for TCP/UDP connections
	global PACKETSIZE BURSTTIME IDLETIME
	global WINDOW SHAPE FLOW_PRIORITY
	
	# Set to access CBR interval array
	array set arr $CBR_INTERVAL_ARRLIST
	
	# Must use CBR traffic mode
	set TRAFFIC_TYPE $CBR_TRAFFIC_MODE
	
	#
	# Configure UDP/TCP flows
	#
	for {set i 1} {$i <= $NUM_FLOWS} {incr i} {
		set CBR_INTERVAL $arr($i)
		puts "CBR_INTERVAL for flow $i is set to $CBR_INTERVAL"

		set CXN [expr $i + 10]
		set flowStartTime [expr $starttime1 + [uniform 0 2]]

		if { $ALL_UDP == 1 } {

			set thruputFileOut "CMUDP[expr $CXN + 0].out"
			set statsFileOut "UDPstats.out"

			if { $TRAFFIC_DIRECTION == 0 } {	; # upstream
				puts "Configure UDP upstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
      				BuildUDPCxWithMode $ns $CM($i) $n2 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
			} else {				; # downstream
				if { $i == 4 } {
					puts "Configure UDP downstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
					#puts "Let this UDP downstream flow be a BADGUY session (index:$i)"
					#set BADflowStartTime $BADGUY_UDP_FLOWS_START_TIME
					#set BADflowStopTime $BADGUY_UDP_FLOWS_STOP_TIME
					#set BAD_PACKETSIZE 1460
					#set BAD_TARGET_VIDEO_RATE 24000000.0
					#set BAD_CBR_INTERVAL [expr $BAD_PACKETSIZE * 8 / $BAD_TARGET_VIDEO_RATE ]
					#set BAD_BURSTTIME $BURSTTIME
					#set BAD_IDLETIME $IDLETIME
					#set BAD_SHAPE $SHAPE
					#set BAD_MODE $CBR_TRAFFIC_MODE
					#BuildUDPCxWithMode $ns $n2 $CM($i) 1 $BAD_PACKETSIZE $BAD_BURSTTIME $BAD_IDLETIME  $BAD_CBR_INTERVAL $BAD_TARGET_VIDEO_RATE  $CXN $BADflowStartTime $BADflowStopTime $thruputFileOut $statsFileOut $BAD_SHAPE $BAD_MODE $FLOW_PRIORITY
					BuildUDPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
				} else {
					puts "Configure UDP downstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
					BuildUDPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
				}
			}
			
		} else {

			set thruputFileOut "CMTCP[expr $CXN + 0].out"
			set statsFileOut "TCPstats.out"

			if { $TRAFFIC_DIRECTION == 0 } {	; # upstream flow
				BuildTCPCxWithMode $ns $CM($i) $n2 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime  $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
			} else {				; # downstream flow
				if { $i == 1 } {
					BuildTCPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
				} else {
					BuildTCPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
				}
			}
			
		}
	}
	
	puts "Basic flow set created!"
}

proc create_flow_set0_with_bad_flow { NUM_FLOWS ALL_UDP TRAFFIC_DIRECTION TRAFFIC_TYPE CBR_INTERVAL TARGET_VIDEO_RATE TCP_PROT_ID BADGUY_FLOWS_START_TIME BADGUY_FLOWS_STOP_TIME } {

	puts "Build a $NUM_FLOWS-flow set ..."
	
	# global variables this proc relies on
	global ns		; # ns simulator object
	global n2		; # wired node
	global CM		; # CM nodes

	# global variables for timeline
	global starttime1
	global printtime
	
	# global variables for TCP/UDP connections
	global PACKETSIZE BURSTTIME IDLETIME
	global WINDOW SHAPE FLOW_PRIORITY
	global CBR_TRAFFIC_MODE
	
	#
	# Configure UDP/TCP flows
	#
	for {set i 1} {$i <= $NUM_FLOWS} {incr i} {

		set CXN [expr $i + 10]
		set flowStartTime [expr $starttime1 + [uniform 0 2]]

		if { $ALL_UDP == 1 } {

			set thruputFileOut "CMUDP[expr $CXN + 0].out"
			set statsFileOut "UDPstats.out"

			if { $TRAFFIC_DIRECTION == 0 } {	; # upstream
				puts "Configure UDP upstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
      				BuildUDPCxWithMode $ns $CM($i) $n2 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
			} else {				; # downstream
				if { $i == 4 } {
					puts "Build a DS UDP BADGUY session (index:$i) ";
					set BADflowStartTime $BADGUY_FLOWS_START_TIME
					set BADflowStopTime $BADGUY_FLOWS_STOP_TIME
					set BAD_PACKETSIZE 1460
					set BAD_TARGET_VIDEO_RATE 24000000.0
					set BAD_CBR_INTERVAL [expr $BAD_PACKETSIZE * 8 / $BAD_TARGET_VIDEO_RATE ]
					set BAD_BURSTTIME $BURSTTIME
					set BAD_IDLETIME $IDLETIME
					set BAD_SHAPE $SHAPE
					set BAD_MODE $CBR_TRAFFIC_MODE
					BuildUDPCxWithMode $ns $n2 $CM($i) 1 $BAD_PACKETSIZE $BAD_BURSTTIME $BAD_IDLETIME  $BAD_CBR_INTERVAL $BAD_TARGET_VIDEO_RATE  $CXN $BADflowStartTime $BADflowStopTime $thruputFileOut $statsFileOut $BAD_SHAPE $BAD_MODE $FLOW_PRIORITY
					#BuildUDPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
				} else {
					puts "Configure UDP downstream flow (target rate = $TARGET_VIDEO_RATE) for CM $i ..."
					BuildUDPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $SHAPE $TRAFFIC_TYPE $FLOW_PRIORITY
				}
			}
			
		} else {

			set thruputFileOut "CMTCP[expr $CXN + 0].out"
			set statsFileOut "TCPstats.out"

			if { $TRAFFIC_DIRECTION == 0 } {	; # upstream flow
				BuildTCPCxWithMode $ns $CM($i) $n2 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime  $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
			} else {				; # downstream flow
				if { $i == 4 } {
					# Bad guy TCP flow needs to be CBR traffic instead of FTP
					puts "Build a DS TCP BADGUY session (index:$i) ";
					set BADflowStartTime $BADGUY_FLOWS_START_TIME
					set BADflowStopTime $BADGUY_FLOWS_STOP_TIME
					set BAD_PACKETSIZE 1460
					set BAD_TARGET_VIDEO_RATE 24000000.0
					set BAD_CBR_INTERVAL [expr $BAD_PACKETSIZE * 8 / $BAD_TARGET_VIDEO_RATE ]
					set BAD_BURSTTIME $BURSTTIME
					set BAD_IDLETIME $IDLETIME
					set BAD_SHAPE $SHAPE
					set BAD_MODE $CBR_TRAFFIC_MODE
					BuildTCPCxWithMode $ns $n2 $CM($i) 1 $BAD_PACKETSIZE $BAD_BURSTTIME $BAD_IDLETIME $BAD_CBR_INTERVAL $BAD_TARGET_VIDEO_RATE $CXN $BADflowStartTime $BADflowStopTime $thruputFileOut $statsFileOut $WINDOW $BAD_SHAPE $TCP_PROT_ID $BAD_MODE $FLOW_PRIORITY
				} else {
					BuildTCPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
				}
			}
			
		}
	}
	
	puts "Basic flow set created!"
}

proc create_ftp_flow_set { num_flows cm_start } {
	global TCL_DEBUG
	
	global ns
	global CM		; # nodes
	global ftp_server
	
	global PACKETSIZE BURSTTIME IDLETIME BURSTRATE SHAPE WINDOW
	global TCP_PROT_ID FTP_TRAFFIC_MODE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY
	
	# global variables for timelines
	global printtime
	
	set FLOW_PRIORITY $PRIORITY_LOW
	
	set tcpprinttime $printtime

	set statsFileOut "DSFTPTCPstats.out"
	exec rm -f $statsFileOut
	
	puts "Build $num_flows DS FTP sessions using stats file: $statsFileOut, start_cm: $cm_start"
	
	for {set i 0} {$i < $num_flows} {incr i} {
	
		set cmIndex [expr $i + $cm_start]
		set ftpIndex [expr $i + 1]
		set cxid  [expr $cmIndex + 1000]
		set newFileOut "CMTCPDSFTP[expr $cxid + 0].out"
		#set tcpprinttime $printtime
		
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 1]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 1]]
		}

		#if {$TCL_DEBUG == 1} {
			puts "Build DS TCP session:  CM Index: $cmIndex, FTP index: $ftpIndex, cxid: $cxid, start time: $flowStartTime"
		#}
		
		#      BuildTCPCx $ns $wrt_server $n($clientIndex) $CONCURRENTTCP $PACKETSIZE $BURSTTIME $IDLETIME $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut  $WINDOW  $SHAPE  $protID
		BuildTCPCxWithMode $ns $ftp_server($ftpIndex) $CM($cmIndex) 1 $PACKETSIZE $BURSTTIME $IDLETIME 0  $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut $statsFileOut  $WINDOW  $SHAPE  $TCP_PROT_ID $FTP_TRAFFIC_MODE $FLOW_PRIORITY
	}
	
	puts "DS FTP sessions sourced from ftp_server created!"
}

proc create_ftp_lcm_flow_set { num_flows cm_start } {
	global TCL_DEBUG
	
	global ns
	global LCM
	global ftp_server
	
	global PACKETSIZE BURSTTIME IDLETIME BURSTRATE SHAPE WINDOW
	global TCP_PROT_ID FTP_TRAFFIC_MODE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY
	
	# global variables for timelines
	global printtime
	
	set FLOW_PRIORITY $PRIORITY_LOW
	
	set tcpprinttime $printtime

	set statsFileOut "DSFTPTCPstatsT1.out"
	exec rm -f $statsFileOut
	
	puts "Build $num_flows DS FTP sessions using stats file: $statsFileOut, start_cm: $cm_start"
	
	for {set i 0} {$i < $num_flows} {incr i} {
	
		set cmIndex [expr $i + $cm_start]
		set ftpIndex [expr $i + 1]
		set cxid  [expr $cmIndex + 1000]
		set newFileOut "CMTCPDSFTP[expr $cxid + 0].out"
		#set tcpprinttime $printtime
		
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 1]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 1]]
		}

		#if {$TCL_DEBUG == 1} {
			puts "Build DS TCP session:  CM Index: $cmIndex, FTP index: $ftpIndex, cxid: $cxid, start time: $flowStartTime"
		#}
		
		#      BuildTCPCx $ns $wrt_server $n($clientIndex) $CONCURRENTTCP $PACKETSIZE $BURSTTIME $IDLETIME $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut  $WINDOW  $SHAPE  $protID
		BuildTCPCxWithMode $ns $ftp_server($ftpIndex) $LCM($cmIndex) 1 $PACKETSIZE $BURSTTIME $IDLETIME 0  $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut $statsFileOut  $WINDOW  $SHAPE  $TCP_PROT_ID $FTP_TRAFFIC_MODE $FLOW_PRIORITY
	}
	
	puts "DS FTP sessions sourced from ftp_server created!"
}

proc create_ftp_mcm_flow_set { num_flows cm_start } {
	global TCL_DEBUG
	
	global ns
	global MCM
	global mftp_server
	
	global PACKETSIZE BURSTTIME IDLETIME BURSTRATE SHAPE WINDOW
	global TCP_PROT_ID FTP_TRAFFIC_MODE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY
	
	# global variables for timelines
	global printtime
	
	set FLOW_PRIORITY $PRIORITY_LOW
	
	set tcpprinttime $printtime

	set statsFileOut "DSFTPTCPstatsT2.out"
	exec rm -f $statsFileOut
	
	puts "Build $num_flows DS FTP sessions using stats file: $statsFileOut, start_cm: $cm_start"
	
	for {set i 0} {$i < $num_flows} {incr i} {
	
		set cmIndex [expr $i + $cm_start]
		set ftpIndex [expr $i + 1]
		set cxid  [expr $cmIndex + 2000]
		set newFileOut "CMTCPDSFTP[expr $cxid + 0].out"
		#set tcpprinttime $printtime
		
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 1]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 1]]
		}

		#if {$TCL_DEBUG == 1} {
			puts "Build DS TCP session:  CM Index: $cmIndex, FTP index: $ftpIndex, cxid: $cxid, start time: $flowStartTime"
		#}
		
		#      BuildTCPCx $ns $wrt_server $n($clientIndex) $CONCURRENTTCP $PACKETSIZE $BURSTTIME $IDLETIME $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut  $WINDOW  $SHAPE  $protID
		BuildTCPCxWithMode $ns $mftp_server($ftpIndex) $MCM($cmIndex) 1 $PACKETSIZE $BURSTTIME $IDLETIME 0  $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut $statsFileOut  $WINDOW  $SHAPE  $TCP_PROT_ID $FTP_TRAFFIC_MODE $FLOW_PRIORITY
	}
	
	puts "DS FTP sessions sourced from ftp_server created!"
}

proc create_ftp_hcm_flow_set { num_flows cm_start } {
	global TCL_DEBUG
	
	global ns
	global HCM
	global hftp_server
	
	global PACKETSIZE BURSTTIME IDLETIME BURSTRATE SHAPE WINDOW
	global TCP_PROT_ID FTP_TRAFFIC_MODE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY
	
	# global variables for timelines
	global printtime
	
	set FLOW_PRIORITY $PRIORITY_LOW
	
	set tcpprinttime $printtime

	set statsFileOut "DSFTPTCPstatsT3.out"
	exec rm -f $statsFileOut
	
	puts "Build $num_flows DS FTP sessions using stats file: $statsFileOut, start_cm: $cm_start"
	
	for {set i 0} {$i < $num_flows} {incr i} {
	
		set cmIndex [expr $i + $cm_start]
		set ftpIndex [expr $i + 1]
		set cxid  [expr $cmIndex + 3000]
		set newFileOut "CMTCPDSFTP[expr $cxid + 0].out"
		#set tcpprinttime $printtime
		
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 1]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 1]]
		}

		#if {$TCL_DEBUG == 1} {
			puts "Build DS TCP session:  CM Index: $cmIndex, FTP index: $ftpIndex, cxid: $cxid, start time: $flowStartTime"
		#}
		
		#      BuildTCPCx $ns $wrt_server $n($clientIndex) $CONCURRENTTCP $PACKETSIZE $BURSTTIME $IDLETIME $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut  $WINDOW  $SHAPE  $protID
		BuildTCPCxWithMode $ns $hftp_server($ftpIndex) $HCM($cmIndex) 1 $PACKETSIZE $BURSTTIME $IDLETIME 0  $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut $statsFileOut  $WINDOW  $SHAPE  $TCP_PROT_ID $FTP_TRAFFIC_MODE $FLOW_PRIORITY
	}
	
	puts "DS FTP sessions sourced from ftp_server created!"
}

proc create_dash_video_flow_set { num_flows cm_start } {

	global TCL_DEBUG
	
	global ns
	global CM		; # nodes
	global dash_server
	
	#global MULTI_APP_MODE firstWebBrowserIndex firstBTIndex
	
	global WINDOW PACKETSIZE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY

	# global variables for timelines
	global printtime
	
	# DASH variables
	global vodapp_playback_buffer_capacity aavginterval DASHMODE startingServerRate

	#set TARGET_VIDEO_RATE 3000000.0
	set TARGET_VIDEO_RATE $startingServerRate
	#set WEB_VIDEO_PACKETSIZE 1000
	set WEB_VIDEO_PACKETSIZE $PACKETSIZE
	
	set FLOW_PRIORITY $PRIORITY_HIGH

	set tcpprinttime $printtime

	#if {$TCL_DEBUG == 1} {
		puts "Build $num_flows DASH Video flows (cm_start: $cm_start, target rate: $TARGET_VIDEO_RATE)";
	#}
	
	set statsHandle "VIDEOTCPstats.out"
	exec rm -f $statsHandle
	for {set i 0} {$i < $num_flows} {incr i} {
	
		set cmIndex [expr $i + $cm_start]
		set dashIndex [expr $i + 1]
		set cxid  [expr $cmIndex + 6000]
		set newFileOut "CMTCPDSVIDEDO[expr $cxid + 0].out"
		#set tcpprinttime $printtime
		
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 1]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 1]]
		}
		
		#if {$TCL_DEBUG == 1} {
			puts "Build the DASH Video streaming flows: cxID: $cxid, cmIndex: $cmIndex, dashIndex: $dashIndex"
		#}

		#BuildTCPCxWithMode $ns $wrt_server $n($clientIndex) $CONCURRENT_VIDEO_TCP_CXs  $WEB_VIDEO_PACKETSIZE $WEB_VIDEO_BURSTTIME $WEB_VIDEO_IDLETIME $WEB_CBR_INTERVAL $WEB_VIDEO_BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut $statsHandle  $WEB_TCP_WINDOW  $WEB_VIDEO_SHAPE  $WEB_TCP_PROTOCOL $MODE $FLOW_PRIORITY
		create_netflix_flow $ns $CM($cmIndex) $dash_server($dashIndex) $WEB_VIDEO_PACKETSIZE $TARGET_VIDEO_RATE $aavginterval $vodapp_playback_buffer_capacity $cxid $flowStartTime  $tcpprinttime $newFileOut $statsHandle  $WINDOW $FLOW_PRIORITY $DASHMODE
	}
}

proc create_flow_set0_with_vodapp_flow { NUM_FLOWS ALL_UDP TRAFFIC_DIRECTION TRAFFIC_TYPE CBR_INTERVAL TARGET_VIDEO_RATE TCP_PROT_ID BADGUY_FLOWS_START_TIME BADGUY_FLOWS_STOP_TIME } {

	puts "Build a $NUM_FLOWS-flow set ..."
	
	# global variables this proc relies on
	global ns		; # ns simulator object
	global n2		; # wired node
	global CM		; # CM nodes

	# global variables for timeline
	global starttime1
	global printtime
	
	# global variables for TCP/UDP connections
	global PACKETSIZE BURSTTIME IDLETIME
	global WINDOW SHAPE FLOW_PRIORITY

	# DASH variables
	global vodapp_playback_buffer_capacity aavginterval DASHMODE startingServerRate

	if { $ALL_UDP == 1 } {
		puts "This proc is not for UDP flow creation."
		return
	}

	#
	# Configure UDP/TCP flows
	#
	for {set i 1} {$i <= $NUM_FLOWS} {incr i} {

		set CXN [expr $i + 10]
		set flowStartTime [expr $starttime1 + [uniform 0 2]]

		if { $ALL_UDP == 1 } {
			puts "ERROR - No UDP flow will be created."
		} else {

			set thruputFileOut "CMTCP[expr $CXN + 0].out"
			set statsFileOut "TCPstats.out"

			if { $TRAFFIC_DIRECTION == 0 } {	; # upstream flow
				BuildTCPCxWithMode $ns $CM($i) $n2 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime  $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
			} else {				; # downstream flow
				if { $i == 4 } {
					# Bad guy TCP flow needs to be CBR traffic instead of FTP
					#puts "Build a DS TCP BADGUY session (index:$i) ";
					set BADflowStartTime $BADGUY_FLOWS_START_TIME
					set BADflowStopTime $BADGUY_FLOWS_STOP_TIME
					#set BAD_PACKETSIZE 1460
					#set BAD_TARGET_VIDEO_RATE 24000000.0
					#set BAD_CBR_INTERVAL [expr $BAD_PACKETSIZE * 8 / $BAD_TARGET_VIDEO_RATE ]
					#set BAD_BURSTTIME $BURSTTIME
					#set BAD_IDLETIME $IDLETIME
					#set BAD_SHAPE $SHAPE
					#set BAD_MODE $CBR_TRAFFIC_MODE
					#BuildTCPCxWithMode $ns $n2 $CM($i) 1 $BAD_PACKETSIZE $BAD_BURSTTIME $BAD_IDLETIME $BAD_CBR_INTERVAL $BAD_TARGET_VIDEO_RATE $CXN $BADflowStartTime $BADflowStopTime $thruputFileOut $statsFileOut $WINDOW $BAD_SHAPE $TCP_PROT_ID $BAD_MODE $FLOW_PRIORITY
					# Bad guy netflix video flow
					set WEB_VIDEO_PACKETSIZE 1000
					set TARGET_VIDEO_RATE 3000000.0
					create_netflix_flow $ns $CM($i) $n2 $WEB_VIDEO_PACKETSIZE $TARGET_VIDEO_RATE $aavginterval $vodapp_playback_buffer_capacity $CXN $BADflowStartTime $BADflowStopTime $thruputFileOut $statsFileOut $WINDOW $FLOW_PRIORITY $DASHMODE
				} else {
					BuildTCPCxWithMode $ns $n2 $CM($i) 1 $PACKETSIZE $BURSTTIME $IDLETIME $CBR_INTERVAL $TARGET_VIDEO_RATE $CXN $flowStartTime $printtime $thruputFileOut $statsFileOut $WINDOW $SHAPE $TCP_PROT_ID $TRAFFIC_TYPE $FLOW_PRIORITY
				}
			}
			
		}
	}
	
	puts "Basic flow set created!"
}

proc create_lossmon_flow { DS_ON US_ON } {

	global ns
	global n1 n2
	
	global printtime
	
	#   l1 <<---l0 is Upstream (LMId 1 is US)
	#   l3 ---> l2 is Downstream (LMId 2 is DS)

	set echoFlag 0	; # 1 will cause an echo- this is the default behavior
	set bsize 1	; # specifying burst size

	set l0 [new Agent/VOIP_mon]
	$l0 set LMId 1
	set l2 [new Agent/VOIP_mon]
	$l2 set LMId 2

	# Setting for sending two 711 10ms chunks in one packet, :
	$l0 data-size 210
	$l2 data-size 210
	$l0 burst-size $bsize 
	$l2 burst-size $bsize 
	$l0 echo-mode $echoFlag
	$l2 echo-mode $echoFlag 

	# Client currently does not log any output
	$l2 set-outfile DSLossMon.out

	$ns attach-agent $n1 $l0
	$ns attach-agent $n1 $l2

	#   l1 <<---l0 is Upstream (LMId 1 is US)
	#   l3 ---> l2 is Downstream (LMId 2 is DS)

	set l1 [new Agent/VOIP_mon]
	$l1 set LMId 1
	set l3 [new Agent/VOIP_mon]
	$l3 set LMId 2

	# Setting for sending two 711 10ms chunks in one packet, :
	$l1 data-size 210
	$l3 data-size 210
	$l1 burst-size $bsize
	$l3 burst-size $bsize
	$l1 echo-mode $echoFlag
	$l3 echo-mode $echoFlag 

	$l1 set-outfile USLossMon.out

	$ns attach-agent $n2 $l1
	$ns attach-agent $n2 $l3

	# ----------------------------------

	# send 2 G.711 pkts every 20 ms
	#set burst_delay  .5
	set burst_delay  .02
	#set burst_delay  2
	set pkt_delay 0

	#set burst_delay  2
	#set pkt_delay 0
	# 1 ms
	#set pkt_delay .10
	set end_time [expr $printtime - .05]

	# Upstream loss monitor
	if { $US_ON > 0 } {
		$ns connect $l0 $l1
		startLburstProcess $ns $l0 $bsize $burst_delay $pkt_delay $end_time
		$ns at [expr $printtime - 0.1] "$l1 dumpresults 5"
	}
	
	# Downstream loss monitor
	if { $DS_ON > 0 } {
		$ns connect $l3 $l2
		startLburstProcess $ns $l3 $bsize $burst_delay $pkt_delay $end_time
		$ns at [expr $printtime - 0.1] "$l2 dumpresults 5"
	}
	
	puts "Loss_mon traffic created!"
}

proc create_wrt_lossmon_flow { DS_ON US_ON } {
# loss_monCM -----   ----  wrt_server
#                (DS)
#  l1     <----  LMId 1           l0
#
#                 (US)
#  l3     -----> LMId 2           l2

	global ns
	global wrt_server loss_monCM
	
	global printtime

        set echoFlag 0  ; # 1 will cause an echo- this is the default behavior
        set bsize 1     ; # specifying burst size

        set l0 [new Agent/VOIP_mon]
        $l0 set LMId 1
        set l2 [new Agent/VOIP_mon]
        $l2 set LMId 2

        # Setting for sending two 711 10ms chunks in one packet, :
        $l0 data-size 210
        $l2 data-size 210
        $l0 burst-size $bsize 
        $l2 burst-size $bsize 
        $l0 echo-mode $echoFlag
        $l2 echo-mode $echoFlag 

	#Client currently does not log any output
	#$l0 set-outfile loss_mon_cli1.out
	#$l2 set-outfile loss_mon_ser2.out
	
	$l2 set-outfile USLossMon.out

	$ns attach-agent $wrt_server $l0
	$ns attach-agent $wrt_server $l2

	set l1 [new Agent/VOIP_mon]
	$l1 set LMId 1
	set l3 [new Agent/VOIP_mon]
	$l3 set LMId 2
	
        # Setting for sending two 711 10ms chunks in one packet, :
        $l1 data-size 210
        $l3 data-size 210
        $l1 burst-size $bsize
        $l3 burst-size $bsize
        $l1 echo-mode $echoFlag
        $l3 echo-mode $echoFlag 

	$l1 set-outfile DSLossMon.out
	
	$ns attach-agent $loss_monCM $l1
	$ns attach-agent $loss_monCM $l3

        # send 2 G.711 pkts every 20 ms
        #set burst_delay  .5
        set burst_delay  .02
        #set burst_delay  2
        set pkt_delay 0

        #set burst_delay  2
        #set pkt_delay 0
        # 1 ms
        #set pkt_delay .10
	set end_time [expr  $printtime - 2]

        # Downstream loss monitor
        if { $DS_ON == 1 } {
                $ns connect $l0 $l1
                startLburstProcess $ns $l0 $bsize $burst_delay $pkt_delay $end_time
                $ns at [expr $printtime - 0.1] "$l1 dumpresults 5"
        }
        
        # Upstream loss monitor
        if { $US_ON == 1 } {
                $ns connect $l3 $l2
                startLburstProcess $ns $l3 $bsize $burst_delay $pkt_delay $end_time
                $ns at [expr $printtime - 0.1] "$l2 dumpresults 5"
        }

	puts "WRT loss_mon traffic created!"
}

proc create_ping_flow { TRAFFIC_DIRECTION } {

	global ns
	global n1 n2
	
	global printtime

	# US: p1 <--------- p0
	# DS: p0 ---------> p1
	
	set p0 [new Agent/Ping]		; # ping client
	set p1 [new Agent/Ping]		; # ping server
	
	if { $TRAFFIC_DIRECTION == 0 } {	; # upstream
		puts "Ping monitor upstream from n1 to n2"
		$ns attach-agent $n1 $p0
		$ns attach-agent $n2 $p1
	} else {				; # downstream
		puts "Ping monitor downstream from n2 to n1"
		$ns attach-agent $n2 $p0
		$ns attach-agent $n1 $p1
	}
	
	# Connect the two ping agents
	$ns connect $p0 $p1		; # p0 --> p1
	
	#can call startPingProcess which does a ping every interval
	#or have the recv schedule doPing ....
	
	# Start ping process with specified interval
	startPingProcess $ns $p0 10.0
	
	# Schedule to see ping summary
	$ns at $printtime "doPingStats"

	puts "Ping traffic created!"
}

proc create_wrt_ping_flow { up_node down_node printtime } {
	global ns

	set p0 [new Agent/Ping]
	$ns attach-agent $up_node $p0

	set p1 [new Agent/Ping]
	$ns attach-agent $down_node $p1

	#Connect the two agents
	$ns connect $p0 $p1

	startPingProcess $ns $p0 2

	$ns at $printtime "doPingStats"
	
	puts "WRT ping traffic created!"
}

proc create_udpmon_flow { TRAFFIC_DIRECTION } {

	global ns
	global n1 n2

	# US: udpsink0 <---------- udp0
	# DS: udp0 ----------> udpsink0
	
	set udp0 [new Agent/UDP]
	set udpsink0 [new Agent/UDPSink]

	if { $TRAFFIC_DIRECTION == 0 } {	; # Upstream
		puts "UDP monitor upstream flow from n1 to n2"
		$ns attach-agent $n2 $udpsink0
		$ns attach-agent $n1 $udp0
	} else {				; # Downstream
		puts "UDP monitor downstream flow from n2 to n1"
		$ns attach-agent $n1 $udpsink0
		$ns attach-agent $n2 $udp0
	}
	
	set cbr0 [new Application/Traffic/CBR]
	#  $cbr0 set packetSize_ 210
	#  $cbr0 set interval_ 0.02
	$cbr0 set packetSize_  210
	$cbr0 set interval_ 0.01
	#mode_ 1 will create CBR.send - see ./tools/cbr_traffic.cc
	#  $cbr0 set mode_ 1
	$cbr0 attach-agent $udp0
	
	$ns connect $udp0 $udpsink0
	
	$udpsink0 set fid_  1
	#Will create CBR.recv
	$udpsink0 set SinkId_  1
	
	set newUDPFileOut "UDPsink.out"
	exec rm -f $newUDPFileOut
	
	UDPTraceThroughput $ns $udpsink0  .5 $newUDPFileOut
	
	exec rm -f CBR.send
	exec rm -f CBR.recv
	$ns at .53210 "$cbr0 start"

	puts "UDP monitor traffic created."
}

proc create_web_flow_set { num_flows cm_start {sz_obj ""} } {

	global ns
	global CM		; # nodes
	global web_server
	
	global MYWEBSEED
	
	# Create page pool
	set pool [new PagePool/WebTraf]

	# Setup servers and clients
	$pool set-num-client $num_flows
	$pool set-num-server $num_flows
	puts "Web Page Pool num clients: $num_flows and num servers: $num_flows"
	for {set i 0} {$i < $num_flows} {incr i} {
		set cmIndex [expr $i + $cm_start]
		$pool set-client $i $CM($cmIndex)
		puts " ... Added CM($cmIndex) to the CLIENT Web Page Pool"
	}
	puts "added this number client: $i"
	for {set i 0} {$i < $num_flows} {incr i} {
		set wsIndex [expr $i + 1]
		$pool set-server $i $web_server($wsIndex)
		puts " ... Added web_server($wsIndex) to the SERVER Web Page Pool"
	}	
	puts "added this number server: $i"

	# Set web traffic RNG
	set WebTrafRNG [new RNG]
	$WebTrafRNG seed $MYWEBSEED

	# Inter-session Interval random variable
	set interSession [new RandomVariable/Exponential]
	$interSession set avg_ 1
	$interSession use-rng  $WebTrafRNG
	
	## Number of Pages per Session random variable
	set sessionSize [new RandomVariable/Constant]
	#JJM
	#$sessionSize set val_ 100
	$sessionSize set val_ 1000
	$sessionSize use-rng  $WebTrafRNG

	# Create sessions
	$pool set-num-session $num_flows
	set launchTime 0
	for {set i 0} {$i < $num_flows} {incr i} {
		# New RNG for each web user
		set WebSessionRNG [new RNG]
		$WebSessionRNG seed [expr $MYWEBSEED + $i]

		# Get a random number for number of pages to visit
		set numPage [$sessionSize value]
		puts "Session $i has $numPage pages"
		
		#	set interPage [new RandomVariable/Exponential]
		#	$interPage set avg_ 15
		set interPage [new RandomVariable/ParetoII]
		#JJM NEW
		#	$interPage set avg_ 10
		$interPage set avg_ 5
		$interPage set shape_ 2.0
		$interPage use-rng  $WebSessionRNG
		
		#	set pageSize [new RandomVariable/Constant]
		#	$pageSize set val_ 1
		set pageSize [new RandomVariable/ParetoII]
		#JJM
		#	$pageSize set avg_ 3
		#	$pageSize set shape_ 1.5
		$pageSize set avg_ 4
		$pageSize set shape_ 1.2
		$pageSize use-rng  $WebSessionRNG
		
		#	set interObj [new RandomVariable/Exponential]
		#	$interObj set avg_ 0.01
		set interObj [new RandomVariable/ParetoII]
		$interObj set avg_ .5
		$interObj set shape_ 1.5
		$interObj use-rng  $WebSessionRNG
		
		if {$sz_obj eq ""} {
			set objSize [new RandomVariable/ParetoII]
			#JJM NEW
			$objSize set avg_ 20
			$objSize set shape_ 1.5
			#	$objSize set avg_ 12
			#	$objSize set shape_ 1.2
			$objSize use-rng  $WebSessionRNG
		} else {
		    if {[expr $i % 3] == 0} {
			set objSize [new RandomVariable/Constant]
			$objSize set val_ $sz_obj
			$objSize use-rng  $WebSessionRNG
		    } else {
			set objSize [new RandomVariable/ParetoII]
			#JJM NEW
			$objSize set avg_ 20
			$objSize set shape_ 1.5
			#	$objSize set avg_ 12
			#	$objSize set shape_ 1.2
			$objSize use-rng  $WebSessionRNG
		    }
		}
		
		$pool create-session $i $numPage [expr $launchTime + 0.1] \
					$interPage $pageSize $interObj $objSize

		#This is probably better... 
		#	set launchTime [uniform .1 100]
		#but exp'7 - 12 didDO this ...
		#JJM
		set launchTime [uniform .01 .1]
		#	set launchTime [uniform .1 2]
		#	set launchTime [expr $launchTime + [$interSession value]]
	}

	# $pool set-interPageOption 0; # 0 for time between the start of 2 pages
		                       # 1 for time between the end of a page and 
		                       #   the start of the next
		                       # default: 1

	puts "Web flows created!"
}

proc create_web_sessions { num_sessions cm_index } {

	global ns
	global n	; # nodes
	global MYSEED MYWEBSEED
	
	# global variable this proc generates
	global firstWebBrowserIndex
	
	set firstWebBrowserIndex $cm_index

	# Create page pool
	set pool [new PagePool/WebTraf]

	# Setup servers and clients
	# After cable topology is created, 'ns' member variables:
	#	src_ contains a list of web clients (CMs)
	#	dst_ contains a list of web servers
	$pool set-num-client [llength [$ns set src_]]
	$pool set-num-server [llength [$ns set dst_]]
	puts "Web Page Pool num clients: [$ns set src_] and num servers: [$ns set dst_]"
	set i 0
	foreach s [$ns set src_] {
		$pool set-client $i $n($s)
		puts " ... Added this node  to the CLIENT Web Page Pool $s"
		incr i
	}
	puts "added this number client: $i"
	set i 0
	foreach s [$ns set dst_] {
		$pool set-server $i $n($s)
		puts " ... Added this node to the SERVER Web Page Pool $s"
		incr i
	}
	puts "added this number server: $i"

	# Change NS default RNG seed
	ns-random  $MYSEED 

	# Other RNGs
	#set BTRNG [new RNG]
	#$BTRNG seed 1598189534
	set WebTrafRNG [new RNG]
	$WebTrafRNG seed $MYWEBSEED

	# Inter-session Interval
	set interSession [new RandomVariable/Exponential]
	$interSession set avg_ 1
	$interSession use-rng  $WebTrafRNG
	
	## Number of Pages per Session
	set sessionSize [new RandomVariable/Constant]
	#JJM
	#$sessionSize set val_ 100
	$sessionSize set val_ 1000
	$sessionSize use-rng  $WebTrafRNG

	# Create sessions
	$pool set-num-session $num_sessions
	set launchTime 0
	for {set i 0} {$i < $num_sessions} {incr i} {
		# New RNG for each web user
		set WebSessionRNG [new RNG]
		$WebSessionRNG seed [expr $MYWEBSEED + $i]

		# Get a random number for number of pages to visit
		set numPage [$sessionSize value]
		puts "Session $i has $numPage pages"
		
		#	set interPage [new RandomVariable/Exponential]
		#	$interPage set avg_ 15
		set interPage [new RandomVariable/ParetoII]
		#JJM NEW
		#	$interPage set avg_ 10
		$interPage set avg_ 5
		$interPage set shape_ 2.0
		$interPage use-rng  $WebSessionRNG
		
		#	set pageSize [new RandomVariable/Constant]
		#	$pageSize set val_ 1
		set pageSize [new RandomVariable/ParetoII]
		#JJM
		#	$pageSize set avg_ 3
		#	$pageSize set shape_ 1.5
		$pageSize set avg_ 4
		$pageSize set shape_ 1.2
		$pageSize use-rng  $WebSessionRNG
		
		#	set interObj [new RandomVariable/Exponential]
		#	$interObj set avg_ 0.01
		set interObj [new RandomVariable/ParetoII]
		$interObj set avg_ .5
		$interObj set shape_ 1.5
		$interObj use-rng  $WebSessionRNG
		
		set objSize [new RandomVariable/ParetoII]
		#JJM NEW
		$objSize set avg_ 20
		$objSize set shape_ 1.5
		#	$objSize set avg_ 12
		#	$objSize set shape_ 1.2
		$objSize use-rng  $WebSessionRNG
		
		$pool create-session $i $numPage [expr $launchTime + 0.1] \
					$interPage $pageSize $interObj $objSize

		#This is probably better... 
		#	set launchTime [uniform .1 100]
		#but exp'7 - 12 didDO this ...
		#JJM
		set launchTime [uniform .01 .1]
		#	set launchTime [uniform .1 2]
		#	set launchTime [expr $launchTime + [$interSession value]]
	}

	# $pool set-interPageOption 0; # 0 for time between the start of 2 pages
		                       # 1 for time between the end of a page and 
		                       #   the start of the next
		                       # default: 1

	puts "Web sessions created!"
}

proc create_DS_FTP_sessions_wrt_server { num_sessions num_concurrent_tcp cm_index } {
	global TCL_DEBUG
	
	global ns
	global n	; # nodes
	global wrt_server
	
	global PACKETSIZE BURSTTIME IDLETIME BURSTRATE SHAPE WINDOW
	global TCP_PROT_ID FTP_TRAFFIC_MODE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY
	
	# global variables for timelines
	global printtime tprinttime
	
	set FLOW_PRIORITY $PRIORITY_LOW
	set statsFileOut "DSFTPTCPstats.out"
	
	exec rm -f $statsFileOut
	
	puts "Build $num_sessions DS FTP sessions using stats file: $statsFileOut, index: $cm_index"
	
	for {set i 0} {$i < [expr $num_sessions - 0]} {incr i} {
	
		set clientIndex [expr $i + $cm_index]
		set cxid  [expr [expr [expr $num_concurrent_tcp -0] *  $i] + $clientIndex + 1000]
		set newFileOut "CMTCPDS[expr $cxid + 0].out"
		set tcpprinttime $tprinttime
		
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}

		if {$TCL_DEBUG == 1} {
			puts "Build this many DS TCP sessions:  $num_sessions,   number concurrent: $num_concurrent_tcp"
			puts "The client index is $clientIndex"
			puts "build $num_concurrent_tcp DS TCP flows with cxid of $cxid and node array clientIndex of $clientIndex and start time $flowStartTime "
		}
		
		#      BuildTCPCx $ns $wrt_server $n($clientIndex) $CONCURRENTTCP $PACKETSIZE $BURSTTIME $IDLETIME $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut  $WINDOW  $SHAPE  $protID
		BuildTCPCxWithMode $ns $wrt_server $n($clientIndex) $num_concurrent_tcp $PACKETSIZE $BURSTTIME $IDLETIME 0  $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut $statsFileOut  $WINDOW  $SHAPE  $TCP_PROT_ID $FTP_TRAFFIC_MODE $FLOW_PRIORITY
	}
	
	puts "DS FTP sessions sourced from wrt_server created!"
}

proc create_DS_FTP_sessions_ftp_server { num_sessions num_concurrent_tcp cm_index } {
	global TCL_DEBUG
	
	global ns
	global n	; # nodes
	global ftp_server
	
	global PACKETSIZE BURSTTIME IDLETIME BURSTRATE SHAPE WINDOW
	global TCP_PROT_ID FTP_TRAFFIC_MODE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY
	
	# global variables for timelines
	global printtime tprinttime
	
	set FLOW_PRIORITY $PRIORITY_LOW
	set statsFileOut "DSFTPTCPstats.out"
	
	exec rm -f $statsFileOut
	
	puts "Build $num_sessions DS FTP sessions using stats file: $statsFileOut, index: $cm_index"
	
	for {set i 0} {$i < [expr $num_sessions - 0]} {incr i} {
	
		set clientIndex [expr $i + $cm_index]
		set cxid  [expr [expr [expr $num_concurrent_tcp -0] *  $i] + $clientIndex + 1000]
		set newFileOut "CMTCPDS[expr $cxid + 0].out"
		set tcpprinttime $tprinttime
		
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}

		if {$TCL_DEBUG == 1} {
			puts "Build this many DS TCP sessions:  $num_sessions,   number concurrent: $num_concurrent_tcp"
			puts "The client index is $clientIndex"
			puts "build $num_concurrent_tcp DS TCP flows with cxid of $cxid and node array clientIndex of $clientIndex and start time $flowStartTime "
		}
		
		#      BuildTCPCx $ns $wrt_server $n($clientIndex) $CONCURRENTTCP $PACKETSIZE $BURSTTIME $IDLETIME $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut  $WINDOW  $SHAPE  $protID
		BuildTCPCxWithMode $ns $ftp_server($i) $n($clientIndex) $num_concurrent_tcp $PACKETSIZE $BURSTTIME $IDLETIME 0  $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut $statsFileOut  $WINDOW  $SHAPE  $TCP_PROT_ID $FTP_TRAFFIC_MODE $FLOW_PRIORITY
	}
	
	puts "DS FTP sessions sourced from ftp_server created!"
}

proc create_US_FTP_sessions { num_sessions num_concurrent_tcp cm_index } {
	global TCL_DEBUG

	global ns
	global n	; # nodes
	global wrt_server
	
	global PACKETSIZE BURSTTIME IDLETIME BURSTRATE SHAPE WINDOW
	global TCP_PROT_ID FTP_TRAFFIC_MODE

	# global variables for timelines
	global printtime tprinttime

	puts "Build $num_sessions US FTP sessions (CMListIndex:$cm_index)";
	
	for {set i 0} {$i < [expr $num_sessions - 0]} {incr i} {
		set clientIndex [expr $i + $cm_index]
		set cxid  [expr [expr [expr $num_concurrent_tcp -0] *  $i] + $clientIndex + 2000]
		set newFileOut "CMTCPUS[expr $cxid + 0].out"
		set tcpprinttime $tprinttime
		
		exec rm -f $newFileOut

		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}

		if {$TCL_DEBUG == 1} {
			puts "Build this many US TCP sessions:  $num_sessions,   number concurrent: $num_concurrent_tcp"
			puts "The client index is $clientIndex"
			puts "build $num_concurrent_tcp US TCP flows with cxid of $cxid "
		}
		
		BuildTCPCx $ns  $n($clientIndex) $wrt_server  $num_concurrent_tcp $PACKETSIZE $BURSTTIME $IDLETIME $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut  $WINDOW  $SHAPE  $TCP_PROT_ID
	}
	
	puts "US FTP sessions created!"
}

proc create_BT_sessions { num_sessions num_concurrent_p2p cm_index } {
	global TCL_DEBUG
	
	global ns
	global n	; # nodes
	global BTServerNodes
	
	global firstBTS lastBTS BTtestNode
	global firstServerID lastServerID
	global firstClientID lastClientID

	global BADGUY_BT_FLOWS_START_TIME BADGUY_BT_FLOWS_STOP_TIME
	
	global BTBURSTRATE BTBURSTTIME BTIDLETIME P2PWINDOW TCP_PROT_ID
	
	global DOWNSTREAM_BT_ONLY
	
	# global variable this proc generates
	global firstBTIndex

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY
	
	# global variables for timelines
	global stoptime

	set targetP2PSessions $num_sessions
	
	set firstBTIndex $cm_index
	
	set FLOW_PRIORITY $PRIORITY_LOW

	if {$TCL_DEBUG == 1} {
		puts "Build this many BT sessions: $targetP2PSessions (CMListIndex:$cm_index)";
		puts "The firstServerID is $firstServerID"
		puts "The firstClientID is  $firstClientID"
		puts "The firstBTS is  $firstBTS"
		puts "The lastBTS is  $lastBTS"
	}

	set srcNode  $firstBTS;
	set dstNode  $cm_index
	
	if {$TCL_DEBUG == 1} {
		puts "set the first dstNode at: $dstNode"
		puts "set the first srcNode at: $srcNode"
	}
	
	set asymIndex 1;
	#This is US BW / DS BW
	#if 0 it means all DS
	set asymLevel 1;

	for {set i 1} {$i <= $targetP2PSessions} {incr i} {
	
		if {$BADGUY_BT_FLOWS_START_TIME == 0} {
			set BTstarttime  [uniform 1.2 5]
			set BTstoptime   $stoptime
		} else {
			set BTstarttime  [expr $BADGUY_BT_FLOWS_START_TIME + [uniform .5 2]]
			set BTstoptime  [expr $BADGUY_BT_FLOWS_STOP_TIME - [uniform .5 2]]
		}
		
		#Note: src and dst Node mixed up
		for {set j 0} {$j < $num_concurrent_p2p} {incr j} {
			incr srcNode;
			if { $srcNode > $lastBTS } {
				set srcNode  $firstBTS;
			}
			
			#       puts "Build this  BT session: src:$srcNode and dst:$dstNode"
			#note BT-helper wil identify DS cxids by adding 500 to the cxid
			
			set cxid [expr 4000 + [expr $i * 10] + $j]
			set newFileOutDS "CMBTDS[expr $cxid + 500].out"
			set newFileOutUS "CMBTUS[expr $cxid + 0].out"
			
			exec rm -f $newFileOutDS
			exec rm -f $newFileOutUS
			
			#2/3's of the BTs make the US flow higher
			set tmpX [uniform [expr $BTBURSTRATE / 10]  $BTBURSTRATE]
			
			#We want to force a range of common behaviors 
			if {$asymIndex == 1} {
				set asymLevel [uniform .95 1.05]
			}
			if {$asymIndex == 2} {
				set asymLevel [uniform .9 1.1]
			}
			if {$asymIndex == 3} {
				set asymLevel [uniform 1.7 2]
			}
			if {$asymIndex == 4} {
				set asymLevel [uniform .3 .5]
			}
			
			incr asymIndex
			if {$asymIndex > 4} {
				set asymIndex 1
			}
			
			if { $DOWNSTREAM_BT_ONLY == 1} {
				set asymLevel  0
			}
			
			#if {$TCL_DEBUG == 1} {
				puts "Build NEW BT session: (srcNode,dstNode:$srcNode,$dstNode):  burstRate:$tmpX, asymIndex:$asymIndex, asymLevel:$asymLevel (dstNode:$dstNode,  BTServer index:$srcNode"
			#}
			
			BuildBTCxs $ns $n($dstNode) $BTServerNodes($srcNode) 1 $BTBURSTTIME $BTIDLETIME $tmpX $cxid $BTstarttime  $stoptime $P2PWINDOW $TCP_PROT_ID $asymLevel 0 1 $newFileOutDS $newFileOutUS $FLOW_PRIORITY
		}

		incr srcNode;
		incr dstNode;
		if { $srcNode >= $lastBTS } {
			set srcNode  $firstBTS;
		}
	}

	puts "BT sessions created!"
}

proc create_DS_UDP_sessions { num_sessions cm_index } {
	global TCL_DEBUG
	
	global ns
	global n	; # nodes
	global wrt_server
	
	global BADGUY_UDP_FLOWS_START_TIME BADGUY_UDP_FLOWS_STOP_TIME

	global PACKETSIZE BURSTTIME IDLETIME BURSTRATE SHAPE WINDOW
	global CBR_TRAFFIC_MODE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY

	# global variables for timelines
	global printtime

	set statsFileOut "DSUDPstats.out"
	
	exec rm -f $statsFileOut
	
	if {$TCL_DEBUG == 1} {
		puts "Build $num_sessions DS UDP sessions (CMListIndex:$cm_index)";
	}
	
	set DSUDP_PACKETSIZE 1460
	set DSUDP_TARGET_VIDEO_RATE 3000000.0
	set DSUDP_CBR_INTERVAL [expr $DSUDP_PACKETSIZE * 8 / $DSUDP_TARGET_VIDEO_RATE ]
	set DSUDP_BURSTTIME $BURSTTIME
	set DSUDP_IDLETIME $IDLETIME
	set DSUDP_SHAPE $SHAPE
	set DSUDP_MODE $CBR_TRAFFIC_MODE
	
	set FLOW_PRIORITY $PRIORITY_HIGH
	
	for {set i 0} {$i < [expr $num_sessions - 0]} {incr i} {
		set clientIndex [expr $i + $cm_index]
		set cxid  [expr $clientIndex + 5000]
		set newFileOut "CMUDPDS[expr $cxid + 0].out"
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}
		
		#BADGUY_FLOW
		#To create a bad guy flow
		if { ($i == 1) && ($BADGUY_UDP_FLOWS_START_TIME >0)} {
			set BAD_FlowStartTime $BADGUY_UDP_FLOWS_START_TIME
			set BAD_FlowStopTime $BADGUY_UDP_FLOWS_STOP_TIME
			set BAD_PACKETSIZE 1460
			set BAD_TARGET_VIDEO_RATE 20000000.0
			set BAD_CBR_INTERVAL [expr $BAD_PACKETSIZE * 8 / $BAD_TARGET_VIDEO_RATE ]
			set BAD_BURSTTIME $BURSTTIME
			set BAD_IDLETIME $IDLETIME
			set BAD_SHAPE $SHAPE
			set BAD_MODE $CBR_TRAFFIC_MODE
			set BAD_FLOW_PRIORITY $FLOW_PRIORITY
			puts "Build $num_sessions DS UDP BADGUY sessions (CMListIndex:$cm_index), priority is $BAD_FLOW_PRIORITY";
			BuildUDPCxWithMode $ns $wrt_server $n($clientIndex)  1 $BAD_PACKETSIZE $BAD_BURSTTIME $BAD_IDLETIME  $BAD_CBR_INTERVAL $BAD_TARGET_VIDEO_RATE  $cxid $BAD_FlowStartTime $BAD_FlowStopTime $newFileOut $statsFileOut $BAD_SHAPE $BAD_MODE $BAD_FLOW_PRIORITY
		} else {
			if {$TCL_DEBUG == 1} {
				puts "Build this many DS UDP sessions:  $num_sessions"
				puts "The client index is $clientIndex"
			}
			puts "Build $num_sessions DS UDP sessions (CMListIndex:$cm_index), priority is $FLOW_PRIORITY";
			#first node is source, second is sink 
			BuildUDPCxWithMode $ns $wrt_server $n($clientIndex)  1 $DSUDP_PACKETSIZE $DSUDP_BURSTTIME $DSUDP_IDLETIME  $DSUDP_CBR_INTERVAL $DSUDP_TARGET_VIDEO_RATE  $cxid $flowStartTime $printtime $newFileOut $statsFileOut $DSUDP_SHAPE $DSUDP_MODE $FLOW_PRIORITY
		}
	}
}

proc create_DS_UDP_bad_flow { src cm_index pkt_size flow_rate } {
	global TCL_DEBUG
	
	global ns
	global CM	; # CM nodes
	
	global BADGUY_UDP_FLOWS_START_TIME BADGUY_UDP_FLOWS_STOP_TIME

	global BURSTTIME IDLETIME BURSTRATE SHAPE WINDOW
	global CBR_TRAFFIC_MODE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY

	# global variables for timelines
	global printtime

	set statsFileOut "DSUDPstats.out"
	
	exec rm -f $statsFileOut
	
	set FLOW_PRIORITY $PRIORITY_HIGH
	
	set BAD_FlowStartTime [expr 0.5 + [uniform 0 2] + $BADGUY_UDP_FLOWS_START_TIME ]
	set BAD_FlowStopTime $BADGUY_UDP_FLOWS_STOP_TIME
	set BAD_PACKETSIZE $pkt_size
	set BAD_TARGET_VIDEO_RATE $flow_rate
	set BAD_CBR_INTERVAL [expr 8.0 * $BAD_PACKETSIZE / $BAD_TARGET_VIDEO_RATE ]
	set BAD_BURSTTIME $BURSTTIME
	set BAD_IDLETIME $IDLETIME
	set BAD_SHAPE $SHAPE
	set BAD_MODE $CBR_TRAFFIC_MODE
	set BAD_FLOW_PRIORITY $FLOW_PRIORITY
puts "BAD_CBR_INTERVAL=$BAD_CBR_INTERVAL"
	
	set cxid  [expr $cm_index + 5000]
	set newFileOut "CMUDPDS[expr $cxid + 0].out"
	exec rm -f $newFileOut
	
	puts "WINDOW = $WINDOW"
	puts "Build a DS UDP BADGUY sessions (CMListIndex:$cm_index), priority is $BAD_FLOW_PRIORITY";

	BuildUDPCxWithMode $ns $src $CM($cm_index)  1 $BAD_PACKETSIZE $BAD_BURSTTIME $BAD_IDLETIME  $BAD_CBR_INTERVAL $BAD_TARGET_VIDEO_RATE  $cxid $BAD_FlowStartTime $BAD_FlowStopTime $newFileOut $statsFileOut $BAD_SHAPE $BAD_MODE $BAD_FLOW_PRIORITY
}

proc create_web_video_sessions { num_sessions cm_index } {
#    Right now, just a CBR stream over TCP
	global TCL_DEBUG
	
	global ns
	global n	; # nodes
	global wrt_server
	
	global MULTI_APP_MODE firstWebBrowserIndex firstBTIndex
	
	global WINDOW

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY

	# global variables for timelines
	global printtime tprinttime

	#0 is Exponential- trying to model progressive video downloads
	#1 is CBR/TCP
	#2 is FTP
	set MODE 0
	set WEB_TCP_PROTOCOL 9
	#  set WEB_TCP_PROTOCOL 1
	set WEB_TCP_WINDOW $WINDOW
	set CONCURRENT_VIDEO_TCP_CXs 1
	set TARGET_VIDEO_RATE 3000000.0
	set WEB_VIDEO_BURSTTIME .1
	set WEB_VIDEO_IDLETIME   1.0
	set tmpX  [expr $TARGET_VIDEO_RATE * [expr $WEB_VIDEO_BURSTTIME + $WEB_VIDEO_IDLETIME]]
	set WEB_VIDEO_BURSTRATE  [expr $tmpX / $WEB_VIDEO_BURSTTIME]
	#  set WEB_VIDEO_BURSTRATE   33000000
	set WEB_VIDEO_SHAPE 0
	set WEB_VIDEO_PACKETSIZE 1000
	
	set FLOW_PRIORITY $PRIORITY_HIGH

	#if zero use EXP model, else CBR
	set WEB_CBR_INTERVAL [expr $WEB_VIDEO_PACKETSIZE * 8 / $TARGET_VIDEO_RATE ]
	#set WEB_CBR_INTERVAL 0

	set tcpprinttime $tprinttime

	#if {$TCL_DEBUG == 1} {
		puts "Build $num_sessions DS Web Video Streaming  sessions (CMListIndex:$cm_index, target rate: $TARGET_VIDEO_RATE, Video burst rate: $WEB_VIDEO_BURSTRATE, Interval:$WEB_CBR_INTERVAL)";
	#}
	
	set statsHandle "VIDEOTCPstats.out"
	exec rm -f $statsHandle
	for {set i 0} {$i < [expr $num_sessions - 0]} {incr i} {
	
		#If multiple flows desired, locate web video flows with either web users or BT users
		if { $MULTI_APP_MODE == 1 } {
			set clientIndex [expr $i + $firstWebBrowserIndex]
			puts "Build $num_sessions BUT place them with first web browser nodes (clientIndex:$clientIndex, CMListIndex:$cm_index"
		} elseif { $MULTI_APP_MODE == 2 } {
			set clientIndex [expr $i + $firstBTIndex]
			puts "Build $num_sessions BUT place them starting with the first BT nodes (clientIndex:$clientIndex, CMListIndex:$cm_index"
		} else {
			set clientIndex [expr $i + $cm_index]
		}
		
		set cxid  [expr [expr [expr $CONCURRENT_VIDEO_TCP_CXs -0] *  $i] + $clientIndex + 6000]
		
		set newFileOut "CMTCPVIDEODS[expr $cxid + 0].out"
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}
		
		#if {$TCL_DEBUG == 1} {
			puts "Build the TCP Video streaming  sessions: cxID:$cxid,  clientIndex:$clientIndex, bursttime:$WEB_VIDEO_BURSTTIME, idleTime:$WEB_VIDEO_IDLETIME, burstRate:$WEB_VIDEO_BURSTRATE"
		#}

		BuildTCPCxWithMode $ns $wrt_server $n($clientIndex) $CONCURRENT_VIDEO_TCP_CXs  $WEB_VIDEO_PACKETSIZE $WEB_VIDEO_BURSTTIME $WEB_VIDEO_IDLETIME $WEB_CBR_INTERVAL $WEB_VIDEO_BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut $statsHandle  $WEB_TCP_WINDOW  $WEB_VIDEO_SHAPE  $WEB_TCP_PROTOCOL $MODE $FLOW_PRIORITY
	}
}

proc create_netflix_video_sessions { num_sessions cm_index } {

	global TCL_DEBUG
	
	global ns
	global n	; # nodes
	global wrt_server
	
	global MULTI_APP_MODE firstWebBrowserIndex firstBTIndex
	
	global WINDOW PACKETSIZE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY

	# global variables for timelines
	global printtime tprinttime
	
	# DASH variables
	global vodapp_playback_buffer_capacity aavginterval DASHMODE startingServerRate

	set CONCURRENT_VIDEO_TCP_CXs 1
	#set TARGET_VIDEO_RATE 3000000.0
	set TARGET_VIDEO_RATE $startingServerRate
	#set WEB_VIDEO_PACKETSIZE 1000
	set WEB_VIDEO_PACKETSIZE $PACKETSIZE
	
	set FLOW_PRIORITY $PRIORITY_HIGH

	set tcpprinttime $tprinttime

	#if {$TCL_DEBUG == 1} {
		puts "Build $num_sessions Netflix Video Streaming  sessions (CMListIndex:$cm_index, target rate: $TARGET_VIDEO_RATE)";
	#}
	
	set statsHandle "VIDEOTCPstats.out"
	exec rm -f $statsHandle
	for {set i 0} {$i < [expr $num_sessions - 0]} {incr i} {
	
		#If multiple flows desired, locate web video flows with either web users or BT users
		if { $MULTI_APP_MODE == 1 } {
			set clientIndex [expr $i + $firstWebBrowserIndex]
			puts "Build $num_sessions BUT place them with first web browser nodes (clientIndex:$clientIndex, CMListIndex:$cm_index"
		} elseif { $MULTI_APP_MODE == 2 } {
			set clientIndex [expr $i + $firstBTIndex]
			puts "Build $num_sessions BUT place them starting with the first BT nodes (clientIndex:$clientIndex, CMListIndex:$cm_index"
		} else {
			set clientIndex [expr $i + $cm_index]
		}
		
		set cxid  [expr [expr [expr $CONCURRENT_VIDEO_TCP_CXs -0] *  $i] + $clientIndex + 6000]
		
		set newFileOut "CMTCPVIDEODS[expr $cxid + 0].out"
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}
		
		#if {$TCL_DEBUG == 1} {
			puts "Build the Netflix Video streaming  sessions: cxID:$cxid,  clientIndex:$clientIndex"
		#}

		#BuildTCPCxWithMode $ns $wrt_server $n($clientIndex) $CONCURRENT_VIDEO_TCP_CXs  $WEB_VIDEO_PACKETSIZE $WEB_VIDEO_BURSTTIME $WEB_VIDEO_IDLETIME $WEB_CBR_INTERVAL $WEB_VIDEO_BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut $statsHandle  $WEB_TCP_WINDOW  $WEB_VIDEO_SHAPE  $WEB_TCP_PROTOCOL $MODE $FLOW_PRIORITY
		create_netflix_flow $ns $n($clientIndex) $wrt_server $WEB_VIDEO_PACKETSIZE $TARGET_VIDEO_RATE $aavginterval $vodapp_playback_buffer_capacity $cxid $flowStartTime  $tcpprinttime $newFileOut $statsHandle  $WINDOW $FLOW_PRIORITY $DASHMODE
	}
}

proc create_adaptive_netflix_video_sessions { num_videos cm_index } {

	global TCL_DEBUG
	
	global ns
	global n	; # nodes
	#global wrt_server
	
	global WINDOW PACKETSIZE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY

	# global variables for timelines
	global printtime tprinttime
	
	# DASH variables
	global vodapp_playback_buffer_capacity aavginterval DASHMODE startingServerRate

	set CONCURRENT_VIDEO_TCP_CXs 1
	#set TARGET_VIDEO_RATE 3000000.0
	set TARGET_VIDEO_RATE $startingServerRate
	#set WEB_VIDEO_PACKETSIZE 1000
	set WEB_VIDEO_PACKETSIZE $PACKETSIZE
	
	set FLOW_PRIORITY $PRIORITY_HIGH

	set tcpprinttime $tprinttime

	#if {$TCL_DEBUG == 1} {
		#puts "Build $num_sessions Netflix Video Streaming  sessions (CMListIndex:$cm_index, target rate: $TARGET_VIDEO_RATE)";
		puts "Build Netflix Video Streaming adaptive sessions (NUM_VIDEOS: $num_videos, CMListIndex: $cm_index)"
	#}
	
	set statsHandle "VIDEOTCPstats.out"
	exec rm -f $statsHandle
	
	# Use this index to source videos from different servers
	set srv_offset		6	; # servers start at this index
	
	# Use these two variables to distribute video server allocations among routers
	set row		0	; # for router indexing (0 .. 3)
	set col		0	; # for server indexing (0 .. 9)
	
	# Create videos - session number starts at 70000
	set clientIndex	[expr 0 + $cm_index]
	for {set i 0} {$i < [expr $num_videos - 0]} {incr i} {
		# which server to use?
		set srv [expr $row * 10 + $col + $srv_offset]
		incr row			; # use server on next router
		if {$row >= 4} {		; # wrapped around?
			set row 0
			incr col		; # use next server on the same router
			if {$col >= 10} {	; # wrapped around?
				set col 0
			}
		}
		
		set cxid  	[expr $clientIndex * 100 + $srv + 70000]
		
		set newFileOut "CMTCPVIDEODS[expr $cxid + 0].out"
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}
		
		puts "Build the Netflix Video streaming  sessions: cxID:$cxid,  clientIndex:$clientIndex"
		create_netflix_flow $ns $n($clientIndex) $n($srv) $WEB_VIDEO_PACKETSIZE $TARGET_VIDEO_RATE $aavginterval $vodapp_playback_buffer_capacity $cxid $flowStartTime  $tcpprinttime $newFileOut $statsHandle  $WINDOW $FLOW_PRIORITY $DASHMODE
		
		incr clientIndex
	}
	set cm_index	$clientIndex
	
}

proc create_non_adaptive_netflix_video_sessions { num_low_defs num_med_defs num_std_defs num_hi_defs num_uhi_defs cm_index } {

	global TCL_DEBUG
	
	global ns
	global n	; # nodes
	#global wrt_server
	
	global WINDOW PACKETSIZE

	# global variables this proc may change
	global PRIORITY_HIGH PRIORITY_LOW FLOW_PRIORITY

	# global variables for timelines
	global printtime tprinttime
	
	# DASH variables
	global vodapp_playback_buffer_capacity aavginterval DASHMODE startingServerRate

	set CONCURRENT_VIDEO_TCP_CXs 1
	#set TARGET_VIDEO_RATE 3000000.0
	set TARGET_VIDEO_RATE $startingServerRate
	#set WEB_VIDEO_PACKETSIZE 1000
	set WEB_VIDEO_PACKETSIZE $PACKETSIZE
	
	set FLOW_PRIORITY $PRIORITY_HIGH

	set tcpprinttime $tprinttime

	#if {$TCL_DEBUG == 1} {
		#puts "Build $num_sessions Netflix Video Streaming  sessions (CMListIndex:$cm_index, target rate: $TARGET_VIDEO_RATE)";
		puts "Build Netflix Video Streaming non-adaptive sessions (LD: $num_low_defs, MD: $num_med_defs, SD: $num_std_defs, HD: $num_hi_defs, UHD: $num_uhi_defs, CMListIndex: $cm_index)"
	#}
	
	set statsHandle "VIDEOTCPstats.out"
	exec rm -f $statsHandle
	
	# Use this index to source videos from different servers
	set srv_offset		6	; # servers start at this index
	
	# Use these two variables to distribute video server allocations among routers
	set row		0	; # for router indexing (0 .. 3)
	set col		0	; # for server indexing (0 .. 9)
	
	# Create LD videos - session number starts at 10000
	set clientIndex	[expr 0 + $cm_index]
	for {set i 0} {$i < [expr $num_low_defs - 0]} {incr i} {
		# which server to use?
		set srv [expr $row * 10 + $col + $srv_offset]
		incr row			; # use server on next router
		if {$row >= 4} {		; # wrapped around?
			set row 0
			incr col		; # use next server on the same router
			if {$col >= 10} {	; # wrapped around?
				set col 0
			}
		}
		
		set cxid  	[expr $clientIndex * 100 + $srv + 10000]
		
		set newFileOut "CMTCPVIDEODS[expr $cxid + 0].out"
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}
		
		puts "Build the Netflix Video streaming  sessions: cxID:$cxid,  clientIndex:$clientIndex"
		create_netflix_flow $ns $n($clientIndex) $n($srv) $WEB_VIDEO_PACKETSIZE $TARGET_VIDEO_RATE $aavginterval $vodapp_playback_buffer_capacity $cxid $flowStartTime  $tcpprinttime $newFileOut $statsHandle  $WINDOW $FLOW_PRIORITY $DASHMODE 1
		
		#incr srv
		incr clientIndex
	}
	set cm_index	$clientIndex
	
	# Create MD videos - session number starts at 20000
	set clientIndex	[expr 0 + $cm_index]
	for {set i 0} {$i < [expr $num_med_defs - 0]} {incr i} {
		# which server to use?
		set srv [expr $row * 10 + $col + $srv_offset]
		incr row			; # use server on next router
		if {$row >= 4} {		; # wrapped around?
			set row 0
			incr col		; # use next server on the same router
			if {$col >= 10} {	; # wrapped around?
				set col 0
			}
		}
		
		set cxid  	[expr $clientIndex * 100 + $srv + 20000]
		
		set newFileOut "CMTCPVIDEODS[expr $cxid + 0].out"
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}
		
		puts "Build the Netflix Video streaming  sessions: cxID:$cxid,  clientIndex:$clientIndex"
		create_netflix_flow $ns $n($clientIndex) $n($srv) $WEB_VIDEO_PACKETSIZE $TARGET_VIDEO_RATE $aavginterval $vodapp_playback_buffer_capacity $cxid $flowStartTime  $tcpprinttime $newFileOut $statsHandle  $WINDOW $FLOW_PRIORITY $DASHMODE 2
		
		#incr srv
		incr clientIndex
	}
	set cm_index	$clientIndex
	
	# Create SD videos - session number starts at 30000
	set clientIndex	[expr 0 + $cm_index]
	for {set i 0} {$i < [expr $num_std_defs - 0]} {incr i} {
		# which server to use?
		set srv [expr $row * 10 + $col + $srv_offset]
		incr row			; # use server on next router
		if {$row >= 4} {		; # wrapped around?
			set row 0
			incr col		; # use next server on the same router
			if {$col >= 10} {	; # wrapped around?
				set col 0
			}
		}
		
		set cxid  	[expr $clientIndex * 100 + $srv + 30000]
		
		set newFileOut "CMTCPVIDEODS[expr $cxid + 0].out"
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}
		
		puts "Build the Netflix Video streaming  sessions: cxID:$cxid,  clientIndex:$clientIndex"
		create_netflix_flow $ns $n($clientIndex) $n($srv) $WEB_VIDEO_PACKETSIZE $TARGET_VIDEO_RATE $aavginterval $vodapp_playback_buffer_capacity $cxid $flowStartTime  $tcpprinttime $newFileOut $statsHandle  $WINDOW $FLOW_PRIORITY $DASHMODE 3
		
		#incr srv
		incr clientIndex
	}
	set cm_index	$clientIndex
	
	# Create HD videos - session number starts at 40000
	set clientIndex	[expr 0 + $cm_index]
	for {set i 0} {$i < [expr $num_hi_defs - 0]} {incr i} {
		# which server to use?
		set srv [expr $row * 10 + $col + $srv_offset]
		incr row			; # use server on next router
		if {$row >= 4} {		; # wrapped around?
			set row 0
			incr col		; # use next server on the same router
			if {$col >= 10} {	; # wrapped around?
				set col 0
			}
		}
		
		set cxid  	[expr $clientIndex * 100 + $srv + 40000]
		
		set newFileOut "CMTCPVIDEODS[expr $cxid + 0].out"
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}
		
		puts "Build the Netflix Video streaming  sessions: cxID:$cxid,  clientIndex:$clientIndex"
		create_netflix_flow $ns $n($clientIndex) $n($srv) $WEB_VIDEO_PACKETSIZE $TARGET_VIDEO_RATE $aavginterval $vodapp_playback_buffer_capacity $cxid $flowStartTime  $tcpprinttime $newFileOut $statsHandle  $WINDOW $FLOW_PRIORITY $DASHMODE 4
		
		#incr srv
		incr clientIndex
	}
	set cm_index	$clientIndex
	
	# Create UHD videos - session number starts at 50000
	set clientIndex	[expr 0 + $cm_index]
	for {set i 0} {$i < [expr $num_uhi_defs - 0]} {incr i} {
		# which server to use?
		set srv [expr $row * 10 + $col + $srv_offset]
		incr row			; # use server on next router
		if {$row >= 4} {		; # wrapped around?
			set row 0
			incr col		; # use next server on the same router
			if {$col >= 10} {	; # wrapped around?
				set col 0
			}
		}
		
		set cxid  	[expr $clientIndex * 100 + $srv + 50000]
		
		set newFileOut "CMTCPVIDEODS[expr $cxid + 0].out"
		exec rm -f $newFileOut
		
		if {$cxid >= 3} {
			#        set flowStartTime [expr 40.001 + [uniform 0 1]]
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		} else {
			set flowStartTime [expr 0.001 + [uniform 0 3]]
		}
		
		puts "Build the Netflix Video streaming  sessions: cxID:$cxid,  clientIndex:$clientIndex"
		create_netflix_flow $ns $n($clientIndex) $n($srv) $WEB_VIDEO_PACKETSIZE $TARGET_VIDEO_RATE $aavginterval $vodapp_playback_buffer_capacity $cxid $flowStartTime  $tcpprinttime $newFileOut $statsHandle  $WINDOW $FLOW_PRIORITY $DASHMODE 5
		
		#incr srv
		incr clientIndex
	}
	set cm_index	$clientIndex
	
}

#
# This routine builds and starts a NetFlix flow between the src and destnode
#
# inputs:  we summarize the input params as folllows:
#
#  ns 
#  node_client 
#  node_server 
#  BW_LINK 
#  aavginterval 
#  clientbuffersize 
#  numberID  : a unique flow id
#  startTime  
#  stopTime 
#  thruHandle :  a file handle
#  statsHandle 
#  window  :the max tcp window 
#  priority :  sets the flow priority
#  DASHMODE : not used for now
#
proc create_netflix_flow { ns node_client node_server packetSize BW_LINK aavginterval clientbuffersize numberID startTime stopTime thruHandle statsHandle window priority DASHMODE {bitRateLevel 0} } {
	global vodapp_outstanding_requests
	global vodapp_ratio_threshold_reduction
	global vodapp_ratio_threshold_increase
	global vodapp_segment_size
	global vodapp_player_fetch_ratio_threshold
	global vodapp_player_interval
	global vodapp_adaptation_sensitivity
	global aavgdelta

	global vodapp_switching_interval_increase
	global vodapp_switching_interval_reduction
	global vodapp_player_min_stabilize_time
	#global vodapp_player_threshold
	
	global vodapp_bitrates_list
	global vodapp_bitrates_list_ld
	global vodapp_bitrates_list_md
	global vodapp_bitrates_list_sd
	global vodapp_bitrates_list_hd
	global vodapp_bitrates_list_uhd

	global TCPUDP_THROUGHPUT_MONITORS_ON
	global THROUGHPUT_MONITOR_INTERVAL
	
	if { $TCPUDP_THROUGHPUT_MONITORS_ON == 1} {
		exec rm -f $thruHandle
	}
	
	puts "create_netflix_flow: Create a Netflix flow,  CxID:$numberID;  startTime:$startTime stoptime:$stopTime, priority is $priority, aavginterval:$aavginterval"

	# Create TCP client and server agents
	#set tcp_client [new Agent/TCP/FullTcp]
	#set tcp_server [new Agent/TCP/FullTcp]
	set tcp_client [new Agent/TCP/FullTcp/Sack]
	set tcp_server [new Agent/TCP/FullTcp/Sack]
	
	# Set up TCP client
	$tcp_client set fid_ $numberID
	$tcp_client set cxId_ $numberID
	$tcp_client set window_ $window
	$tcp_client set maxcwnd_ $window
	$tcp_client set packetSize_ $packetSize
	
	# Set up TCP server
	set myID [expr $numberID + 500]	; # Server side ID offset by 1000
	$tcp_server set fid_ $myID
	$tcp_server set cxId_ $myID
	$tcp_server set window_ $window
	$tcp_server set maxcwnd_ $window
	$tcp_server set packetSize_ $packetSize
	#    $tcp_server set segsize_ 1400

	puts "Create TCP Cx  set client side cxID to #  [expr 0+$numberID], server side cxID to # $myID, protID is TCP FULL"
	
	# Attach and connect TCP server and client agents
	$ns attach-agent $node_client $tcp_client
	$ns attach-agent $node_server $tcp_server
	$ns connect $tcp_client $tcp_server
	$tcp_server listen

	# Create app client and server objects
	set app_client [new Application/TcpApp/StreamingClient $tcp_client]
	set app_server [new Application/TcpApp/StreamingServer $tcp_server]
	
	# App client setup
	#
	# (Client only) the interval time(in second) which the player to fetch the data from video buffer.
	# the size of data depend on the bitrate and the interval.
	$app_client player-interval $vodapp_player_interval
	#	$app_client player-interval 0.04167 
	#	$app_client player-interval [expr {$aavginterval * 11}]
	# (Client only) The time length of the video content in each request.
	$app_client request-interval $vodapp_segment_size
	#	$app_client request-interval [expr {$aavginterval * 5}]
	# Client ID
	$app_client set-ID $numberID
	# max pending requests
	$app_client max-requests $vodapp_outstanding_requests
	# the size of the buffer, in seconds
	$app_client buffer-size $clientbuffersize
	# the threshold buffer size (second) for switching down bitrate
	$app_client buffer-threshold-bitrate [expr {$clientbuffersize / 9}]
	# (Client only) the buffer threshold for player, if the size of buffer large than the threshold, the player start fetch data and play.
	$app_client buffer-threshold-player [expr {$clientbuffersize * 7 / 9}]
	# the constant delta to be used to calculate the aavg
	#$app_client aavg-delta 0.8
	$app_client aavg-delta $aavgdelta
	$app_client aavg-interval $aavginterval
	# (Client only) the time to detected the slop of lower bitrate.
	# The bitrates detected in this interval should alway lower than the previous one before to switch to lower bitrate
	#JJM 10/13/2012
	# for more realistic behavior, change the value from
	# to $app_client switching-interval [expr {$aavginterval * 1.8 * 2}]
	#$app_client switching-interval [expr {$aavginterval * 1.8}]
	$app_client switching-interval-increase $vodapp_switching_interval_increase
	$app_client switching-interval-reduction $vodapp_switching_interval_reduction
	# (Client only) set log file for client's requests (bitrate, size)
	#$app_client set-reqlog out.vaclireq
	$app_client set-reqlog "out.vaclireq$numberID"
	# set log file for client's buffer (totalsize, changedsize)
	#$app_client set-buflog out.vaclibuf
	$app_client set-buflog "out.vaclibuf$numberID"
	# set log file for client's internal variables (avg bw, 2sec bw, buffer size)
	#$app_client set-varlog out.vaclivar
	$app_client set-varlog "out.vaclivar$numberID"
	# set log file for client's stats
	$app_client set-statlog "out.vaclistat$numberID"
	# set the bitrates list, such as: $app_client set-bitrates 768000 1500000 2200000 2600000 3200000 3800000 4200000 4800000
	if { $bitRateLevel == 1 } {
		$app_client set-bitrates $vodapp_bitrates_list_ld
	} elseif { $bitRateLevel == 2 } {
		$app_client set-bitrates $vodapp_bitrates_list_md
	} elseif { $bitRateLevel == 3 } {
		$app_client set-bitrates $vodapp_bitrates_list_sd
	} elseif { $bitRateLevel == 4 } {
		$app_client set-bitrates $vodapp_bitrates_list_hd
	} elseif { $bitRateLevel == 5 } {
		$app_client set-bitrates $vodapp_bitrates_list_uhd
	} else {
		$app_client set-bitrates $vodapp_bitrates_list
	}
	$app_client ratio-threshold-reduction $vodapp_ratio_threshold_reduction
	$app_client ratio-threshold-increase  $vodapp_ratio_threshold_increase
	$app_client min-stabilize-time $vodapp_player_min_stabilize_time
	$app_client dash-mode $DASHMODE
	# the ratio of the received/max size of the block fetch from buffer by player
	$app_client player-fetch-ratio-threshold $vodapp_player_fetch_ratio_threshold
	# AdaptationSensitivity: the sensitivity of the switching:
	# we use delay time to smooth the # of switching
	#    real switching delay = (1 - adaptation_sensitivity) * 10 * switching_interval + adaptation_sensitivity * switching_interval / 10
	#    we set it to 0.909 to make sure the real switching_interval ~= switching_interval
	$app_client adaptation-sensitivity $vodapp_adaptation_sensitivity
	
	# App server setup
	#
	# (Server only) the send rate of the data
	$app_server send-rate $BW_LINK
	# (Server only) the message size in each packet
	$app_server message-size 42000
	#	$app_server message-size [expr {$BW_LINK / 8 / 30}]
	$app_server aavg-delta 0.8
	$app_server aavg-interval $aavginterval
	# set log file for server's buffer (totalsize, changedsize)
	#$app_server set-buflog out.vasvrbuf
	$app_server set-buflog "out.vasvrbuf$myID"
	# set log file for server's internal variables (avg bw, 2sec bw, buffer size)
	#$app_server set-varlog out.vasvrvar
	$app_server set-varlog "out.vasvrvar$myID"
	#$app_server set-pkglog out.vasvrpkg
	# App Server ID
	$app_server set-ID $myID
	
	# Connect app server and client
	$app_client connect $app_server
	
	# Schedule the start of app server and client
	$ns at $startTime "$app_server start"
	$ns at $startTime "$app_client start"

	# Periodic throughput trace
	if { $TCPUDP_THROUGHPUT_MONITORS_ON == 1} {
		TraceThroughput $ns $tcp_client  $THROUGHPUT_MONITOR_INTERVAL $thruHandle
	}

	puts "Starting client at $startTime, stop at $stopTime "

	# Final dump stats
	$ns at $stopTime "dumpFinalTCPStats  $numberID  $startTime  $tcp_server  $tcp_client $statsHandle"

	$ns at $stopTime "$app_client dumpstats"
	$ns at $stopTime "$app_server dumpstats"
	$ns at $stopTime "$app_client stop"
	$ns at $stopTime "$app_server stop"

}

proc create_wrt_flow { protID ftp_traffic tcpprinttime } {
	global ns
	global wrt_client
	global wrt_server
	
	global PACKETSIZE WINDOW

	# Create TCP source based on protocol ID
	if { $protID == 1 } {
		#  puts "Create a Reno test flow.."
		set tcp1 [new Agent/TCP/Reno]
	} elseif { $protID == 9 } {
		#  puts "Create a SACk test flow.."
		set tcp1 [new Agent/TCP/Sack1]
	} elseif { $protID == 2 } {
		puts "Create a NewReno test flow.."
		set tcp1 [new Agent/TCP/Newreno]
	} elseif { $protID == 3 } {
		puts "Create a VegasReno test flow.."
		set tcp1 [new Agent/TCP/Vegas]
	} elseif { $protID == 4 } {
		puts "Create a Vegas1 (CAM) test flow.."
		set tcp1 [new Agent/TCP/Vegas1]
	} elseif { $protID == 5 } {
		puts "Create a DCA test flow.."
		set tcp1 [new Agent/TCP/DCA]
	} elseif { $protID == 6 } {
		puts "Create a Dual test flow.."
		set tcp1 [new Agent/TCP/Dual]
	} elseif { $protID == 7 } {
		puts "Create a Reno/ECN test flow.."
		set tcp1 [new Agent/TCP/Reno]
		$tcp1 set ecn_ 1
	} elseif { $protID == 8 } {
		puts "Create a fullTCP test flow.."
		set sink1 [new Agent/TCP/FullTcp]
		set tcp1 [new Agent/TCP/FullTcp]
		$sink1 set cxId_ 5
	} else {
		puts "!!!!!! ERROR - Wrong WRT protocol ID !!!!!!"
	}
	
	# Create TCP sink based on protocol ID
	if {$protID != 8} {
		if { $protID == 9 } {
			puts "Create a Sack1/DelAck sink"
			set sink1 [new Agent/TCPSink/Sack1/DelAck]
		} else {
			#set sink1 [new Agent/TCPSink]
			set sink1 [new Agent/TCPSink/DelAck]
		}
		$sink1 set SinkId_ 1
	}
	
	
	$tcp1 set fid_ 1
	$sink1 set fid_ 1
	$sink1 set SinkId_ 1
	
	#set wrt_client to be the sink!!!
	$ns attach-agent $wrt_client $sink1
	#$ns attach-agent $n(400) $tcp1
	#$ns attach-agent $n(40) $sink1
	
	#puts "CABLELABS: attach tcp 1 sink to $firstClientID"
	#This aligns TCP1 DS
	#$ns attach-agent $n($firstClientID) $sink1
	$ns attach-agent $wrt_server $tcp1

	#Or if want tcp1 US:
	#$ns attach-agent $n($firstClientID) $tcp1
	#$ns attach-agent $wrt_server $sink1

	#Set to cxId_ of 1 to create WRT samples in snumack.out
	$tcp1 set cxId_ 1
	
	$ns connect $tcp1 $sink1
	
	if {$protID == 8} {
		$sink1 listen
	}
	
	$tcp1 set window_ $WINDOW
	$tcp1 set maxcwnd_ $WINDOW
	$tcp1 set packetSize_ $PACKETSIZE

	#see dsl.tcl.  This is where we can trace tcpRTT, or other TCP
	#tracedVars.  Note: we use another way to plot the tcpRTT-
	#turn on TRACESNUM and ACK in the TCP source then process via matlab
	#using the same programs as we did with measurement data.
	#setupTcpTracing $tcp1 $tcp1trace
	
	if  { $ftp_traffic  == 1 } {
		#turn on an ftp flow
		set ftp1 [new Application/FTP]
		$ftp1 attach-agent $tcp1
		$ns at 1.101 "$ftp1 start"
	} else {
		puts "WRT monitor traffic flow ..."
		#make sure TRACEBURST is set in tcp.cc and expoo.cc.  We
		#want to measure a periodic TCP burst... (this is our metric)
		set exp1 [new Application/Traffic/Exponential]
		$exp1 attach-agent $tcp1
		$exp1 set packetSize_ $PACKETSIZE
		$exp1 set burst_time_ .0064
		$exp1 set idle_time_ 1
		$exp1 set rate_ 100000k
		#the mode_ turns the exp gen into a CBR ...
		$exp1 set mode_ 1
		$ns at 1.0 "$exp1 start"
	}
	
	exec rm -f CMDSTCPMONITOR.out
	#TraceThroughput $ns $sink1  1.0 CMDSTCPMONITOR.out
	#TCPTraceSendRate $ns $tcp1  .1  tcpsend1.out
	
	$ns at $tcpprinttime "dumpFinalTCPStats  1 1.0 $tcp1  $sink1 TCPstats.out"
	
	puts "WRT flow created!"
}

proc create_tcp1_flow { protID ftp_traffic tcpprinttime } {
	global ns
	global n	; # nodes
	global wrt_server
	
	global firstClientID
	
	global PACKETSIZE WINDOW

	# Create TCP source based on protocol ID
	if { $protID == 1 } {
		#  puts "Create a Reno test flow.."
		set tcp1 [new Agent/TCP/Reno]
	} elseif { $protID == 9 } {
		#  puts "Create a SACk test flow.."
		set tcp1 [new Agent/TCP/Sack1]
	} elseif { $protID == 2 } {
		puts "Create a NewReno test flow.."
		set tcp1 [new Agent/TCP/Newreno]
	} elseif { $protID == 3 } {
		puts "Create a VegasReno test flow.."
		set tcp1 [new Agent/TCP/Vegas]
	} elseif { $protID == 4 } {
		puts "Create a Vegas1 (CAM) test flow.."
		set tcp1 [new Agent/TCP/Vegas1]
	} elseif { $protID == 5 } {
		puts "Create a DCA test flow.."
		set tcp1 [new Agent/TCP/DCA]
	} elseif { $protID == 6 } {
		puts "Create a Dual test flow.."
		set tcp1 [new Agent/TCP/Dual]
	} elseif { $protID == 7 } {
		puts "Create a Reno/ECN test flow.."
		set tcp1 [new Agent/TCP/Reno]
		$tcp1 set ecn_ 1
	} elseif { $protID == 8 } {
		puts "Create a fullTCP test flow.."
		set sink1 [new Agent/TCP/FullTcp]
		set tcp1 [new Agent/TCP/FullTcp]
		$sink1 set cxId_ 5
	} else {
		puts "!!!!!! ERROR - Wrong WRT protocol ID !!!!!!"
	}
	
	# Create TCP sink based on protocol ID
	if {$protID != 8} {
		if { $protID == 9 } {
			puts "Create a Sack1/DelAck sink"
			set sink1 [new Agent/TCPSink/Sack1/DelAck]
		} else {
			#set sink1 [new Agent/TCPSink]
			set sink1 [new Agent/TCPSink/DelAck]
		}
		$sink1 set SinkId_ 1
	}
	
	
	$tcp1 set fid_ 1
	$sink1 set fid_ 1
	$sink1 set SinkId_ 1
	
	#set wrt_client to be the sink!!!
	#$ns attach-agent $wrt_client $sink1
	#$ns attach-agent $n(400) $tcp1
	#$ns attach-agent $n(40) $sink1
	
	puts "CABLELABS: attach tcp 1 sink to $firstClientID"
	#This aligns TCP1 DS
	$ns attach-agent $n($firstClientID) $sink1
	$ns attach-agent $wrt_server $tcp1

	#Or if want tcp1 US:
	#$ns attach-agent $n($firstClientID) $tcp1
	#$ns attach-agent $wrt_server $sink1

	#Set to cxId_ of 1 to create WRT samples in snumack.out
	$tcp1 set cxId_ 1
	
	$ns connect $tcp1 $sink1
	
	if {$protID == 8} {
		$sink1 listen
	}
	
	$tcp1 set window_ $WINDOW
	$tcp1 set maxcwnd_ $WINDOW
	$tcp1 set packetSize_ $PACKETSIZE

	#see dsl.tcl.  This is where we can trace tcpRTT, or other TCP
	#tracedVars.  Note: we use another way to plot the tcpRTT-
	#turn on TRACESNUM and ACK in the TCP source then process via matlab
	#using the same programs as we did with measurement data.
	#setupTcpTracing $tcp1 $tcp1trace
	
	if  { $ftp_traffic  == 1 } {
		#turn on an ftp flow
		set ftp1 [new Application/FTP]
		$ftp1 attach-agent $tcp1
		$ns at 1.101 "$ftp1 start"
	} else {
		#make sure TRACEBURST is set in tcp.cc and expoo.cc.  We
		#want to measure a periodic TCP burst... (this is our metric)
		set exp1 [new Application/Traffic/Exponential]
		$exp1 attach-agent $tcp1
		$exp1 set packetSize_ $PACKETSIZE
		$exp1 set burst_time_ .0064
		$exp1 set idle_time_ 1
		$exp1 set rate_ 100000k
		#the mode_ turns the exp gen into a CBR ...
		$exp1 set mode_ 1
		$ns at 1.0 "$exp1 start"
	}
	
	exec rm -f CMDSTCPMONITOR.out
	TraceThroughput $ns $sink1  1.0 CMDSTCPMONITOR.out
	#TCPTraceSendRate $ns $tcp1  .1  tcpsend1.out
	
	$ns at $tcpprinttime "dumpFinalTCPStats  1 1.0 $tcp1  $sink1 TCPstats.out"
	
	puts "TCP 1 test flow created!"
}

proc create_single_ugs_flow { single_ugs_flow stoptime } {
	global TCL_DEBUG
	
	global ns wrt_server wrt_client
	
	#if {$TCL_DEBUG == 1} {
		puts "Create a the single UDP echo client/server, SINGLE_UGS value is $single_ugs_flow  ..."
	#}
	
	if {$single_ugs_flow < 3} {
		set udp0 [new Agent/UDP]
		$ns attach-agent $wrt_client $udp0
		
		set cbr0 [new Application/Traffic/CBR]
		#  $cbr0 set packetSize_ 350
		#  $cbr0 set interval_ 0.05
		#  $cbr0 set packetSize_ 210
		#  $cbr0 set interval_ 0.02
		$cbr0 set packetSize_ 64
		$cbr0 set interval_ 0.5
		#mode_ 1 will create CBR.send - see ./tools/cbr_traffic.cc
		$cbr0 set mode_ 1
		$cbr0 attach-agent $udp0
		
		set udpsinkexp0 [new Agent/UDPSink]
		$ns attach-agent $wrt_server $udpsinkexp0
		
		$ns connect $udp0 $udpsinkexp0
		
		#mode_ 1 will create CBR.send - see ./tools/cbr_traffic.cc
		$udpsinkexp0 set fid_  1
		$udpsinkexp0 set SinkId_  1
		
		set newUDPFileOut "UDPsink.out"
		exec rm -f $newUDPFileOut
		
		UDPTraceThroughput $ns $udpsinkexp0  .5 $newUDPFileOut
		set UDPstartupTime [uniform .1 3]
		
		$ns at $stoptime "dumpFinalUDPStats  1 $UDPstartupTime $udpsinkexp0 UDPstats.out"

		$ns at $UDPstartupTime "$cbr0 start"
		
		puts "Single UGS flow created!"
	} else {
		puts "No single UGS flow created!"
	}
}

proc create_ugs_flows { NUMBER_UGS_CMS } {
	global TCL_DEBUG
	
	global ns UGSCMNodes voip_server
	
	for {set i 0} {$i < $NUMBER_UGS_CMS} {incr i} {
		#if {$TCL_DEBUG == 1} {
			puts "Create a UGS CM flow ..."
		#}
		
		set newUDPFileOut "UGSout[expr $i + 0].out"
		exec rm -f $newUDPFileOut
		
		set UDPArray($i) [new Agent/UDP]
		
		$ns attach-agent $UGSCMNodes($i) $UDPArray($i)
		
		set CBRArray($i) [new Application/Traffic/CBR]
		$CBRArray($i) set packetSize_ 210
		$CBRArray($i) set interval_ 0.02
		#mode_ 1 will create CBR.send - see ./tools/cbr_traffic.cc
		$CBRArray($i) set mode_ 0
		$CBRArray($i) attach-agent $UDPArray($i)
		
		set udpsinkArray($i) [new Agent/UDPSink]
		#global NUMBER_UGS_CMS UGSCMNodes voip_server
		$ns attach-agent $voip_server $udpsinkArray($i)
		$ns connect $UDPArray($i) $udpsinkArray($i)
		#mode_ 1 will create CBR.send - see ./tools/cbr_traffic.cc
		#If >2000, then udp-sink.cc will dump a sample to jitter.dat
		$udpsinkArray($i) set SinkId_  [expr $i + 2001]
		
		if {$TCL_DEBUG == 1} {
			puts "..set the sink id to [expr $i + 2001]"
		}
		
		#Comment this out....
		UDPTraceThroughput $ns $udpsinkArray($i)  .5 $newUDPFileOut
		
		set startupTime [uniform .1 3]
		if {$TCL_DEBUG == 1} {
			puts "Start a CBR source at time $startupTime"
		}
		
		$ns at $startupTime "$CBRArray($i) start"
	}
}


proc create_tcp2_flow { protID TCP2DS traffic tcpprinttime } {
	# this proc has not been completely worked out

	# Create TCP source based on protocol ID
	if { $protID == 1 } {
		#  puts "Create a Reno test flow.."
		set tcp2 [new Agent/TCP/Reno]
	} elseif { $protID == 9 } {
		#  puts "Create a SACk test flow.."
		set tcp2 [new Agent/TCP/Sack1]
	} elseif { $protID == 2 } {
		puts "Create a NewReno test flow.."
		set tcp2 [new Agent/TCP/Newreno]
	} elseif { $protID == 3 } {
		puts "Create a VegasReno test flow.."
		set tcp2 [new Agent/TCP/Vegas]
	} elseif { $protID == 4 } {
		puts "Create a Vegas1 (CAM) test flow.."
		set tcp2 [new Agent/TCP/Vegas1]
	} elseif { $protID == 5 } {
		puts "Create a DCA test flow.."
		set tcp2 [new Agent/TCP/DCA]
	} elseif { $protID == 6 } {
		puts "Create a Dual test flow.."
		set tcp2 [new Agent/TCP/Dual]
	} elseif { $protID == 7 } {
		puts "Create a Reno/ECN test flow.."
		set tcp2 [new Agent/TCP/Reno]
		$tcp2 set ecn_ 1
	} elseif { $protID == 8 } {
		puts "Create a fullTCP test flow.."
		set sink2 [new Agent/TCP/FullTcp]
		set tcp2 [new Agent/TCP/FullTcp]
		$sink2 set cxId_ 5
	} else {
		puts "!!!!!! ERROR - Wrong WRT protocol ID !!!!!!"
	}
	
	# Create TCP sink based on protocol ID
	#set sink2 [new Agent/TCPSink/DelAck]
	#set sink2 [new Agent/TCPSink]
	if {$protID != 8} {
		if { $protID == 9 } {
			puts "Create a Sack1/DelAck sink"
			set sink2 [new Agent/TCPSink/Sack1/DelAck]
		} else {
			#set sink2 [new Agent/TCPSink]
			set sink2 [new Agent/TCPSink/DelAck]
		}
	}


	$tcp2 set fid_ 2
	$sink2 set fid_ 2 
	$sink2 set SinkId_ 2
	
	if {$numberCMs > 0} {
		if {$TCP2DS == 1} {
			#for DS
			$ns attach-agent $n($firstClientID) $sink2
			#    $ns attach-agent $n($lastServerID) $tcp2
			$ns attach-agent $wrt_server $tcp2
			puts "CABLELABS: TCP2(DS): Setting sink to node $firstClientID and sender to wrt_server"
		} else {
			#for US
			$ns attach-agent $n($firstClientID) $tcp2
			#    $ns attach-agent $n($lastServerID) $sink2
			$ns attach-agent $wrt_server $sink2
			puts "CABLELABS: TCP2(US): Setting sender to node $firstClientID and sink to wrt_server"
		}
		
		#finally, start parallel cxs at tcp2 if needed
		set cxid 2000;
		set flowStartTime [expr 0.001 + [uniform 0 2]]
		set newFileOut "CMTCP[expr $cxid].out"
		if {$CONCURRENTTCP > 1} {
			if {$TCP2DS == 1} {
				puts "CABLELABS: TCP2(DS): DS PARALLEL connections($CONCURRENTTCP): Setting sender to node $firstClientID and sink to wrt_server"
				BuildTCPCx $ns $wrt_server $n($firstClientID) [expr $CONCURRENTTCP-1] $PACKETSIZE $BURSTTIME $IDLETIME $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut  $WINDOW  $SHAPE  $protID
			} else {
				puts "CABLELABS: TCP2(US): US PARALLEL connections($CONCURRENTTCP): Setting sender to node $firstClientID and sink to wrt_server"
				BuildTCPCx $ns $n($firstClientID) $wrt_server  [expr $CONCURRENTTCP-1] $PACKETSIZE $BURSTTIME $IDLETIME $BURSTRATE $cxid $flowStartTime  $tcpprinttime $newFileOut  $WINDOW  $SHAPE  $protID
			}
		}
	} else {
		$ns attach-agent $wrt_client $sink2
		$ns attach-agent $wrt_server $tcp2
		puts "Setting TCP2 sink to node wrt_client node and sender to wrt_server"
	}
	
	$ns connect $tcp2 $sink2
	
	$tcp2 set cxId_ 2
	
	# Chose between an ftp , exp or web source
	#set WINDOW2 85
	set WINDOW2 72
	#set WINDOW2 685
	$tcp2 set window_ $WINDOW2
	$tcp2 set maxcwnd_ $WINDOW2
	$tcp2 set packetSize_ $PACKETSIZE

	if {$traffic == 0} {
		puts "CABLELABS: Setting TCP2 for FTP, window : $WINDOW2 "
		set ftp2 [$tcp2 attach-app FTP]
		$ns at .14 "$ftp2 start"
	} else {
		puts "CABLELABS: Setting TCP2 for VIDEO, window : $WINDOW2 "
		set exp2 [new Application/Traffic/Exponential]
		$exp2 attach-agent $tcp2
		#  $exp2 set packetSize_ $PACKETSIZE
		$exp2 set packetSize_ 1000
		$exp2 set burst_time_ 3
		$exp2 set idle_time_  1.0
		$exp2 set rate_ 12000000
		$ns at .5 "$exp2 start"

		#set gen2 [new Application/Traffic/Pareto]
		#$gen2 attach-agent $tcp2
		#$gen2 set packetSize_ 1460
		#$gen2 set burst_time_  $OFFICEBURSTTIME
		#$gen2 set idle_time_ $OFFICEIDLETIME
		#$gen2 set rate_  $OFFICERATE
		#$gen2 set shape_  $OFFICESHAPE

		#turn on printf
		#$gen2 set mode  1
		#$gen2 set mode  1
		#$ns at 0.020 "$gen2 start"
		#$ns at $printtime "printpareto gen2 $gen2"
	}

	TraceThroughput $ns $sink2  1.0 thru2.out
	#TCPTraceSendRate $ns $tcp2  .1  tcpsend2.out

	$ns at $tcpprinttime "dumpFinalTCPStats  2 1.0 $tcp2  $sink2 TCPstats.out"

	puts "TCP 2 test flow created!"
}
