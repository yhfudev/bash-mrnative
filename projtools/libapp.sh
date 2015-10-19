#!/bin/bash
#
# the app related functions
#
# Copyright 2015 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################
my_getpath () {
  PARAM_DN="$1"
  shift
  #readlink -f
  DN="${PARAM_DN}"
  FN=
  if [ ! -d "${DN}" ]; then
    FN=$(basename "${DN}")
    DN=$(dirname "${DN}")
  fi
  cd "${DN}" > /dev/null 2>&1
  DN=$(pwd)
  cd - > /dev/null 2>&1
  echo "${DN}/${FN}"
}
DN_EXEC=$(dirname $(my_getpath "$0") )
#####################################################################

FN_TCL=main.tcl

run_one_ns2 () {
    PARAM_DN_PARENT=$1
    shift
    PARAM_DN_TEST=$1
    shift

    cd       "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/"
    rm -f *.bin *.txt *.out out.* *.tr *.log tmp*
    echo ${EXEC_NS2} ${FN_TCL} 1 "${PARAM_DN_TEST}" FILTER grep PFSCHE TO "${FN_LOG}" 1>&2
    #${EXEC_NS2} ${FN_TCL} 1 "${PARAM_DN_TEST}" 2>&1 | grep PFSCHE >> "${FN_LOG}"
    ${EXEC_NS2} ${FN_TCL} 1 "${PARAM_DN_TEST}" >> "${FN_LOG}" 2>&1
    if [ -f mediumpacket.out ]; then
        rm -f mediumpacket.out.gz
        gzip mediumpacket.out
    fi

    cd - 1>&2 > /dev/null
}

prepare_one_tcl_scripts () {
    # the prefix of the test
    PARAM_PREFIX=$1
    shift
    # the test type, "udp", "tcp", "has", "udp+has", "tcp+has"
    PARAM_TYPE=$1
    shift
    # the scheduler, such as "PF", "DRR"
    PARAM_SCHE=$1
    shift
    # the number of flows
    PARAM_NUM=$1
    shift
    PARAM_DN_TOP=$1
    shift
    PARAM_DN_COMM=$1
    shift
    PARAM_DN_TARGET=$1
    shift

    PARAM_DN_TEST=$(simulation_directory "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}")
    rm -rf   "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    mkdir -p "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"

    # Copy common scripts and data files from Common directory
    cp ${PARAM_DN_COMM}/cleanup.tcl     "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/sched-defs.tcl  "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/dash.tcl        "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/profile.tcl     "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/docsis-conf.${PARAM_SCHE,,}.tcl "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/docsis-conf.tcl"
    cp ${PARAM_DN_COMM}/docsis-util.tcl     "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/lossmon-util.tcl    "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/ping-util.tcl       "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/tcpudp-util.tcl     "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/networks.tcl        "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/flows-util.tcl      "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_TOP}/main.tcl         "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_TOP}/run-conf.tcl     "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/channels.dat    "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/BG.dat          "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/CMBGDS.dat      "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/CMBGUS.dat      "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    cp ${PARAM_DN_COMM}/getall.sh       "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"

    case $PARAM_TYPE in
    "udp")
        # setup the number of flows
        echo "setup udp ..." 1>&2
        sed -i \
            -e "s|set NUM_FTPs\s[0-9]*|set NUM_FTPs  0|" \
            -e "s|set NUM_UDPs\s[0-9]*|set NUM_UDPs  ${PARAM_NUM}|" \
            -e "s|set NUM_DASHs\s[0-9]*|set NUM_DASHs 0|" \
            -e "s|set NUM_WEBs\s[0-9]*|set NUM_WEBs  0|" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/run-conf.tcl"
        echo "setup udp done!" 1>&2
        ;;
    "tcp")
        sed -i \
            -e "s|set NUM_FTPs\s[0-9]*|set NUM_FTPs  ${PARAM_NUM}|" \
            -e "s|set NUM_UDPs\s[0-9]*|set NUM_UDPs  0|" \
            -e "s|set NUM_DASHs\s[0-9]*|set NUM_DASHs 0|" \
            -e "s|set NUM_WEBs\s[0-9]*|set NUM_WEBs  0|" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/run-conf.tcl"
        ;;
    "has")
        sed -i \
            -e "s|set NUM_FTPs\s[0-9]*|set NUM_FTPs  0|" \
            -e "s|set NUM_UDPs\s[0-9]*|set NUM_UDPs  0|" \
            -e "s|set NUM_DASHs\s[0-9]*|set NUM_DASHs ${PARAM_NUM}|" \
            -e "s|set NUM_WEBs\s[0-9]*|set NUM_WEBs  0|" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/run-conf.tcl"
        ;;
    "udp+has")
        sed -i \
            -e "s|set NUM_FTPs\s[0-9]*|set NUM_FTPs  0|" \
            -e "s|set NUM_UDPs\s[0-9]*|set NUM_UDPs  [expr ${PARAM_NUM} / 3]|" \
            -e "s|set NUM_DASHs\s[0-9]*|set NUM_DASHs [expr ${PARAM_NUM} - (${PARAM_NUM} / 3)]|" \
            -e "s|set NUM_WEBs\s[0-9]*|set NUM_WEBs  0|" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/run-conf.tcl"
        ;;
    "tcp+has")
        sed -i \
            -e "s|set NUM_FTPs\s[0-9]*|set NUM_FTPs  [expr ${PARAM_NUM} / 3]|" \
            -e "s|set NUM_UDPs\s[0-9]*|set NUM_UDPs  0|" \
            -e "s|set NUM_DASHs\s[0-9]*|set NUM_DASHs [expr ${PARAM_NUM} - (${PARAM_NUM} / 3)]|" \
            -e "s|set NUM_WEBs\s[0-9]*|set NUM_WEBs  0|" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/run-conf.tcl"
        ;;
    esac

    # setup the throughput log interval
    LOGINTERVAL=$(echo | awk -v V=$TIME_STOP '{print V / 100}' )
    if [ $(echo | awk -v V=$LOGINTERVAL '{if (V<0.5) print 1; else print 0;}') = 1 ] ; then
        LOGINTERVAL=0.5
    fi
    echo "LOGINTERVAL=$LOGINTERVAL" 1>&2

    # set stop time
    echo "setup stoptime, log interval ..." 1>&2
    sed -i \
        -e "s|set[ \t[:space:]]\+stoptime[ \t[:space:]]\+.*$|set stoptime ${TIME_STOP}|g" \
        -e 's|set[ \t[:space:]]\+TCPUDP_THROUGHPUT_MONITORS_ON[ \t[:space:]]\+.*$|set TCPUDP_THROUGHPUT_MONITORS_ON 1|g' \
        -e "s|set[ \t[:space:]]\+THROUGHPUT_MONITOR_INTERVAL[ \t[:space:]]\+.*$|set THROUGHPUT_MONITOR_INTERVAL ${LOGINTERVAL}|g" \
        -e "s|.*set[ \t[:space:]]\+BADGUY_UDP_FLOWS_START_TIME[ \t[:space:]]\+.*$|set BADGUY_UDP_FLOWS_START_TIME ${TIME_START}|g" \
        -e "s|.*set[ \t[:space:]]\+BADGUY_UDP_FLOWS_STOP_TIME[ \t[:space:]]\+.*$|set BADGUY_UDP_FLOWS_STOP_TIME  ${TIME_STOP}|g" \
        "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/run-conf.tcl"

    # set channel bandwidth
    echo "setup channel bandwidth ..." 1>&2
    sed -i \
        -e "s|42880000|${BW_CHANNEL}|g" \
        -e "s|1000000000|${BW_CHANNEL}|g" \
        "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/channels.dat"
    if (( ${BW_CHANNEL} > 42880000 )) ; then
        echo "setup high speed channel ..." 1>&2
        # fix the high speed problem
        sed -i \
            -e "s|\.00001|0.00000001|g" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/channels.dat"
        # goruns.dat for 2G channel: set CONCAT_THRESHOLD 50
        sed -i \
            -e "s|set[ \t[:space:]]\+CONCAT_THRESHOLD[ \t[:space:]]\+.*$|set CONCAT_THRESHOLD 150|g" \
            -e "s|set[ \t[:space:]]\+DOWNSTREAM_SID_QUEUE_SIZE[ \t[:space:]]\+.*$|set DOWNSTREAM_SID_QUEUE_SIZE 2048|g" \
            -e "s|set[ \t[:space:]]\+DOWNSTREAM_SERVICE_RATE[ \t[:space:]]\+.*$|set DOWNSTREAM_SERVICE_RATE 200000000|g" \
            -e "s|set[ \t[:space:]]\+UPSTREAM_SERVICE_RATE[ \t[:space:]]\+.*$|set UPSTREAM_SERVICE_RATE 10000000|g" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/docsis-conf.tcl"

        # set the bandwidth between nodes
        sed -i \
            -e "s|[ \t[:space:]]\+1000Mb[ \t[:space:]]\+| 10000Mb |g" \
            -e "s|[ \t[:space:]]\+24ms[ \t[:space:]]\+| 1ms |g" \
            -e "s|.*set[ \t[:space:]]\+WINDOW[ \t[:space:]]\+.*$|set WINDOW 65536|g" \
            -e "s|.*set[ \t[:space:]]\+DEFAULT_BUFFER_CAPACITY[ \t[:space:]]\+.*$|set DEFAULT_BUFFER_CAPACITY 32768|g" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/${FN_TCL}"
        sed -i \
            -e "s|^set[ \t[:space:]]\+WINDOW[ \t[:space:]]\+.*$|set WINDOW 65536|g" \
            -e "s|^set[ \t[:space:]]\+DEFAULT_BUFFER_CAPACITY[ \t[:space:]]\+.*$|set DEFAULT_BUFFER_CAPACITY 32768|g" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/run-conf.tcl"
    fi

    # set profile for channels
    echo "setup profile ..." 1>&2
    sed -i \
        -e "s|set curr_profile .*$|set curr_profile \$${NS2_PROFILE}|g" \
        "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"

    # init the profile
    if [ "${FLG_INIT_PROFILE_LOW}" = "1" ]; then
        echo "use init profile low ..." 1>&2
        sed -i \
            -e 's|proc init_profiles\s.*$|proc init_profiles {cm_node_start cm_node_count} { set_lower_profile $cm_node_start $cm_node_count }|' \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"
    fi
    if [ "${FLG_INIT_PROFILE_HIGH}" = "1" ]; then
        echo "use init profile high ..." 1>&2
        sed -i \
            -e 's|proc init_profiles\s.*$|proc init_profiles {cm_node_start cm_node_count} { set_high_profile $cm_node_start $cm_node_count }|' \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"
    fi
    if [ "${FLG_INIT_PROFILE_INTERVAL}" = "1" ]; then
        echo "use init profile interval ..." 1>&2
        sed -i \
            -e 's|proc init_profiles\s.*$|proc init_profiles {cm_node_start cm_node_count} { set_interval_profiles $cm_node_start $cm_node_count }|' \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"
    fi

    # change the profile in the middle of test
    if [ "${FLG_CHANGE_PROFILE_HIGH}" = "1" ]; then
        echo "use change profile high ..." 1>&2
        sed -i \
            -e "s|set[ \t[:space:]]\+CHANGE_PROFILE_HIGH[ \t[:space:]]\+.*$|set CHANGE_PROFILE_HIGH 1|g" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"
    fi
    if [ "${FLG_CHANGE_PROFILE_LOW}" = "1" ]; then
        echo "use change profile low ..." 1>&2
        sed -i \
            -e "s|set[ \t[:space:]]\+CHANGE_PROFILE_LOW[ \t[:space:]]\+.*$|set CHANGE_PROFILE_LOW 1|g" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"
    fi
}

# parse the parameters and generate the requests for ploting figures
prepare_figure_commands_for_one_stats () {
    PARAM_CONFIG_FILE="$1"
    shift
    # the prefix of the test
    PARAM_PREFIX=$1
    shift
    # the test type, "udp", "tcp", "has", "udp+has", "tcp+has"
    PARAM_TYPE=$1
    shift
    # the scheduler, such as "PF", "DRR"
    PARAM_SCHE=$1
    shift
    # the number of flows
    PARAM_NUM=$1
    shift

    #${DN_PARENT}/plotfigns2.sh tpflow "${DN_TOP}/results/" "${DN_TOP}/figures/" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"

    case $PARAM_TYPE in
    "udp")
        echo "packet any \"${PARAM_CONFIG_FILE}\"" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        echo "throughput udp \"${PARAM_CONFIG_FILE}\"" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        ;;
    "tcp")
        echo "packet any \"${PARAM_CONFIG_FILE}\"" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        echo "throughput tcp \"${PARAM_CONFIG_FILE}\"" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        ;;
    "has")
        echo "packet any \"${PARAM_CONFIG_FILE}\"" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        echo "throughput tcp \"${PARAM_CONFIG_FILE}\"" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        ;;
    "udp+has")
        echo "packet any \"${PARAM_CONFIG_FILE}\"" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        echo "throughput udp \"${PARAM_CONFIG_FILE}\"" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        echo "throughput tcp \"${PARAM_CONFIG_FILE}\"" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        ;;
    "tcp+has")
        echo "packet any \"${PARAM_CONFIG_FILE}\"" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        echo "throughput tcp \"${PARAM_CONFIG_FILE}\"" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        ;;
    esac
}
