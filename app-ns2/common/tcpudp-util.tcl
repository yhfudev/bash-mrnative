#
# This script defines TCP/UDP utility TCL procedures
#

#
# This routine builds and starts a TCP connection between the src and dest nodes
#
# inputs:
#
#	ns
#	SrcNode
#	DestNode
#	Number		- this routine will create any number of TCP cx's
#	burstTime	- pareto param
#	idleTime	- pareto param
#	burstRate	- pareto param
#	numberID	- a unique Cx id
#	starttime
#	stoptime
#	thruHandle	- a file handle
#	window		- the max tcp window
#	pshape		- the pareto shape param
#	protID		- specifies the type of TCP protocol to use
#
proc BuildTCPCx { ns SrcNode DestNode Number packetSize burstTime idleTime burstRate numberID starttime stoptime thruHandle window pshape protID } {

	exec rm -f $thruHandle

	global TCPUDP_THROUGHPUT_MONITORS_ON
	
	set printtime $stoptime
	
	for {set i 0} {$i < $Number} {incr i} {
		puts "Create TCP Cx #  [expr $i+$numberID] (file $thruHandle), window : $window"
		
		#PROTID
		if { $protID == 1 } {
			set tcp [new Agent/TCP/Reno]
		} elseif { $protID == 9 } {
			puts "Create TCP Sack1  Cx #  [expr $i+$numberID] (file $thruHandle)"
			set tcp [new Agent/TCP/Sack1]
		} elseif { $protID == 2 } {
			set tcp [new Agent/TCP/Newreno]
		} elseif { $protID == 3 } {
			set tcp [new Agent/TCP/Vegas]
		} elseif { $protID == 7 } {
			set tcp [new Agent/TCP/Reno]
			#RED
			$tcp set ecn_ 1
		} else {
			puts "Bad protID $protID"
		}

		#set sink [new Agent/TCPSink/DelAck]
		#  set sink [new Agent/TCPSink]
		if {$protID != 8} {
			if { $protID == 9 } {
				#    puts "Create a Sack1/DelAck sink"
				set sink [new Agent/TCPSink/Sack1/DelAck]
			} else {
				#set sink [new Agent/TCPSink]
				set sink [new Agent/TCPSink/DelAck]
			}
		} else {
			puts "Bad protID $protID"
		}

		$tcp set fid_  [expr $i+$numberID]
		$sink set fid_ [expr $i+$numberID]
		$sink set sinkId_ [expr $i+$numberID]
		
		$ns attach-agent $SrcNode $tcp
		$ns attach-agent $DestNode $sink
		$ns connect $tcp $sink

		#$A303
		#Add random packet size
		$tcp set packetSize_ $packetSize
		#  $tcp set packetSize_ 1460
		#  $tcp set packetSize_ [uniform 256  1460]
		#  $tcp set packetSize_ 512

		$tcp set maxcwnd_ $window
		$tcp set window_ $window
		$tcp set cxId_ [expr $i+$numberID]
		$tcp set overhead_ 0.000020
		puts "Create TCP Cx  set cxID to #  [expr $i+$numberID]"

		if { $pshape == 0} {
			set ftp [$tcp attach-app FTP]    
			puts " Attach an FTP generator and start it a $starttime"
			$ns at $starttime  "$ftp start"
			$ns at $stoptime  "$ftp stop"
		} else {
			set gen [new Application/Traffic/Pareto]
			$gen attach-agent $tcp
			$gen set packetSize_ $packetSize
			$gen set burst_time_  $burstTime
			$gen set idle_time_ $idleTime
			$gen set rate_ $burstRate
			$gen set shape_  $pshape
			
			puts " Attach a pareto generator and start it a $starttime"
			$ns at $starttime  "$gen start"
			$ns at $stoptime  "$gen stop"
		}
		
		if { $TCPUDP_THROUGHPUT_MONITORS_ON == 1} {
			TraceThroughput $ns $sink  1.0 $thruHandle
		}
		
		#Note:  cxID 1 is the WRT monitor and cxID 2 is the snum ack traced flow.
		#  if  {[expr $i + $numberID] == 1} {
		#    TraceThroughput $ns $sink  1.0 $thruHandle
		#  }
		#  if  {[expr $i + $numberID] == 2} {
		#    TraceThroughput $ns $sink  1.0 $thruHandle
		#  }

		$ns at $printtime "dumpFinalTCPStats  [expr $i + $numberID] $starttime $tcp  $sink TCPstats.out"
	}
}

#
# This routine builds and starts a TCP connection between the src and dest nodes
#
# inputs:
#
#	ns
#	SrcNode
#	DestNode
#	Number		- this routine will create any number of TCP cx's
#	burstTime	- pareto param
#	idleTime	- pareto param
#	burstRate	- pareto param
#	numberID	- a unique Cx id
#	stoptime
#	thruHandle	- a file handle
#	window		- the max tcp window
#	pshape		- the pareto shape param
#	protID		- specifies the type of TCP protocol to use
#
#	mode		- specifies the traffic generator to be used
#				0: exponential
#				1: CBR
#				2: FTP
#				3: Pareto
#				4:
#
proc BuildTCPCxWithMode { ns SrcNode DestNode Number packetSize burstTime idleTime intervalTime burstRate numberID starttime stoptime thruHandle statsHandle window pshape protID mode priority} {

	global TCPUDP_THROUGHPUT_MONITORS_ON
	global THROUGHPUT_MONITOR_INTERVAL
	
	if { $TCPUDP_THROUGHPUT_MONITORS_ON == 1 } {
		exec rm -f $thruHandle
	}

	set printtime $stoptime

	puts "BuildTCPCxWithMode: Create $Number TCP Connection(s), starting CxID:$numberID, mode:$mode and starttime:$starttime stoptime:$stoptime"

	for {set i 0} {$i < $Number} {incr i} {
		puts "Create TCP Cx # [expr $i+$numberID] (file $thruHandle),  mode is $mode, priority is $priority, packetSize is $packetSize"

		# tcp src
		if { $protID == 1 } {
			set tcp [new Agent/TCP/Reno]
		} elseif { $protID == 9 } {
			set tcp [new Agent/TCP/Sack1]
		} elseif { $protID == 2 } {
			set tcp [new Agent/TCP/Newreno]
		} elseif { $protID == 3 } {
			set tcp [new Agent/TCP/Vegas]
		} elseif { $protID == 7 } {
			set tcp [new Agent/TCP/Reno]
			#RED
			$tcp set ecn_ 1
		} elseif { $protID == 8 } {
			#  set tcp [new Agent/TCP/FullTcp]
			#  set sink [new Agent/TCP/FullTcp]
			set tcp [new Agent/TCP/FullTcp/Sack]
			set sink [new Agent/TCP/FullTcp/Sack]

			#For Full- we need to have sink side by a different cx id
			#  otherwise the snumack trace is not right
			#  set tcp_client [new Agent/TCP/FullTcp]
			#  set tcp_server [new Agent/TCP/FullTcp]
			#  $ns attach-agent $node_client $tcp_client
			#  $ns attach-agent $node_server $tcp_server
			#  $ns connect $tcp_client $tcp_server
			#Do we need to do this?
			#  $tcp_server listen
			#Ids each cx
			$tcp set packetSize_  $packetSize
			$tcp set maxcwnd_ $window
			$tcp set window_ $window
			$sink set packetSize_  $packetSize
			$sink set maxcwnd_ $window
			$sink set window_ $window
		}

		# tcp sink
		# set sink [new Agent/TCPSink/DelAck]
		# set sink [new Agent/TCPSink]
		if {$protID != 8} {
			if { $protID == 9 } {
				# puts "Create a Sack1/DelAck sink"
				set sink [new Agent/TCPSink/Sack1/DelAck]
			} else {
				#set sink [new Agent/TCPSink]
				set sink [new Agent/TCPSink/DelAck]
			}
		}

		set CxID [expr $i+$numberID]

		$tcp set fid_  $CxID
		$sink set fid_  $CxID
		$sink set sinkId_ $CxID

		$ns attach-agent $SrcNode $tcp
		$ns attach-agent $DestNode $sink
		$ns connect $tcp $sink

		$tcp set packetSize_ $packetSize
		$tcp set maxcwnd_ $window
		$tcp set window_ $window
		$tcp set cxId_ $CxID
		$tcp set overhead_ 0.000020
		$tcp set prio_ $priority

#$A303
#Add random packet size
#  $tcp set packetSize_ 1460
#  $tcp set packetSize_ [uniform 256  1460]
#  $tcp set packetSize_ 512

		if {$mode == 0} {

			set exp [new Application/Traffic/Exponential]

			$exp attach-agent $tcp
			#  $exp set packetSize_ 1460
			$exp set packetSize_ $packetSize
			$exp set burst_time_ $burstTime
			$exp set idle_time_ $idleTime
			$exp set rate_ $burstRate

			puts "Start an EXP TCP Cx  cxId_:$CxID, burst rate:$burstRate"

			$ns at $starttime "$exp start"
			$ns at $stoptime "$exp stop"

		} elseif {$mode == 1} {

			set cbr [new Application/Traffic/CBR]

			$cbr attach-agent $tcp
			$cbr set packetSize_ $packetSize
			$cbr set interval_ $intervalTime
			$cbr set mode_ 0

			puts "Start a CBR TCP Cx  cxId_:$CxID, interval:$intervalTime"

			$ns at $starttime "$cbr start"
			$ns at $stoptime "$cbr stop"

		} elseif {$mode == 2} {

			set ftp [$tcp attach-app FTP]

			puts "Attach an FTP generator and start it at $starttime"

			$ns at $starttime  "$ftp start"
			$ns at $stoptime  "$ftp stop"

		} elseif {$mode == 3} {

			set gen [new Application/Traffic/Pareto]

			$gen attach-agent $tcp
			$gen set packetSize_ $packetSize
			$gen set burst_time_ $burstTime
			$gen set idle_time_ $idleTime
			$gen set rate_ $burstRate
			$gen set shape_ $pshape

			puts "Attach a pareto generator and start it at $starttime"

			$ns at $starttime  "$gen start"
			$ns at $stoptime  "$gen stop"

		} else {

			set ftp [$tcp attach-app FTP]

			puts "By default, we Attach an FTP generator and start it at $starttime"

			$ns at $starttime  "$ftp start"
			$ns at $stoptime  "$ftp stop"

		}

		if { $TCPUDP_THROUGHPUT_MONITORS_ON == 1 } {
			TraceThroughput $ns $sink  $THROUGHPUT_MONITOR_INTERVAL $thruHandle
		}
		if { $TCPUDP_THROUGHPUT_MONITORS_ON == 0 } {
			exec rm -f $thruHandle
			if { $CxID == 1116} {
				TraceThroughput $ns $sink  $THROUGHPUT_MONITOR_INTERVAL $thruHandle
			}
			if { $CxID == 6121} {
				TraceThroughput $ns $sink  $THROUGHPUT_MONITOR_INTERVAL $thruHandle
			}
		}

		if { $CxID == 6046} {
			set tcpTraceFile [open tcp6046.tr w]
			setupTcpTracing $tcp  $tcpTraceFile
		}

		$ns at $printtime "dumpFinalTCPStats [expr $i + $numberID] $starttime $tcp $sink $statsHandle"

	}	; # for {...} {...} {...}

}


proc TraceThroughput { ns tcpsinkSrc interval fname } {
	#puts "We will open TraceThroughput file $fname"

	proc Throughputdump { ns src interval fname } {
		set f [open $fname a]
		$ns at [expr [$ns now] + $interval] "Throughputdump $ns $src $interval $fname"
		# puts [$ns now]/throughput-bytes=[$src set sinkThroughput]
		# puts [$ns now]/throughput=[expr ( ([$src set sinkThroughput]/ $interval) * 8) ]
		set mythroughput [expr (([$src set sinkThroughput] / $interval) * 8)]

#          puts "TraceThroughput:  [$ns now]  $mythroughput"
#To see just bps throughput..
#           puts $f "[$ns now]  $mythroughput"
#to see bits per second AND bytes

		set tmpBytes [$src set sinkThroughput]

		puts $f "[$ns now]  $mythroughput $tmpBytes"
		flush $f

		$src set sinkThroughput 0

		close $f
	}
	
	$ns at [$ns now] "Throughputdump $ns $tcpsinkSrc $interval $fname"
#	$ns at 0.0 "Throughputdump $ns $tcpsinkSrc $interval $fname"
}


#JJM2
#########################################################################################
# proc dumpFinalTCPStats {label starttime tcp tcpsink outputFile} {
#
#  This function is meant to pull stats from the tcp src and sink
#  Note:  This is called if protID is NOT 8 (NOT Full TCP)
#
#########################################################################################
proc dumpFinalTCPStats {label starttime tcp tcpsink outputFile} {
	set f [open $outputFile a]
	set ns [Simulator instance]

	set bytesDel [$tcpsink set numberBytesDelivered]
	set packetsDel [$tcpsink set numberPacketsDelivered]
	set tmpTime [expr [$ns now] - $starttime]
	set thruput [expr $bytesDel*8.0/$tmpTime + 0.0]

# puts "dumpFinalTCPStats: bytesDel is $bytesDel, tmpTime is $tmpTime and thruput is $thruput"

	set notimeouts   [expr [$tcp set nTimeouts_] + 0.0]
	set lossno [ expr [$tcp set nRexmits_] +  0.0]
	set drops [expr $lossno * 100]
	set arrivals [expr  $packetsDel + $lossno + 0.0]
	#	set arrivals [expr [$tcp set ack_] + $lossno + 0.0]

	if {$arrivals > 0} {
		set dropRate [expr $drops / $arrivals + 0.00]
	} else {
		set dropRate 0
	}
	
	set toFreq 0.0
	if {$lossno > 0.0} {
		#puts "notimeouts is $notimeouts and lossno is $lossno"
		set timeoutdrops [expr $notimeouts * 100]
		set toFreq [expr $timeoutdrops / $lossno + 0.00]
	}

	set meanSampleCounter  [$tcp set FinalLossRTTMeanCounter]
	set TotalRTTSamples  [$tcp set FinalRTT]

	if {$meanSampleCounter > 0} {
		set meanRTT [expr $TotalRTTSamples / $meanSampleCounter + 0.00]
	} else {
		set meanRTT 0
	}

#   puts "$label $bytesDel $arrivals $lossno $dropRate $meanRTT $notimeouts $toFreq $thruput  0 0 0"
#make the number of fields the same as with dumpFinalTFRC.... DO NOT CHANGE!!!! MATLAB needs this.
	puts $f "$label $bytesDel $arrivals $lossno $dropRate $notimeouts $toFreq $meanRTT $thruput 0 0 0"
	flush $f

	close $f

}


#
# This routine builds and starts a UDP connection between the src and dest node
#
# inputs:
#
#	ns
#	SrcNode
#	DestNode
#	Number		- this routine will create any number of TCP cx's
#	burstTime	- pareto param
#	idleTime	- pareto param
#	burstRate	- pareto param
#	numberID	- a unique Cx id
#	stoptime
#	thruHandle	- a file handle
#	pshape		- the pareto shape param
#	protID		- specifies the type of TCP protocol to use
#
#	mode		- specifies the traffic generator to be used
#				0: exponential
#				1: CBR
#				2: FTP
#				3: Pareto
#				4:
#
proc BuildUDPCxWithMode { ns SrcNode DestNode Number packetSize burstTime idleTime intervalTime burstRate numberID starttime stoptime thruHandle statsHandle pshape mode priority } {

	global TCPUDP_THROUGHPUT_MONITORS_ON
	global THROUGHPUT_MONITOR_INTERVAL

	if { $TCPUDP_THROUGHPUT_MONITORS_ON == 1 } {
		exec rm -f $thruHandle
	}

	set printtime $stoptime

	puts "BuildUDPCxWithMode: Create $Number UDP Connection(s), starting CxID:$numberID, mode:$mode and starttime:$starttime stoptime:$stoptime"

	for {set i 0} {$i < $Number} {incr i} {

		set udp [new Agent/UDP]
		set sink [new Agent/UDPSink]
		set myCXID [expr $i +  $numberID]

		$sink set SinkId_  $myCXID
		$sink set fid_  $myCXID
		$sink set prio_ $priority

		$udp set class_ 2
		$udp set cxId_ $myCXID
		$udp set packetSize_ $packetSize
		$udp set prio_ $priority

		$ns attach-agent $SrcNode $udp
		$ns attach-agent $DestNode $sink
		$ns connect $udp $sink

		if {$mode == 0} {	; # exponential traffic

			set exp [new Application/Traffic/Exponential]

			$exp attach-agent $udp
			$exp set packetSize_ $packetSize
			$exp set burst_time_ $burstTime
			$exp set idle_time_ $idleTime
			$exp set rate_ $burstRate

			puts "Start an EXP UDP Cx  cxId:$myCXID, burst rate:$burstRate"

			$ns at $starttime "$exp start"
			$ns at $stoptime "$exp stop"

		} elseif {$mode == 1} {

			set cbr [new Application/Traffic/CBR]

			$cbr attach-agent $udp
			$cbr set packetSize_ $packetSize
			$cbr set interval_ $intervalTime

			if { $myCXID == 12} {
				$cbr set mode_ 1
				puts "Create CBRUDP Cx # $myCXID (file $thruHandle), mode_ 1, packetSize:$packetSize, interval:$intervalTime, starttime:$starttime, stoptime:$stoptime"
			} else {
				$cbr set mode_ 0
				puts "Create CBRUDP Cx # $myCXID (file $thruHandle), mode_ 0, packetSize:$packetSize, interval:$intervalTime, starttime:$starttime, stoptime:$stoptime"
			}

			puts "Start a CBR UDP Cx  cxId:$myCXID, interval:$intervalTime"

			$ns at $starttime "$cbr start"
			$ns at $stoptime "$cbr stop"

		} elseif {$mode == 2} {
			puts " Attach an FTP generator - HARD ERROR  DOES NOT APPLY TO UDP "
		} elseif {$mode == 3} {

			set gen [new Application/Traffic/Pareto]

			$gen attach-agent $udp
			$gen set packetSize_ $packetSize
			$gen set burst_time_  $burstTime
			$gen set idle_time_ $idleTime
			$gen set rate_ $burstRate
			$gen set shape_  $pshape

			puts " Attach a pareto generator and start it a $starttime"

			$ns at $starttime  "$gen start"
			$ns at $stoptime  "$gen stop"

		} else {
			puts " BuildUDPCxWithMode:  HARD ERROR , bad mode: $mode"
		}

		# if {$myCXID == 13} {
		#puts "Stop  the UDP Cx  cxId:$myCXID at $stoptime]"
		#$ns at $stoptime  "$cbr stop"
		# }

		# to create a throughput file ..
		if {$TCPUDP_THROUGHPUT_MONITORS_ON == 1} {
			UDPTraceThroughput $ns $sink $THROUGHPUT_MONITOR_INTERVAL $thruHandle
		} elseif {$TCPUDP_THROUGHPUT_MONITORS_ON == 0} {
			exec rm -f $thruHandle
			if {$myCXID == 5121} {
				UDPTraceThroughput $ns $sink $THROUGHPUT_MONITOR_INTERVAL $thruHandle
			} elseif {$myCXID == 5122} {
				UDPTraceThroughput $ns $sink $THROUGHPUT_MONITOR_INTERVAL $thruHandle
			}
		}

		$ns at $stoptime "dumpFinalUDPStats $myCXID $starttime $sink $statsHandle"

	}	; # for {...} {...} {...}
}

#
# This routine dumps out final UDP connection statistics
#
proc dumpFinalUDPStats {label starttime udpsink outputFile} {
	set f [open $outputFile a]
	set ns [Simulator instance]

	set bytesDel [$udpsink set UDPSinkNumberBytesDelivered]
	set PktsDel  [$udpsink set UDPSinkTotalPktsReceived]
	set PktsDropped  [$udpsink set UDPSinkNumberPktsDropped]
	set PktsOutOfOrder  [$udpsink set UDPSinkPktsOutOfOrder]

	set AvgJitter  [$udpsink set UDPAvgJitter]
	set AvgLatency  [$udpsink set UDPAvgLatency]

	set tmpTime [expr [$ns now] - $starttime]
	set thruput [expr $bytesDel*8.0/$tmpTime + 0.0]

	#puts "dumpFinalUDPStats: bytesDel is $bytesDel, tmpTime is $tmpTime and thruput is $thruput (output file: $outputFile)"
	set tmpX [ expr $PktsDropped*1.0 + $PktsDel*1.0]
	if {$tmpX > 0} {
		set dropRate [expr $PktsDropped*1.0 / $tmpX + 0.00]
	} else {
		set dropRate 0
	}

	#puts "$label $bytesDel $arrivals $lossno $dropRate $meanRTT $notimeouts $toFreq $thruput  0 0 0"
	#make the number of fields the same as with dumpFinalTFRC.... DO NOT CHANGE!!!! MATLAB needs this.
	puts $f "$label $bytesDel $PktsDel $PktsDropped $PktsOutOfOrder $dropRate $thruput $AvgJitter $AvgLatency"

	flush $f
	close $f
}

#
# This routine enables tracing of UDP traffic to get throughput
#
proc UDPTraceThroughput { ns AgentSrc interval fname } {

	proc UDPThroughputdump { ns newsrc interval fname } {
		set f [open $fname a]
		$ns at [expr [$ns now] + $interval] "UDPThroughputdump $ns $newsrc $interval $fname"

		set mythroughput [expr (([$newsrc set UDPSinkThroughput] / $interval) * 8)]
		puts $f "[$ns now]  $mythroughput"
		$newsrc set UDPSinkThroughput 0

		flush $f
		close $f
	}

	$ns at 0.0 "UDPThroughputdump $ns $AgentSrc $interval $fname"
}

#
#   This builds a BT Cx which is really two one-way TCPs each with an 
#   exponential traf gen with a application throughput that will be controlled
#   by the TCL script handleBT-CX.
#
#    The BTservernodes are the $DestNode param
#    the SrcNode is the CM node
#
#   tcp1 cx has cx id of less than 4500
#       $ns attach-agent $SrcNode $tcp1
#       $ns attach-agent $DestNode $sink1
#        So the tcp1 cx source is the CM - this makes it US to the CM.
#            and DS to the BT peer
#
#   tcp2 cx has cx id  >=4500
#       $ns attach-agent $SrcNode $sink2
#       $ns attach-agent $DestNode $tcp2
#       So the 4500 cxs are DS to the CM.
#
#  It's invokes :
#  BuildBTCxs $ns $n($dstNode) $BTServerNodes($srcNode) 1 
#        $BTBURSTTIME $BTIDLETIME $tmpX $cxid  $stoptime $P2PWINDOW $protID $asymLevel
#
#  $A0: 11/15/2006: To configure the generators for DS only when asymlevel == 0
#
proc BuildBTCxs { ns SrcNode DestNode Number burstTime idleTime burstRate numberID starttime stoptime window protID asymlevel debug logStatsFlag newFileOutDS newFileOutUS priority} {

	global TCPUDP_THROUGHPUT_MONITORS_ON
	
	if { $TCPUDP_THROUGHPUT_MONITORS_ON == 1} {
		exec rm -f $newFileOutDS
		exec rm -f $newFileOutUS
	}
	
	# set asymlevel  1
	set interval   10
	
	set printtime $stoptime
	
	exec rm -f P2PTCPstats.out
	exec rm -f USP2PTCPstats.out
	exec rm -f DSP2PTCPstats.out
	
	# set burstRate [uniform $burstRateLow $burstRateHigh]
	
	for {set i 0} {$i < $Number} {incr i} {
		set fname "TORRENT[expr $i + $numberID].out"
		exec rm -f $fname
		
		if { $debug == 1} {
			puts "Create EXP TCP Cx #  [expr $i+$numberID] (file $fname), burstRate: $burstRate and asymlevel: $asymlevel"
		}
		
		#PROTID
		if { $protID == 1 } {
			set tcp1 [new Agent/TCP/Reno]
			set tcp2 [new Agent/TCP/Reno]
		}
		if { $protID == 9 } {
			#  puts "Create a SACk test flow.."
			set tcp1 [new Agent/TCP/Sack1]
			set tcp2 [new Agent/TCP/Sack1]
		}
		if { $protID == 2 } {
			set tcp1 [new Agent/TCP/Newreno]
			set tcp2 [new Agent/TCP/Newreno]
		}
		if { $protID == 7 } {
			set tcp1 [new Agent/TCP/Reno]
			set tcp2 [new Agent/TCP/Reno]
			#RED
			$tcp1 set ecn_ 1
			$tcp2 set ecn_ 1
		}
		
		#set sink1 [new Agent/TCPSink/DelAck]
		#set sink2 [new Agent/TCPSink/DelAck]
		if {$protID != 8} {
			if { $protID == 9 } {
				#    puts "Create a Sack1/DelAck sink"
				set sink1 [new Agent/TCPSink/Sack1/DelAck]
				set sink2 [new Agent/TCPSink/Sack1/DelAck]
			} else {
				#set sink1 [new Agent/TCPSink]
				set sink1 [new Agent/TCPSink/DelAck]
				set sink2 [new Agent/TCPSink/DelAck]
			}
		}

		$tcp1 set fid_  [expr $i+$numberID]
		$sink1 set fid_ [expr $i+$numberID]
		$sink1 set sinkId_ [expr $i+$numberID]
		$tcp2 set fid_  [expr $i+$numberID+500]
		$sink2 set fid_ [expr $i+$numberID+500]
		$sink2 set sinkId_ [expr $i+$numberID+500]
		
		$ns attach-agent $SrcNode $tcp1
		$ns attach-agent $DestNode $sink1
		#$A0
		if { $asymlevel != 0 } {
			$ns connect $tcp1 $sink1
		}
		
		$ns attach-agent $SrcNode $sink2
		$ns attach-agent $DestNode $tcp2
		$ns connect $tcp2 $sink2

		$tcp1 set prio_  $priority
		$tcp2 set prio_  $priority
		$sink1 set prio_  $priority
		$sink2 set prio_  $priority
		
		$tcp1 set packetSize_ 1460
		$tcp1 set maxcwnd_ $window
		$tcp1 set window_ $window
		
		$tcp2 set packetSize_ 1460
		$tcp2 set maxcwnd_ $window
		$tcp2 set window_ $window
		
		$tcp1 set cxId_ [expr $i+$numberID]
		$tcp1 set overhead_ 0.000020
		$tcp2 set cxId_ [expr $i+$numberID+500]
		$tcp2 set overhead_ 0.000020
		
		set exp1 [new Application/Traffic/Exponential]
		$exp1 attach-agent $tcp1
		$exp1 set packetSize_ 1460
		$exp1 set burst_time_ $burstTime
		$exp1 set idle_time_ $idleTime
		$exp1 set rate_ $burstRate
		if { $asymlevel != 0 } {
			$ns at [expr $starttime + [uniform 0 3]] "$exp1 start"
			$ns at $stoptime  "$exp1 stop"
		}
		
		set exp2 [new Application/Traffic/Exponential]
		$exp2 attach-agent $tcp2
		$exp2 set packetSize_ 1460
		$exp2 set burst_time_ $burstTime
		$exp2 set idle_time_ $idleTime
		$exp2 set rate_ $burstRate
		$ns at [expr $starttime + [uniform 3 6]] "$exp2 start"
		$ns at $stoptime  "$exp2 stop"
		
		set IntervalOffset [uniform 0 2]
		#$A0
		if { $asymlevel  != 0 } {
			#To have the TCP connections not do BT comment this out
			#But remember the BT peers will usually have low access link speeds
			handleBT-CX  $ns  $exp1 $sink1 $exp2 $sink2 [expr $interval + $IntervalOffset] $asymlevel $burstRate $numberID $fname  $debug
		}
		
		if { $TCPUDP_THROUGHPUT_MONITORS_ON == 1} {
			TraceThroughput $ns $sink1  1.0 $newFileOutUS
			TraceThroughput $ns $sink2  1.0 $newFileOutDS
		}

		#to create a tcp throughput file ..
		#  $ns at $printtime "dumpFinalTCPStats  [expr $i+$numberID] 0 $tcp1  $sink1 P2PTCPstats.out"
		#  $ns at $printtime "dumpFinalTCPStats  [expr $i+$numberID+500] 0 $tcp2  $sink2 P2PTCPstats.out"
		if { $logStatsFlag  == 1 } {
			$ns at $printtime "dumpFinalTCPStats  [expr $i+$numberID] 0 $tcp1  $sink1 P2PTCPstats.out"
			$ns at $printtime "dumpFinalTCPStats  [expr $i+$numberID+500] 0 $tcp2  $sink2 P2PTCPstats.out"
			$ns at $printtime "dumpFinalTCPStats  [expr $i+$numberID] 0 $tcp1  $sink1 USP2PTCPstats.out"
			$ns at $printtime "dumpFinalTCPStats  [expr $i+$numberID+500] 0 $tcp2  $sink2 DSP2PTCPstats.out"
		}
	}
}

#
# function : handleBT-CX
#   exp1 is the sender at the CM, sink1 is the receiver at a wired BT peer 
#   exp2 is the sender at a wired BT peer, sink2 is the receiver at  a CM
#
#   asymlevel==0 means all DS
#
proc handleBT-CX { ns exp1 sink1 exp2 sink2 interval asymlevel maxRate numberID fname debug} {

	if { $debug == 1} {
		puts "We will open handleBT-CX $numberID) file $fname with interval of $interval"
	}

#To not do any adaptation...
# return

	proc handleBT-CXLocal { ns exp1 sink1 exp2 sink2 interval asymlevel maxRate ID fname debug } {
		set minRate [expr .02 * $maxRate]
		set thresh 0
		#          set thresh .2
		
		set dec1 .125
		set dec2 .125
		#          set dec2 .5
		
		if { $debug == 1} {
			set f [open $fname a]
		}
		
		$ns at [expr [$ns now] + $interval] "handleBT-CXLocal $ns $exp1 $sink1 $exp2 $sink2 $interval $asymlevel $maxRate $ID $fname $debug"
		
		if { $debug == 1} {
			puts "handleBT: [$ns now]/throughput-bytes=[$sink1 set sinkThroughput]"
			puts "handleBT: [ns now]/throughput=[expr ( ([$sink1 set sinkThroughput]/ $interval) * 8) ]"
		}
		
		set rate1 [expr ( ([$sink1 set sinkThroughput]/ $interval) * 8) ]
		#           set tmpBytes [$sink1 set sinkThroughput]
		
		if { $debug == 1} {
			puts "handleBT: TraceThroughput:  [$ns now]  $rate1"
		}
		
		set rate2 [expr ( ([$sink2 set sinkThroughput]/ $interval) * 8) ]
		#Get the current send rates
		
		set expRate1 [$exp1 set rate_]
		set expRate2 [$exp2 set rate_]
		
		if { $rate2 == 0 } {
			set rate2  1
		}
		if { $rate1 == 0 } {
			set rate1  1
		}
		
		set op 0
		set ratio1 [expr $rate1/$rate2]
		set ratio2 [expr $rate2/$rate1]
		
		if { $debug == 1} {
			puts "handleBT:CURRENT: [$ns now] $ID ratio1: $ratio1,  ratio2: $ratio2,  threshold: [expr $asymlevel + $thresh]"
			puts "handleBT:CURRENT: [$ns now] $ID US expRate1:actual: $expRate1:$rate1 ;  DS expRate2:actual: $expRate2:$rate2"
		}
		
		if {[expr $rate1/$rate2] > [expr $asymlevel + $thresh]} {
			if {[expr $rate1/$rate2] > [expr $expRate1/$expRate2 ]} {
				#Case 1
				set op 1
				#inc exp2 else dec exp1
				
				if { $debug == 1} {
					puts "handleBT: :  inc exp2"
				}
				
				set expRate2 [expr $expRate2+($dec1*$expRate2)]
				if { $expRate2 > $maxRate } {
					if { $debug == 1} {
						puts "handleBT: :  ooops,  I mean decrement exp1"
					}
					set op 2
					set expRate1 [expr $expRate1-($dec2*$expRate1)]
				}
			} else {
				set op 3
				
				if { $debug == 1} {
					puts "handleBT: :  inc exp2"
				}
				
				set expRate2 [expr $expRate2+($dec1*$expRate2)]
				if { $expRate2 > $maxRate } {
					if { $debug == 1} {
						puts "handleBT: :  ooops,  I mean decrement exp1"
					}
					set op 4
					set expRate1 [expr $expRate1-($dec2*$expRate1)]
				}
			}
		} elseif {[expr $rate1/$rate2] <= [expr $asymlevel + $thresh]} {
			if {[expr $rate1/$rate2] <= [expr $expRate1/$expRate2 ]} {
				set op 5
				
				if { $debug == 1} {
					puts "handleBT: :  increment exp1"
				}
				
				set expRate1 [expr $expRate1+($dec1*$expRate1)]
				if { $expRate1 > $maxRate } {
					if { $debug == 1} {
						puts "handleBT: :  ooops,  I mean decrement exp2"
					}
					set op 6
					set expRate2 [expr $expRate2-($dec2*$expRate2)]
				}
			} else {
				set op 7
				
				if { $debug == 1} {
					puts "handleBT: :  increment exp1"
				}
				
				set expRate1 [expr $expRate1+($dec1*$expRate1)]
				if { $expRate1 > $maxRate } {
					if { $debug == 1} {
						puts "handleBT: :  ooops,  I mean decrement exp2"
					}
					set op 8
					set expRate2 [expr $expRate2-($dec2*$expRate2)]
				}
			}
		} else {
			set op 9
			puts "handleBT: :  ERROR???? increase both exp1 and exp2"
		}
		
		if { $expRate1 > $maxRate } {
			set expRate1 $maxRate
		}
		if { $expRate2 > $maxRate } {
			set expRate2 $maxRate
		}
		if { $expRate1 < $minRate } {
			set expRate1 $minRate
		}
		if { $expRate2 < $minRate } {
			set expRate2 $minRate
		}

		#Set the new exp rates
		#          $exp1 set rate_ $expRate1
		#          $exp2 set rate_ $expRate2
		$exp1 setRate $expRate1
		$exp2 setRate $expRate2
		
		#          set expRate1 [$exp1 set rate_]
		#          set expRate2 [$exp2 set rate_]

#          puts "[$ns now] (id:$ID;op:$op)  observed rates (US:DS):  $rate1:$rate2,  adjusted rates (US:DS): $expRate1:$expRate2"

		if { $debug == 1} {
			puts $f "[$ns now] (id:$ID;op:$op) rates (US:DS): $rate1:$rate2, Adjrates (US:DS): $expRate1:$expRate2, ratio1:ratio2: $ratio1:$ratio2,  [expr $asymlevel + $thresh]"
			puts "handleBT:UPDATE: [$ns now] (id:$ID;op:$op) rates (US:DS): $rate1:$rate2, Adjrates (US:DS): $expRate1:$expRate2, ratio1:ratio2: $ratio1:$ratio2,  [expr $asymlevel + $thresh]"
		}
		
		if { $debug == 1} {
			flush $f
			close $f
		}
		
		$sink1 set sinkThroughput 0
		$sink2 set sinkThroughput 0
	}

	$ns at [$ns now] "handleBT-CXLocal $ns $exp1 $sink1 $exp2 $sink2 $interval $asymlevel $maxRate $numberID $fname $debug"
}

