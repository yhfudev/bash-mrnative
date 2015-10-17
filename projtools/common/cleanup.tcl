proc cleanup {} {
	puts "Clean up procedure executing ..."

	# These commands need to be executed before simulation run
	# because some results get appended to output files

	exec rm -f CBR.send
	exec rm -f CBR.recv
	
	eval exec rm -f [glob -nocomplain CMTS*PACKET.*]
	
	eval exec rm -f [glob -nocomplain CM-BW-*.out]
	exec rm -f CMstats.out
	exec rm -f CMQUEUE.out
	exec rm -f CMUSSIDstats.out
	
	eval exec rm -f [glob -nocomplain ?SCMFlows.out]
	
	eval exec rm -f [glob -nocomplain ?SLossMon.out]

	exec rm -f CMTS-BW.out
	exec rm -f CMTSstats.out
	exec rm -f CMTSstatsperchannel.out
	exec rm -f CMTS-DS-QUEUE.out
	exec rm -f DSSIDstats.out
	exec rm -f RESEQMGRstats.out
	exec rm -f BGSIDstats.out
	
	exec rm -f BGOPT.out
	exec rm -f FSADJUST.out
	
	exec rm -f SESSION_TRAF.out	; # Web session data
	exec rm -f snumack.out		; # WRT samples
	exec rm -f wrt.out		; # wrt samples
	
	exec rm -f ping1.out
	
	eval exec rm -f [glob -nocomplain CMUDP*.out]
	exec rm -f UDPstats.out
	
	eval exec rm -f [glob -nocomplain CMTCP*.out]
	exec rm -f TCPstats.out
	
	exec rm -f UDPsink.out
	
	eval exec rm -f [glob -nocomplain out.*]
	eval exec rm -f [glob -nocomplain vodapp*.*]

	puts "Done cleanup!"
}
