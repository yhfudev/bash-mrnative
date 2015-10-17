#!/bin/bash
#
# the entry for all of simulations
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

EXEC_NS2="$(my_getpath "${DN_EXEC}/../../ns")"

DN_COMM="$(my_getpath "${DN_EXEC}/common")"
DN_TOP="${DN_EXEC}"
source ${DN_COMM}/libbash.sh
source ${DN_COMM}/libshrt.sh
source ${DN_COMM}/libns2utils.sh

DN_PARENT="$(my_getpath ".")"
FN_TCL=main.tcl

source ${DN_PARENT}/config.sh

check_global_config

#echo "HDFF_NUM_CLONE=$HDFF_NUM_CLONE"; exit 1 # debug

#####################################################################

worker_prepare_one_simulation () {
    PARAM_SESSION_ID="$1"
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

    [ "${PARAM_PREFIX}" = "" ] && (echo "Error in prefix: ${PARAM_PREFIX}" && exit 1)
    [ "${PARAM_TYPE}" = "" ] && (echo "Error in type: ${PARAM_TYPE}" && exit 1)
    [ "${PARAM_SCHE}" = "" ] && (echo "Error in scheduler: ${PARAM_SCHE}" && exit 1)
    [ "${PARAM_NUM}" = "" ] && (echo "Error in number: ${PARAM_NUM}"; exit 1)

    #DN_TEST="${PARAM_PREFIX}_${PARAM_TYPE}_${PARAM_SCHE}_${PARAM_NUM}"
    DN_TEST=$(simulation_directory "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}")

    echo "run ${DN_TEST} ..." >> "${FN_LOG}"
    rm -rf   "${DN_TEST}/"
    mkdir -p "${DN_TEST}/"

    # Copy common scripts and data files from Common directory
    cp ${DN_COMM}/cleanup.tcl       "${DN_TEST}/"
    cp ${DN_COMM}/sched-defs.tcl    "${DN_TEST}/"
    cp ${DN_COMM}/dash.tcl          "${DN_TEST}/"
    cp ${DN_COMM}/profile.tcl       "${DN_TEST}/"
    cp ${DN_COMM}/docsis-conf.${PARAM_SCHE,,}.tcl "${DN_TEST}/docsis-conf.tcl"
    cp ${DN_COMM}/docsis-util.tcl   "${DN_TEST}/"
    cp ${DN_COMM}/lossmon-util.tcl  "${DN_TEST}/"
    cp ${DN_COMM}/ping-util.tcl     "${DN_TEST}/"
    cp ${DN_COMM}/tcpudp-util.tcl   "${DN_TEST}/"
    cp ${DN_COMM}/networks.tcl      "${DN_TEST}/"
    cp ${DN_COMM}/flows-util.tcl    "${DN_TEST}/"
    cp ${DN_TOP}/main.tcl        "${DN_TEST}/"
    cp ${DN_TOP}/run-conf.tcl    "${DN_TEST}/"
    cp ${DN_COMM}/channels.dat  "${DN_TEST}/"
    cp ${DN_COMM}/BG.dat        "${DN_TEST}/"
    cp ${DN_COMM}/CMBGDS.dat    "${DN_TEST}/"
    cp ${DN_COMM}/CMBGUS.dat    "${DN_TEST}/"
    cp ${DN_COMM}/getall.sh     "${DN_TEST}/"
    #mkdir -p  "${DN_TEST}/scripts"
    #cp ${DN_COMM}/scripts/*  "${DN_TEST}/scripts/"

    case $PARAM_TYPE in
    "udp")
        # setup the number of flows
        echo "setup udp ..."
        sed -i \
            -e "s|set NUM_FTPs\s[0-9]*|set NUM_FTPs  0|" \
            -e "s|set NUM_UDPs\s[0-9]*|set NUM_UDPs  ${PARAM_NUM}|" \
            -e "s|set NUM_DASHs\s[0-9]*|set NUM_DASHs 0|" \
            -e "s|set NUM_WEBs\s[0-9]*|set NUM_WEBs  0|" \
            "${DN_TEST}/run-conf.tcl"
        echo "setup udp done!"
        ;;
    "tcp")
        sed -i \
            -e "s|set NUM_FTPs\s[0-9]*|set NUM_FTPs  ${PARAM_NUM}|" \
            -e "s|set NUM_UDPs\s[0-9]*|set NUM_UDPs  0|" \
            -e "s|set NUM_DASHs\s[0-9]*|set NUM_DASHs 0|" \
            -e "s|set NUM_WEBs\s[0-9]*|set NUM_WEBs  0|" \
            "${DN_TEST}/run-conf.tcl"
        ;;
    "has")
        sed -i \
            -e "s|set NUM_FTPs\s[0-9]*|set NUM_FTPs  0|" \
            -e "s|set NUM_UDPs\s[0-9]*|set NUM_UDPs  0|" \
            -e "s|set NUM_DASHs\s[0-9]*|set NUM_DASHs ${PARAM_NUM}|" \
            -e "s|set NUM_WEBs\s[0-9]*|set NUM_WEBs  0|" \
            "${DN_TEST}/run-conf.tcl"
        ;;
    "udp+has")
        sed -i \
            -e "s|set NUM_FTPs\s[0-9]*|set NUM_FTPs  0|" \
            -e "s|set NUM_UDPs\s[0-9]*|set NUM_UDPs  [expr ${PARAM_NUM} / 3]|" \
            -e "s|set NUM_DASHs\s[0-9]*|set NUM_DASHs [expr ${PARAM_NUM} - (${PARAM_NUM} / 3)]|" \
            -e "s|set NUM_WEBs\s[0-9]*|set NUM_WEBs  0|" \
            "${DN_TEST}/run-conf.tcl"
        ;;
    "tcp+has")
        sed -i \
            -e "s|set NUM_FTPs\s[0-9]*|set NUM_FTPs  [expr ${PARAM_NUM} / 3]|" \
            -e "s|set NUM_UDPs\s[0-9]*|set NUM_UDPs  0|" \
            -e "s|set NUM_DASHs\s[0-9]*|set NUM_DASHs [expr ${PARAM_NUM} - (${PARAM_NUM} / 3)]|" \
            -e "s|set NUM_WEBs\s[0-9]*|set NUM_WEBs  0|" \
            "${DN_TEST}/run-conf.tcl"
        ;;
    esac

    # setup the throughput log interval
    LOGINTERVAL=$(echo | awk -v V=$TIME_STOP '{print V / 100}' )
    if [ $(echo | awk -v V=$LOGINTERVAL '{if (V<0.5) print 1; else print 0;}') = 1 ] ; then
        LOGINTERVAL=0.5
    fi
    echo "LOGINTERVAL=$LOGINTERVAL"

    # set stop time
    echo "setup stoptime, log interval ..."
    sed -i \
        -e "s|set[ \t[:space:]]\+stoptime[ \t[:space:]]\+.*$|set stoptime ${TIME_STOP}|g" \
        -e 's|set[ \t[:space:]]\+TCPUDP_THROUGHPUT_MONITORS_ON[ \t[:space:]]\+.*$|set TCPUDP_THROUGHPUT_MONITORS_ON 1|g' \
        -e "s|set[ \t[:space:]]\+THROUGHPUT_MONITOR_INTERVAL[ \t[:space:]]\+.*$|set THROUGHPUT_MONITOR_INTERVAL ${LOGINTERVAL}|g" \
        -e "s|.*set[ \t[:space:]]\+BADGUY_UDP_FLOWS_START_TIME[ \t[:space:]]\+.*$|set BADGUY_UDP_FLOWS_START_TIME ${TIME_START}|g" \
        -e "s|.*set[ \t[:space:]]\+BADGUY_UDP_FLOWS_STOP_TIME[ \t[:space:]]\+.*$|set BADGUY_UDP_FLOWS_STOP_TIME  ${TIME_STOP}|g" \
        "${DN_TEST}/run-conf.tcl"

    # set channel bandwidth
    echo "setup channel bandwidth ..."
    sed -i \
        -e "s|42880000|${BW_CHANNEL}|g" \
        -e "s|1000000000|${BW_CHANNEL}|g" \
        "${DN_TEST}/channels.dat"
    if (( ${BW_CHANNEL} > 42880000 )) ; then
        echo "setup high speed channel ..."
        # fix the high speed problem
        sed -i \
            -e "s|\.00001|0.00000001|g" \
            "${DN_TEST}/channels.dat"
        # goruns.dat for 2G channel: set CONCAT_THRESHOLD 50
        sed -i \
            -e "s|set[ \t[:space:]]\+CONCAT_THRESHOLD[ \t[:space:]]\+.*$|set CONCAT_THRESHOLD 150|g" \
            -e "s|set[ \t[:space:]]\+DOWNSTREAM_SID_QUEUE_SIZE[ \t[:space:]]\+.*$|set DOWNSTREAM_SID_QUEUE_SIZE 2048|g" \
            -e "s|set[ \t[:space:]]\+DOWNSTREAM_SERVICE_RATE[ \t[:space:]]\+.*$|set DOWNSTREAM_SERVICE_RATE 200000000|g" \
            -e "s|set[ \t[:space:]]\+UPSTREAM_SERVICE_RATE[ \t[:space:]]\+.*$|set UPSTREAM_SERVICE_RATE 10000000|g" \
            "${DN_TEST}/docsis-conf.tcl"

        # set the bandwidth between nodes
        sed -i \
            -e "s|[ \t[:space:]]\+1000Mb[ \t[:space:]]\+| 10000Mb |g" \
            -e "s|[ \t[:space:]]\+24ms[ \t[:space:]]\+| 1ms |g" \
            -e "s|.*set[ \t[:space:]]\+WINDOW[ \t[:space:]]\+.*$|set WINDOW 65536|g" \
            -e "s|.*set[ \t[:space:]]\+DEFAULT_BUFFER_CAPACITY[ \t[:space:]]\+.*$|set DEFAULT_BUFFER_CAPACITY 32768|g" \
            "${DN_TEST}/${FN_TCL}"
        sed -i \
            -e "s|^set[ \t[:space:]]\+WINDOW[ \t[:space:]]\+.*$|set WINDOW 65536|g" \
            -e "s|^set[ \t[:space:]]\+DEFAULT_BUFFER_CAPACITY[ \t[:space:]]\+.*$|set DEFAULT_BUFFER_CAPACITY 32768|g" \
            "${DN_TEST}/run-conf.tcl"
    fi

    # set profile for channels
    echo "setup profile ..."
    sed -i \
        -e "s|set curr_profile .*$|set curr_profile \$${NS2_PROFILE}|g" \
        "${DN_TEST}/profile.tcl"

    # init the profile
    if [ "${FLG_INIT_PROFILE_LOW}" = "1" ]; then
        echo "use init profile low ..."
        sed -i \
            -e 's|proc init_profiles\s.*$|proc init_profiles {cm_node_start cm_node_count} { set_lower_profile $cm_node_start $cm_node_count }|' \
            "${DN_TEST}/profile.tcl"
    fi
    if [ "${FLG_INIT_PROFILE_HIGH}" = "1" ]; then
        echo "use init profile high ..."
        sed -i \
            -e 's|proc init_profiles\s.*$|proc init_profiles {cm_node_start cm_node_count} { set_high_profile $cm_node_start $cm_node_count }|' \
            "${DN_TEST}/profile.tcl"
    fi
    if [ "${FLG_INIT_PROFILE_INTERVAL}" = "1" ]; then
        echo "use init profile interval ..."
        sed -i \
            -e 's|proc init_profiles\s.*$|proc init_profiles {cm_node_start cm_node_count} { set_interval_profiles $cm_node_start $cm_node_count }|' \
            "${DN_TEST}/profile.tcl"
    fi

    # change the profile in the middle of test
    if [ "${FLG_CHANGE_PROFILE_HIGH}" = "1" ]; then
        echo "use change profile high ..."
        sed -i \
            -e "s|set[ \t[:space:]]\+CHANGE_PROFILE_HIGH[ \t[:space:]]\+.*$|set CHANGE_PROFILE_HIGH 1|g" \
            "${DN_TEST}/profile.tcl"
    fi
    if [ "${FLG_CHANGE_PROFILE_LOW}" = "1" ]; then
        echo "use change profile low ..."
        sed -i \
            -e "s|set[ \t[:space:]]\+CHANGE_PROFILE_LOW[ \t[:space:]]\+.*$|set CHANGE_PROFILE_LOW 1|g" \
            "${DN_TEST}/profile.tcl"
    fi

    cd       "${DN_TEST}/"
    rm -f *.bin *.txt *.out out.* *.tr *.log tmp*
    echo ${EXEC_NS2} ${FN_TCL} 1 "${DN_TEST}" FILTER grep PFSCHE TO "${FN_LOG}" >> "${FN_LOG}"
    #${EXEC_NS2} ${FN_TCL} 1 "${DN_TEST}" 2>&1 | grep PFSCHE >> "${FN_LOG}"
    ${EXEC_NS2} ${FN_TCL} 1 "${DN_TEST}" >> "${FN_LOG}" 2>&1
    if [ -f mediumpacket.out ]; then
        rm -f mediumpacket.out.gz
        gzip mediumpacket.out
    fi

    cd - > /dev/null
    echo "$(date) DONE: ${DN_TEST}" >> "${FN_LOG}"

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

echo ""
echo ""
echo "$MSG_TITLE"
echo "=========="
echo "$MSG_DESCRIPTION"
echo "----------"
echo "Running ..."

echo "" > "${FN_LOG}"

echo "$MSG_TITLE" >> "${FN_LOG}"
echo "==========" >> "${FN_LOG}"
echo "$MSG_DESCRIPTION" >> "${FN_LOG}"
echo "----------" >> "${FN_LOG}"
date >> "${FN_LOG}"
echo "Running ..." >> "${FN_LOG}"

make -C ../../..

FN_ASSIGN=$1

# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

for idx_num in ${list_nodes_num[*]} ; do
    for idx_type in ${list_types[*]} ; do
        for idx_sche in ${list_schedules[*]} ; do
            if [ ! "${FN_ASSIGN}" = "" ]; then
                # if the assigment file exit, then check if current test is in the list in the file
                DN_TEST=$(simulation_directory "${PREFIX}" "$idx_type" "$idx_sche" "$idx_num")
                grep "${DN_TEST}" "${FN_ASSIGN}"
                if [ ! "$?" = "0" ] ; then
                    echo "not found ${DN_TEST} in file: ${FN_ASSIGN}, skiping ..."
                    continue
                fi
            fi
            #prepare_one_simulation "${PREFIX}" "${list_types[$idx_type]}" "${list_schedules[$idx_sche]}" "${list_nodes_num[$idx_num]}" &
            worker_prepare_one_simulation "$(mp_get_session_id)" "${PREFIX}" "$idx_type" "$idx_sche" "$idx_num" &
            PID_CHILD=$!
            mp_add_child_check_wait ${PID_CHILD}
        done
    done
done

mp_wait_all_children
echo "$(date) DONE: ALL" >> "${FN_LOG}"
