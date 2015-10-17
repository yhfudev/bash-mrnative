#
# This script defines ping utility TCL procedures
#

# Global variables for Ping 
set lastPingReceived 0
set totalPings 0
set totalPingDrops 0

#
# This proc starts ping process
#
proc startPingProcess {ns pinger interval} {
	proc doPing {ns mypinger myinterval} {
		global totalPings totalPingDrops
		
		$mypinger send
		#puts "warning ping send off ..........."
		incr totalPings
		
		$ns at [expr [$ns now] + $myinterval + [uniform .001 .009]] "doPing $ns $mypinger $myinterval"
	}
	$ns at 0.0 "doPing $ns $pinger $interval"
}

#
# This proc prints ping statistics
#
proc doPingStats {} {
	global totalPings totalPingDrops

	set lossRate [expr $totalPingDrops * 1.0 / $totalPings * 1.0]
	puts "Ping: total sent = $totalPings; total dropped = $totalPingDrops; loss rate = [expr $lossRate * 100]"
}

#
# This method implements recv proc for Ping Agent
#
Agent/Ping instproc recv {from snum rtt} {
	global lastPingReceived totalPingDrops
	global ns docsislan

	#puts "ping:recv([$ns now]): entered with snum = $snum and rtt = $rtt"

	set pingtrace [open ping1.out a]

	if { $snum > 0 } {
	
		if { [expr $lastPingReceived + 1] != $snum } {
			#puts "Ping:recv([$ns now]):Dropped 1 snum = $snum, lastPingReceived = $lastPingReceived"
			incr totalPingDrops
			
			set lastPingReceived [expr $lastPingReceived + 1]
			puts $pingtrace "[$ns now] 0 $lastPingReceived"

			# get here if we lost 2 consecutive ping's
			if { [expr $lastPingReceived + 1] != $snum } {
				#puts "Ping:recv([$ns now]):Dropped 2 snum = $snum, lastPingReceived = $lastPingReceived"
				incr totalPingDrops
				
				set lastPingReceived [expr $lastPingReceived + 1]
				puts $pingtrace "[$ns now] 0 $lastPingReceived"

				# get here if we lost 3 consecutive ping's
				if { [expr $lastPingReceived + 1] != $snum } {
					#puts "Ping:recv([$ns now]):Dropped 3 snum = $snum, lastPingReceived = $lastPingReceived"
					incr totalPingDrops

					set lastPingReceived [expr $lastPingReceived + 1]
					puts $pingtrace "[$ns now] 0 $lastPingReceived"

					# get here if we lost 4 consecutive ping's
				        if { [expr $lastPingReceived + 1] != $snum } {
						#puts "Ping:recv:([$ns now]):Dropped 4 snum = $snum, lastPingReceived = $lastPingReceived"
						incr totalPingDrops
						
						set lastPingReceived [expr $lastPingReceived + 1]
						puts $pingtrace "[$ns now] 0 $lastPingReceived"
					}	; # lost 4
				}	; # lost 3
			}	; # lost 2
		}	; # lost 1
	}

	set lastPingReceived $snum

#so do the next ping right away instead of every interval
#so the ping flood mode....
#note:  I need a timeout to make this work...
#   set pingDelay .001
#   $ns at [expr [$ns now] + $pingDelay] "$p1 send"

	#$self instvar node_
	puts $pingtrace "[$ns now] $rtt $lastPingReceived"
	close $pingtrace
}



