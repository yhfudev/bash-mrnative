
# maxv -- the number of the items in the list, >= 1
# maxi -- the number of different values
proc idx_get_interval {maxv maxi idx} {
    set v [expr $maxv / $maxi ];
    if { [expr $v * $maxi] < $maxv } { set v [expr $v + 1] };
    if { $v < 1 } { set v 1 };
    #puts "maxv=$maxv; maxi=$maxi, idx=$idx; v=$v"
    if { $idx > 0 } {
      if { [expr $idx % $maxi] == [expr $maxi - 1]} {
        set v2 [expr $maxv - 1]
        return $v2
      }
    }
    set v2 [expr ($idx * $v) % $maxv ]
    return $v2
}

#debug code:
#set numberCMs 4
#for {set i 0} {$i < $numberCMs} {incr i} {
#    puts "the number: [idx_get_interval [expr [llength $curr_profile] - 2] $numberCMs $i]"
#}
#exit 0; # debug

# debug file:
set fh_msg [open message.log a]

proc msg {msg1} {
    global fh_msg
    set timestamp [clock format [clock seconds]]
    puts $fh_msg "$timestamp - $msg1"
    flush $fh_msg
}

msg "Start NS2 DOCSIS testing ..."

# the profile config for 192MHz channel in DOCSIS 3.1
#                       QPSK,    8,       16,      32,     64,     128,    256,    512,    1024,   2048,   4096,   8192,   16384
# 4K async = 0.736500
#set profiles_4k_async { 0.13101  0.19652  0.26202  0.32753 0.39303 0.45854 0.52404 0.58955 0.65505 0.72056 0.78606 0.85157 0.91707}
# 4K sync = 0.744700
#set profiles_4k_sync  { 0.13247  0.19870  0.26494  0.33117 0.39741 0.46364 0.52988 0.59611 0.66234 0.72858 0.79481 0.86105 0.92728}
# 8K async = 0.794500
#set profiles_8k_async { 0.14133  0.21199  0.28265  0.35332 0.42398 0.49465 0.56531 0.63597 0.70664 0.77730 0.84796 0.91863 0.98929}
# 8K sync = 0.803100
#set profiles_8k_sync  { 0.14286  0.21429  0.28571  0.35714 0.42857 0.50000 0.57143 0.64286 0.71429 0.78571 0.85714 0.92857 1.00000}

# 4K async = 0.736500
set profiles_4k_async { 1.00000  1.50000  2.00000  2.50000 3.00000 3.50000 4.00000 4.50000 5.00000 5.50000 6.00000 6.50000 7.00000}
# 4K sync = 0.744700
set profiles_4k_sync  { 1.01113  1.51670  2.02227  2.52783 3.03340 3.53897 4.04453 4.55010 5.05567 5.56124 6.06680 6.57237 7.07794}
# 8K async = 0.794500
set profiles_8k_async { 1.07875  1.61813  2.15750  2.69688 3.23625 3.77563 4.31500 4.85438 5.39375 5.93313 6.47251 7.01188 7.55126}
# 8K sync = 0.803100
set profiles_8k_sync  { 1.09043  1.63564  2.18086  2.72607 3.27128 3.81650 4.36171 4.90692 5.45214 5.99735 6.54257 7.08778 7.63299}

proc setup_dl_scheduler {n0} {
    global lan
    global curr_profile
    #global DefaultSchedQSize DefaultSchedQType

    #global DSSCHEDQSize DSSCHEDQType DSSCHEDQDiscipline
    #msg "setup configure-DSScheduler ..."
    #$lan configure-DSScheduler $n0 $DSSCHEDQDiscipline $DSSCHEDQSize $DSSCHEDQType

    msg "configure-profile ..."
    msg "# of items in profile config: [llength $curr_profile]"
    #config-profile <idx> <ratio>
    #$lan configure-profile $n0 0 0.1
    for {set i 0} {$i < [llength $curr_profile]} {incr i} {
        puts "idx=$i, v=[lindex $curr_profile $i]"
        $lan configure-profile $n0 $i [lindex $curr_profile $i]
    }
}

proc set_high_profile {cm_node_start cm_node_count} {
    msg "set all of the flows to the highest profile ..."
    global lan
    global curr_profile
    global CM
    for {set i 0} {$i < $cm_node_count} {incr i} {
        set c [expr $i + $cm_node_start ]
        msg "set flow $c to profile [expr [llength $curr_profile] - 2 ] ..."
        $lan assign-dlprofile $CM($c) [expr [llength $curr_profile] - 2 ]
    }
}

proc set_lower_profile {cm_node_start cm_node_count} {
    msg "set all of the flows to the lowest profile ..."
    global lan
    global curr_profile
    global CM
    for {set i 0} {$i < $cm_node_count} {incr i} {
        set c [expr $i + $cm_node_start ]
        msg "set flow $i to profile 0 ..."
        $lan assign-dlprofile $CM($c) 0
    }
}

proc set_interval_profiles {cm_node_start cm_node_count} {
    msg "set the profiles to interval values ..."
    global lan
    global curr_profile
    global CM
    for {set i 0} {$i < $cm_node_count} {incr i} {
        set c [expr $i + $cm_node_start ]
        msg "set flow $c to profile [idx_get_interval [expr [llength $curr_profile] - 2] $cm_node_count $i] ..."
        $lan assign-dlprofile $CM($c) [idx_get_interval [expr [llength $curr_profile] - 2] $cm_node_count $i]
    }
}

proc time_peak_profiles {cm_node_start cm_node_count} {
    global ns
    global stoptime
    $ns at [expr $stoptime / 3] "set_high_profile $cm_node_start $cm_node_count"
    $ns at [expr $stoptime * 2 / 3] "init_profiles $cm_node_start $cm_node_count";
}

proc time_low_profiles {cm_node_start cm_node_count} {
    global ns
    global stoptime
    $ns at [expr $stoptime / 3] "set_lower_profile $cm_node_start $cm_node_count"
    $ns at [expr $stoptime * 2 / 3] "init_profiles $cm_node_start $cm_node_count";
}



msg "set var1 profiles_8k_sync ..."
set curr_profile $profiles_4k_async

# set the CMTS dl
setup_dl_scheduler $n0

proc init_profiles {cm_node_start cm_node_count} { set_interval_profiles $cm_node_start $cm_node_count }

set CHANGE_PROFILE_HIGH 0
set CHANGE_PROFILE_LOW  0

set cm_index 1

if { $NUM_FTPs > 0 } {
    init_profiles $cm_index $NUM_FTPs
    set numchg [expr $NUM_FTPs / 2]
    if {$NUM_FTPs > 0} {
        if {$numchg <= 0} {
            set numchg 1
        }
    }
    if {$CHANGE_PROFILE_HIGH > 0} {
        time_peak_profiles $cm_index $numchg
    }
    if {$CHANGE_PROFILE_LOW > 0} {
        time_low_profiles $cm_index $numchg
    }
    set cm_index [expr $cm_index + $NUM_FTPs]
}

# Build a bad UDP flow
if { $NUM_UDPs > 0 } {
    init_profiles $cm_index $NUM_UDPs
    set numchg [expr $NUM_UDPs / 2]
    if {$NUM_UDPs > 0} {
        if {$numchg <= 0} {
            set numchg 1
        }
    }
    if {$CHANGE_PROFILE_HIGH > 0} {
        time_peak_profiles $cm_index $numchg
    }
    if {$CHANGE_PROFILE_LOW > 0} {
        time_low_profiles $cm_index $numchg
    }
    set cm_index [expr $cm_index + $NUM_UDPs]
}

# Build a DASH flow set
if { $NUM_DASHs > 0 } {
    init_profiles $cm_index $NUM_DASHs
    set numchg [expr $NUM_DASHs / 2]
    if {$NUM_DASHs > 0} {
        if {$numchg <= 0} {
            set numchg 1
        }
    }
    if {$CHANGE_PROFILE_HIGH > 0} {
        time_peak_profiles $cm_index $numchg
    }
    if {$CHANGE_PROFILE_LOW > 0} {
        time_low_profiles $cm_index $numchg
    }
    set cm_index [expr $cm_index + $NUM_DASHs]
}
