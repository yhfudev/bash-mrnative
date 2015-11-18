#
# This is a simple script for a calibration run.  It runs 10 TCP/FTP flows
# with varied RTTs.
#

# ---------------------------------------------------------------

# Source configuration parameters from other TCL scripts
source cleanup.tcl
source sched-defs.tcl
source dash.tcl
source docsis-conf.tcl
source docsis-util.tcl
source lossmon-util.tcl
source ping-util.tcl
source tcpudp-util.tcl
source networks.tcl
source flows-util.tcl
source run-conf.tcl		; # do this the last
# Note: any settings follows can still overwrite the settings in the sourced scripts
#set WINDOW 65536
#set DEFAULT_BUFFER_CAPACITY 32768

# Other config parameters
#set SCENARIO	1
#set SCENARIO	2
#set SCENARIO	3

# RNG seeding / substream selection
global defaultRNG
if {$argc == 1} {
	set MYSEED [lindex $argv 0];	# default MYSEED set in other TCL file
}
if {$MYSEED < 11} {
	# If see MYSEED < 11 we will assume we are to use next RNG substream
	for {set j 1} {$j < $MYSEED} {incr j} {
		$defaultRNG next-substream
	}
	puts "Setting RNG seed to substream $j"
} else {
	# seed the default RNG with MYSEED
	$defaultRNG seed $MYSEED
	puts "Setting RNG seed with value $MYSEED"
}


# Show simulation messages
puts "Simulation starts now ..."
if {$ALL_UDP == 1} {
	puts "Start a run with $NUM_CM CMs, all UDP traffic, direction $TRAFFIC_DIRECTION"
	puts "CBR: target rate: $TARGET_VIDEO_RATE, PACKETSIZE: $PACKETSIZE, INTERVAL: $CBR_INTERVAL"
} elseif {$ALL_UDP == 0} {
	puts "Start a run with $NUM_CM CMs, all TCP traffic, direction $TRAFFIC_DIRECTION"
	puts "TRAFFIC_TYPE: $TRAFFIC_TYPE, TCP_PROT_ID: $TCP_PROT_ID"
} else {
	puts "ERROR: Bad ALL_UDP (= $ALL_UDP)"
	exit 0
}

# Call cleanup first
puts "Clean up output files first ..."
cleanup


# ---------------------------------------------------------------

# Create a NS simulator object
set ns [new Simulator]

# Build a basic cable network topology
#
# Make sure configuration files are in place:
#
#	CMBGUS.dat
#	CMBGDS.dat
#	BG.dat
#	channels.dat
#
#create_cable_topology0_jjm_router_16ftps_16dashs $NUM_CM 0.5	; # delay = 0.5 ms
create_cable_topology_1G $NUM_FTPs $NUM_DASHs $NUM_WEBs $NUM_CM 0.5	; # delay = 0.5 ms
#puts $lan

#
source profile.tcl

# save the node information
set foe [open "nodemac.out" "w"]
puts $foe "[$lan mac-address $n0]	cmts"
set cm_index 1
for {set i 0} {$i < $NUM_FTPs} {incr i} {
    puts $foe "[$lan mac-address $CM([expr $i + $cm_index])]	cm_ftp_$i"
}
set cm_index [expr $cm_index + $NUM_FTPs]
for {set i 0} {$i < $NUM_UDPs} {incr i} {
    puts $foe "[$lan mac-address $CM([expr $i + $cm_index])]	cm_udp_$i"
}
set cm_index [expr $cm_index + $NUM_UDPs]
for {set i 0} {$i < $NUM_DASHs} {incr i} {
    puts $foe "[$lan mac-address $CM([expr $i + $cm_index])]	cm_has_$i"
}
set cm_index [expr $cm_index + $NUM_DASHs]
close $foe



set cm_index 1
# Build a basic flow set - create a flow for each CM
#
if { $NUM_FTPs > 0 } {
	create_ftp_flow_set $NUM_FTPs $cm_index
	#create_flow_set0_src_ftp_servers $NUM_FTPs $ALL_UDP $TRAFFIC_DIRECTION $TRAFFIC_TYPE $CBR_INTERVAL $TARGET_VIDEO_RATE $TCP_PROT_ID
	set cm_index [expr $cm_index + $NUM_FTPs]
}

set MAXCHANNELBW 2158700000

# Build a bad UDP flow
if { $NUM_UDPs > 0 } {
    #create_DS_UDP_sessions $NUM_UDPs $cm_index
    for {set i 0} {$i < $NUM_UDPs} {incr i} {
        create_DS_UDP_bad_flow $n2 [expr $cm_index + $i] $PACKETSIZE [expr $MAXCHANNELBW / $NUM_UDPs / 5 * 7]
    }
    set cm_index [expr $cm_index + $NUM_UDPs]
}

# Build a DASH flow set
if { $NUM_DASHs > 0 } {
	create_dash_video_flow_set $NUM_DASHs $cm_index
	set cm_index [expr $cm_index + $NUM_DASHs]
}

# Build traffic set
#
# Loss Monitor: n2 ------- n0 (CMTS) ------- n1
if { $LOSS_MONITOR_ON > 0 } {
	create_lossmon_flow $LOSS_MONITOR_DS $LOSS_MONITOR_US
}
# Ping Monitor: n2 ------- n0 (CMTS) ------- n1
if { $PING_MONITOR_ON > 0 } {
	create_ping_flow $TRAFFIC_DIRECTION
}
# UDP Monitor (CBR traffic): n2 ------- n0 (CMTS) ------- n1
if { $UDP_MONITOR_TYPE > 0 } {
	create_udpmon_flow $TRAFFIC_DIRECTION
}

# Schedule finish event at stop time
proc finish {} {
	global ns
	
	$ns flush-trace
	
	puts "Finish simulation at [$ns now] seconds."
	exit 0
}
$ns at $stoptime "finish"

# Run the simulator
$ns run

# Safety (should have been called in 'finish')
exit 0

