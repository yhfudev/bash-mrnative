#
# This script defines DOCSIS utility TCL procedures
#

#
# This proc calls DOCSIS CM method to get and reset bytes sent and received
# and computes the throughput. This calls:
#
#	$mac dump-BW-cm $CMnode $fname   (see vlan.tcl)
#
# which will call the CM objects dumpBWCM method (in mac-docsiscm.cc).
#
# Dumps the throughput in bits per second as shown below:
#
#   timestamp   BW upstream(bps) BW downstream(bps)      
#     0.000000    0.00    	 0.00
#     1.000000    0.00  	 215568.00
#     2.000000  1856928.00  	 206216.00
#     3.000000  3232304.00  	 201784.00
#     4.000000  3256752.00  	 201080.00
#
proc TraceCMBW { mac ns CMnode interval fname } {
	#puts "We will open TraceCMBW file $fname"
	proc ThroughputCMdump { mac ns CMnode interval fname } {
		#puts "TraceCMBW:  Invoke ... [$ns now]"
		$mac dump-BW-cm $CMnode $fname
		$ns at [expr [$ns now] + $interval] "ThroughputCMdump $mac $ns $CMnode $interval $fname"
	}
	$ns at 0.0 "ThroughputCMdump $mac $ns $CMnode $interval $fname"
}

#
# This proc calls DOCSIS CM method to print stats. It can be called
# periodically during a simulation but typically will be called once
# at the end of the simulation run.
#
# It is invoked as follows:
#
#	$ns at $printtime "dumpCMStats mac ns CMnode logfile"
#
# Eventually this calls the CM objects dumpFinalCMStats method.
#
# Output:
#
#	dumpFinalCMStats(10.100000) Total drops: 0;  loss rate: 0.000000 percent
#	Total Packets received downstream: 4495, Total Packets sent upstream: 2314
#	Total Bytes received downstream: 255768, Total Bytes sent upstream: 3530394
#	Total Collisions: 0, Total Fragments: 0
#
proc dumpCMStats { mac ns CMnode fname } {
	$mac dump-final-cm-stats $CMnode $fname
}

# 
# This proc calls DOCSIS CMTS method to get and reset bytes sent and received
# and computes the throughput. This calls:
#
#	$mac dump-BW-cmts $CMTSnode $fname   (see vlan.tcl)
#
# which will call the CMTS objects dumpBWCMTS method (in mac-docsiscmts.cc).
#
# Dumps the throughput in bytes per second as shown below:
#
#   timestamp   BW upstream(bps) BW downstream(bps)      
#     0.000000    0.00    	 0.00
#
proc TraceCMTSBW { mac ns CMTSnode interval fname } {
	#puts "We will open TraceCMTSBW file $fname"
	proc ThroughputCMTSdump { mac ns CMTSnode interval fname } {
		#puts "TraceCMTSBW:  Invoke ... [$ns now]"
		$mac dump-BW-cmts $CMTSnode $fname
		$ns at [expr [$ns now] + $interval] "ThroughputCMTSdump $mac $ns $CMTSnode $interval $fname"
	}
	$ns at 0.0 "ThroughputCMTSdump $mac $ns $CMTSnode $interval $fname"
}

#
# This proc calls DOCSIS CMTS method to print stats. It can be called
# periodically during a simulation but typically will be called once
# at the end of the simulation run.
#
# It is invoked as follows:
#
#	$ns at $printtime "dumpCMTSStats mac ns CMTSnode logfile"
#
# Eventually this calls the CMTS objects dumpFinalCMTSStats method.
#
# Output:
#
#	dumpFinalCMTSStats(10.100000) Total drops in DS: 0;  loss rate: 0.000000 percent
#	Total Packets sent downstream: 4495, Total Packets received upstream: 3464
#	Total Bytes sent downstream: 255768, Total Bytes received upstream: 3527338
#	downstream Util: 0.668 percent, upstream Util: 54.569 percent
#
proc dumpCMTSStats { mac ns CMTSnode fname } {
	$mac dump-final-cmts-stats $CMTSnode $fname
}

#
# This proc calls DOCSIS CM or CMTS method to dump queue statistics
#
#  The output is as follows:
#     timestamp 	max_qnp_ 	min_qnp_ 	qnp_  	util
#	0.000000  	0  		0 		0  	0.000
#	1.000000  	0  		0 		0  	0.712
#	2.000000  	1  		0 		1  	0.679
#	3.000000  	1  		1 		1	0.665
#
#   max_qnp_:  During the current interval, this is the maximum queue size in packets
#   min_qnp_:  During the current interval, this is the minimum queue size in packets
#   qnp_    :  Current number of packets in the queue
#   util:      During the current interval, we compute the utilization of the channel.  We
#              divide the total number of bytes sent by the total number of
#		bytes that could possibly be sent (based on the channel capacity).  
#
#  NOTE:      This is only implemented for the CMTS downstream queue.  
# 		For the upstream, we would have to implement a queue monitor for each SID queue
#               since a CM will has a separate queue for each service ID.
#              This is TODO!!!
#
proc TraceDOCSISQueue {mac ns CMnode interval fname} {
	proc internalTraceDOCSISQueue { mac ns CMnode interval fname } {
		$mac dump-docsis-queue-stats $CMnode $fname
		$ns at [expr [$ns now] + $interval] "internalTraceDOCSISQueue $mac $ns $CMnode $interval $fname"
	}
	$ns at 0.0 "internalTraceDOCSISQueue $mac $ns $CMnode $interval $fname"
}

#
# This proc calls DOCSIS CM or CMTS method to dump utilization statistics
#
# Output:
#       timestamp  downstream util    upstream util
#	0.000000 	0.000 		0.000
#	1.000000 	0.000 		0.000
#	2.000000 	0.000 		0.358
#	3.000000 	0.000 		0.994
#
proc TraceDOCSISUtilization {mac ns CMnode interval fname DSdataRate USdataRate} {
	proc internalTraceDOCSISUtil { mac ns CMnode interval fname DSdataRate USdataRate } {
		$mac dump-docsis-util-stats $CMnode $fname $DSdataRate $USdataRate
		$ns at [expr [$ns now] + $interval] "internalTraceDOCSISUtil $mac $ns $CMnode $interval $fname $DSdataRate $USdataRate"
	}
	$ns at 0.0 "internalTraceDOCSISUtil $mac $ns $CMnode $interval $fname $DSdataRate $USdataRate"
}

