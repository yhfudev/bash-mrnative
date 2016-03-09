
# maxv -- the number of the items in the list, >= 1
# maxi -- the number of different values
proc idx_get_interval {maxv maxi idx} {
    if {$maxi < 2} {
      return [expr $maxv - 1 ]
    }
    set v [expr $maxv / $maxi ];
    if { [expr $v * $maxi] < $maxv } { set v [expr $v + 1] };
    if { $v < 1 } { set v 1 };
    #msg "maxv=$maxv; maxi=$maxi, idx=$idx; v=$v"
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
    #set timestamp [clock format [clock seconds]]
    #puts $fh_msg "$timestamp - $msg1"
    puts $fh_msg "$msg1"
    flush $fh_msg
}

msg "Start NS2 DOCSIS testing ..."

# the profile config for 24.5MHz channel in DOCSIS 3.1
#                       QPSK,    8,       16,      32,     64,     128,    256,    512,    1024,   2048,   4096,   8192,   16384
# base = 23.6 MHz
# 4K async = 0.482327
set profiles_4k_async_24m { 1.00000  1.50000  2.00000  2.50000 3.00000 3.50000 4.00000 4.50000 5.00000 5.50000 6.00000 6.50000 7.00000}
# 4K sync = 0.546000
set profiles_4k_sync_24m { 1.13201  1.69802  2.26403  2.83003 3.39604 3.96205 4.52805 5.09406 5.66007 6.22607 6.79208 7.35809 7.92409}
# 8K async = 0.624468
set profiles_8k_async_24m { 1.29470  1.94205  2.58940  3.23675 3.88410 4.53145 5.17880 5.82615 6.47350 7.12085 7.76820 8.41555 9.06290}
# 8K sync = 0.691887
set profiles_8k_sync_24m { 1.43448  2.15172  2.86896  3.58620 4.30344 5.02068 5.73791 6.45515 7.17239 7.88963 8.60687 9.32411 10.04135}

# the profile config for 49MHz channel in DOCSIS 3.1
#                       QPSK,    8,       16,      32,     64,     128,    256,    512,    1024,   2048,   4096,   8192,   16384
# base = 62.3 MHz
# 4K async = 0.629515
set profiles_4k_async_49m { 1.00000  1.50000  2.00000  2.50000 3.00000 3.50000 4.00000 4.50000 5.00000 5.50000 6.00000 6.50000 7.00000}
# 4K sync = 0.661030
set profiles_4k_sync_49m { 1.05006  1.57509  2.10013  2.62516 3.15019 3.67522 4.20025 4.72528 5.25031 5.77534 6.30038 6.82541 7.35044}
# 8K async = 0.722856
set profiles_8k_async_49m { 1.14827  1.72241  2.29655  2.87068 3.44482 4.01896 4.59309 5.16723 5.74137 6.31550 6.88964 7.46378 8.03792}
# 8K sync = 0.756225
set profiles_8k_sync_49m { 1.20128  1.80192  2.40256  3.00320 3.60384 4.20448 4.80512 5.40576 6.00641 6.60705 7.20769 7.80833 8.40897}

# the profile config for 97MHz channel in DOCSIS 3.1
#                       QPSK,    8,       16,      32,     64,     128,    256,    512,    1024,   2048,   4096,   8192,   16384
# base = 135.8 MHz
# 4K async = 0.699990
set profiles_4k_async_97m { 1.00000  1.50000  2.00000  2.50000 3.00000 3.50000 4.00000 4.50000 5.00000 5.50000 6.00000 6.50000 7.00000}
# 4K sync = 0.716072
set profiles_4k_sync_97m { 1.02298  1.53446  2.04595  2.55744 3.06893 3.58041 4.09190 4.60339 5.11488 5.62636 6.13785 6.64934 7.16083}
# 8K async = 0.770114
set profiles_8k_async_97m { 1.10018  1.65027  2.20036  2.75045 3.30054 3.85063 4.40072 4.95081 5.50090 6.05098 6.60107 7.15116 7.70125}
# 8K sync = 0.787143
set profiles_8k_sync_97m { 1.12451  1.68676  2.24901  2.81126 3.37352 3.93577 4.49802 5.06028 5.62253 6.18478 6.74704 7.30929 7.87154}

# the profile config for 192MHz channel in DOCSIS 3.1
#                       QPSK,    8,       16,      32,     64,     128,    256,    512,    1024,   2048,   4096,   8192,   16384
# base: 282.8M
# 4K async = 0.736500
set profiles_4k_async_192m { 1.00000  1.50000  2.00000  2.50000 3.00000 3.50000 4.00000 4.50000 5.00000 5.50000 6.00000 6.50000 7.00000}
# 4K sync = 0.744700
set profiles_4k_sync_192m  { 1.01113  1.51670  2.02227  2.52783 3.03340 3.53897 4.04453 4.55010 5.05567 5.56124 6.06680 6.57237 7.07794}
# 8K async = 0.794500
set profiles_8k_async_192m { 1.07875  1.61813  2.15750  2.69688 3.23625 3.77563 4.31500 4.85438 5.39375 5.93313 6.47251 7.01188 7.55126}
# 8K sync = 0.803100
set profiles_8k_sync_192m  { 1.09043  1.63564  2.18086  2.72607 3.27128 3.81650 4.36171 4.90692 5.45214 5.99735 6.54257 7.08778 7.63299}


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
        msg "idx=$i, v=[lindex $curr_profile $i]"
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
        msg "set flow $c to profile [expr [llength $curr_profile] - 2 - 1 ] ..."
        $lan assign-dlprofile $CM($c) [expr [llength $curr_profile] - 2 - 1 ]
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
    msg "set the profiles to interval values start=$cm_node_start, cnt=$cm_node_count ..."
    global lan
    global curr_profile
    global CM
    for {set i 0} {$i < $cm_node_count} {incr i} {
        set c [expr $i + $cm_node_start ]
        msg "1 idx_get_interval [expr [llength $curr_profile] - 2] $cm_node_count $i ..."
        msg "set flow $c to profile [idx_get_interval [expr [llength $curr_profile] - 2] $cm_node_count $i] ..."
        $lan assign-dlprofile $CM($c) [idx_get_interval [expr [llength $curr_profile] - 2] $cm_node_count $i]
    }
}

proc set_config_profile {cm_node_start cm_node_count cm_profile_count str_lst_ratio} {
    msg "set flows by config ..."
    global lan
    global curr_profile
    global CM

    #lappend cm_lst_ratio
    set cm_lst_ratio {}
    set tmp_list1 [split $str_lst_ratio " "]
    foreach item $tmp_list1 {
        scan $item "%f" val1
        lappend cm_lst_ratio $val1
        #msg "ratio '$item'=$val1"
    }

    set cnt 0
    set idx_profile 0
    set ratio 0.0
    set ratio [lindex $cm_lst_ratio $idx_profile]

    msg "init ratio=$ratio"
    while {$cnt < $cm_node_count } {
        msg "compare cnt=$cnt and [expr {$cm_node_count * $ratio}]"
        while {$cnt >= int([expr {$cm_node_count * $ratio}]) && $idx_profile < [llength $cm_lst_ratio] } {
            set idx_profile [expr $idx_profile + 1 ]
            if {$idx_profile < [llength $cm_lst_ratio] } {
                #msg "ratio=$ratio + [lindex $cm_lst_ratio $idx_profile]"
                set ratio [expr $ratio + [lindex $cm_lst_ratio $idx_profile] ]
                #msg "new ratio=$ratio"
            }
        }

        # set profile for $cnt
        set c [expr $cnt + $cm_node_start ]
        msg "2 idx_get_interval $cm_profile_count [llength $cm_lst_ratio] $idx_profile ..."
        msg "call assign-dlprofile CM $c [idx_get_interval $cm_profile_count [llength $cm_lst_ratio] $idx_profile ]"
        $lan assign-dlprofile $CM($c) [idx_get_interval $cm_profile_count [llength $cm_lst_ratio] $idx_profile ]

        set cnt [expr $cnt + 1 ]
    }
}
# tests:
#set str_ratio_list "0.25 0.25 0.5"
#set_config_profile 0 20 [expr [llength $curr_profile] - 2] $lst_ratio

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


msg "set var1 profiles_4k_async_192m ..."
set curr_profile $profiles_4k_async_192m

# set the CMTS dl
setup_dl_scheduler $n0

proc init_profiles {cm_node_start cm_node_count} { set_interval_profiles $cm_node_start $cm_node_count }

set list_ratio_init_udp "0.35 0.65"
set list_ratio_init_ftp "0.35 0.65"
set list_ratio_init_has "0.35 0.65"

set CHANGE_PROFILE_HIGH 0
set CHANGE_PROFILE_LOW  0

# the ratio of changed UDP flows
set CHANGE_RATIO_UDP 0.5
# the ratio of changed FTP flows
set CHANGE_RATIO_FTP 0.5
# the ratio of changed HAS flows
set CHANGE_RATIO_HAS 0.5

set cm_index 1

if { $NUM_FTPs > 0 } {
    #init_profiles $cm_index $NUM_FTPs
    # the nubmer of the list should be [llength $curr_profile] - 2],
    # but this cause a strange timer set error in ns2docsis,
    # to work around the problem, we use [llength $curr_profile] - 1] here
    #set_config_profile $cm_index $NUM_FTPs [expr [llength $curr_profile] - 2] $list_ratio_init_ftp
    set_config_profile $cm_index $NUM_FTPs [expr [llength $curr_profile] - 1] $list_ratio_init_ftp

    set numchg int([expr $NUM_FTPs * $CHANGE_RATIO_FTP ])
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
    #init_profiles $cm_index $NUM_UDPs
    #set_config_profile $cm_index $NUM_UDPs [expr [llength $curr_profile] - 2] $list_ratio_init_udp
    set_config_profile $cm_index $NUM_UDPs [expr [llength $curr_profile] - 1] $list_ratio_init_udp

    set numchg int([expr $NUM_UDPs * $CHANGE_RATIO_UDP ])
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
    #init_profiles $cm_index $NUM_DASHs
    #set_config_profile $cm_index $NUM_DASHs [expr [llength $curr_profile] - 2] $list_ratio_init_has
    set_config_profile $cm_index $NUM_DASHs [expr [llength $curr_profile] - 1] $list_ratio_init_has

    set numchg int([expr $NUM_DASHs * $CHANGE_RATIO_HAS ])
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
