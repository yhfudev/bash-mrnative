#
# This script defines loss monitor utility TCL procedures
#

# Global variables for loss monitor utility
set lastLpktReceived 0
set totalLpkts 0
set totalLpktDrops 0

#
# This proc starts loss_mon process:
#
#	This loops for each burst of packets to be sent.
#	The loss_mon server receives the packet and then echos it back.
#	See the recv method in ~/apps/loss_monitor.cc
#
#	burst-size: how many packets in a burst
#
#	as many bursts are allowed as long as time is not exceeded
#
proc startLburstProcess { ns loss_mon burst_size inter_burst_delay inter_pkt_delay end_time} {
	proc doLburst { ns loss_mon burst_size inter_burst_delay inter_pkt_delay end_time } {

		global totalLpkts

		set now_time [expr [$ns now]]
		#puts "doLburst($loss_mon, $now_time) burstsize: $burst_size, burst_delay: $inter_burst_delay"

		set burst_time [expr $now_time + 0.00000000001]
		for {set x 0} {$x < $burst_size} {incr x} {

			#puts "Loss_mon($loss_mon, $now_time): Scheduling a packet transmission, total Lpkts: $totalLpkts "

			$ns at $burst_time "$loss_mon send"
			incr totalLpkts

			set burst_time [expr $burst_time + $inter_pkt_delay]
		}

		if {$now_time < $end_time} {
			$ns at [expr $now_time + $inter_burst_delay] "doLburst $ns $loss_mon $burst_size $inter_burst_delay $inter_pkt_delay $end_time"
		}
	}

	$ns at 0.0 "doLburst $ns $loss_mon $burst_size $inter_burst_delay $inter_pkt_delay $end_time"
}

#
# This proc loops for each packet in a burst.
#
proc startLpktProcess { ns loss_mon burst_size inter_pkt_delay } {

	global totalLpkts
	
	#puts "startLpktProcess([$ns now]) burstsize:$burst_size, pktdelay:$inter_pkt_delay"
	
	set cur_time [expr [$ns now]]
	
	for {set x 0} {$x < $burst_size} {incr x} {
	
		#puts "Loss_mon([$ns now]): Scheduling a packet transmission, total Lpkts: $totalLpkts "
		
		$ns at $cur_time "$loss_mon send"
		incr totalLpkts
		
		set cur_time [expr $cur_time + $inter_pkt_delay]
	}
}

Agent/VOIP_mon instproc recv {from snum rtt ID} {

	global ns
	global lastLpktReceived totalLpktDrops
	
	set cur_time [expr [$ns now]]
	
	#puts "Loss_mon($cur_time))($ID): Received snum :   $snum"
	
	if { $ID == 1 } {	; # Upstream
		set Lpkttrace [open LMpingUS.out a]
		
		#puts "Loss_mon($cur_time)($ID): Received snum :   $snum"
		#puts "Loss_mon($cur_time): Received snum :   $snum"
		
		if  { [expr $lastLpktReceived + 1] != $snum } {
			incr totalLpktDrops
			
			#puts "Loss_mon:Dropped first snum :   $snum"
			
			set lastLpktReceived [expr $lastLpktReceived + 1]
			puts $Lpkttrace "[$ns now] 0 $lastLpktReceived $ID"
			
			# get here if we lost 2 consecutive Lpkt's
			if  { [expr $lastLpktReceived + 1] != $snum } {
				incr totalLpktDrops
				
				#puts "Loss_mon:Dropped second snum:   $snum"
				
				set lastLpktReceived  [expr $lastLpktReceived + 1]
				puts $Lpkttrace "[$ns now]   0 $lastLpktReceived $ID"
				
				# get here if we lost 3 consecutive Lpkt's
				if  { [expr $lastLpktReceived + 1] != $snum } {
					incr totalLpktDrops
					
					#puts "Loss_mon:Dropped third snum:   $snum"
					set lastLpktReceived  [expr $lastLpktReceived + 1]
					puts $Lpkttrace "[$ns now]   0 $lastLpktReceived $ID"
				}
			}
		}
		
		set lastLpktReceived $snum
		$self instvar node_
		
		puts $Lpkttrace "[$ns now] $rtt $lastLpktReceived $ID"
		close $Lpkttrace
	}
	
	if { $ID == 2 } {	; # Downstream
		set Lpkttrace [open LMpingDS.out a]
		
		set cur_time [expr [$ns now]]
		
		#puts "Loss_mon($cur_time)($ID): Received snum :   $snum"
		#puts "Loss_mon($cur_time): Received snum :   $snum"
		
		if  { [expr $lastLpktReceived + 1] != $snum } {
			incr totalLpktDrops
			
			#puts "Loss_mon:Dropped first snum :   $snum"
			
			set lastLpktReceived  [expr $lastLpktReceived + 1]
			puts $Lpkttrace "[$ns now] 0 $lastLpktReceived $ID"
			
			# get here if we lost 2 consecutive Lpkt's
			if  { [expr $lastLpktReceived + 1] != $snum } {
				incr totalLpktDrops
				
				#puts "Loss_mon:Dropped second snum:   $snum"
				
				set lastLpktReceived  [expr $lastLpktReceived + 1]
				puts $Lpkttrace "[$ns now]   0 $lastLpktReceived $ID"
				
				# get here if we lost 3 consecutive Lpkt's
				if  { [expr $lastLpktReceived + 1]  != $snum } {
					incr totalLptDrops
					
					#puts "Loss_mon:Dropped third snum:   $snum"
					
					set lastLpktReceived  [expr $lastLpktReceived + 1]
					puts $Lpkttrace "[$ns now]   0 $lastLpktReceived $ID"
				}
			}
		}
		
		set lastLpktReceived $snum
		$self instvar node_
		
		puts $Lpkttrace "[$ns now] $rtt $lastLpktReceived $ID"
		close $Lpkttrace
	}
}

