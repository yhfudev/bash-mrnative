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
    PARAM_FN_CONFIG_PROJ=$1
    shift

    # read in the config file for this test group
    # in this case, is to read the config for USE_MEDIUMPACKET
    if [ ! -f "${PARAM_FN_CONFIG_PROJ}" ]; then
        echo "$(basename $0) Error: not found file: $PARAM_FN_CONFIG_PROJ" 1>&2
        return
    fi
    PARAM_FN_CONFIG_PROJ2="$(my_getpath "${PARAM_FN_CONFIG_PROJ}")"
    read_config_file "${PARAM_FN_CONFIG_PROJ2}"

    cd       "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/"
    rm -f *.bin *.txt *.out out.* *.tr *.log tmp*
    echo ${EXEC_NS2} ${FN_TCL} 1 "${PARAM_DN_TEST}" FILTER grep PFSCHE TO "${FN_LOG}" 1>&2
    if [ ! -x "${EXEC_NS2}" ]; then
        echo "$(basename $0) Error: not correctly set ns2 env EXEC_NS2=${EXEC_NS2}, which ns=$(which ns)" 1>&2
    else
        #${EXEC_NS2} ${FN_TCL} 1 "${PARAM_DN_TEST}" 2>&1 | grep PFSCHE >> "${FN_LOG}"
        ${EXEC_NS2} ${FN_TCL} 1 "${PARAM_DN_TEST}" >> "${FN_LOG}" 2>&1
    fi

    echo "$(basename $0) [DBG] USE_MEDIUMPACKET='${USE_MEDIUMPACKET}'" 1>&2
    if [ "${USE_MEDIUMPACKET}" = "1" ]; then
        if [ -f mediumpacket.out ]; then
            echo "$(basename $0) [DBG] compressing mediumpacket.out ..." 1>&2
            rm -f mediumpacket.out.gz
            gzip mediumpacket.out
        else
            echo "$(basename $0) Warning: not found mediumpacket.out." 1>&2
        fi
    else
        echo "$(basename $0) Warning: remove mediumpacket.out*!" 1>&2
        rm -f mediumpacket.out*
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
    # set the UDP throughput to the maximum available bw; 6 is the QAM
    sed -i \
        -e "s|^set[ \t[:space:]]\+MAXCHANNELBW[ \t[:space:]]\+.*$|set MAXCHANNELBW [expr ${BW_CHANNEL} * 6]|g" \
        "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/${FN_TCL}"

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

    rm -f "${DN_TEST}/mediumpacket.out*"
    if [ ! "${USE_MEDIUMPACKET}" = "1" ]; then
        ln -s /dev/null "${DN_TEST}/mediumpacket.out"
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

    #${DN_PARENT}/plotfigns2.sh tpflow "${HDFF_DN_OUTPUT}/dataconf/" "${HDFF_DN_OUTPUT}/figures/" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"

    case $PARAM_TYPE in
    "udp")
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"udp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    "tcp")
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    "has")
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    "udp+has")
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"udp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    "tcp+has")
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    esac
}

# clean temperary files with file name prefix "tmp-"
clean_one_tcldir () {
    # the prefix of the test
    PARAM_DN_DEST=$1
    shift

    FLG_ERR=1
    if [ -d "${PARAM_DN_DEST}" ]; then
        FLG_ERR=0
        FLG_NONE=1
        cd       "${DN_TEST}"
        find . -maxdepth 1 -type f -name "tmp-*" | xargs -n 10 rm -f
        cd - > /dev/null
    fi

    if [ "${FLG_ERR}" = "1" ]; then
        #echo "save ${PARAM_FN_LOG_ERROR}: ${DN_TEST}" >> "/dev/stderr"
        echo "${DN_TEST}" >> "${PARAM_FN_LOG_ERROR}"
    fi
}

# check the throughput log file, if the log time reach to the pre-set end time.
# checked both for UDP and TCP packets, with file prefix CMTCPDS and CMUDPDS
check_one_tcldir () {
    PARAM_DN_DEST=$1
    shift
    # output file save the failed directories
    PARAM_FN_LOG_ERROR=$1
    shift

    FLG_ERR=1
    if [ -d "${PARAM_DN_DEST}" ]; then
        FLG_ERR=0
        FLG_NONE=1
        cd       "${PARAM_DN_DEST}"
        FN_TPFLOW="CMTCPDS*.out"
        LST=$(find . -maxdepth 1 -type f -name "${FN_TPFLOW}" | awk -F/ '{print $2}' | sort)
        for i in $LST ; do
            FLG_NONE=0
            echo "process flow throughput (tcp) $i ..."
            idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
            #echo "curr dir=$(pwd), tail i=$i" >> /dev/stderr
            TM1=$(tail -n 1 "$i" | awk '{print $1}')
            if [ $(echo | awk -v A=$TM1 -v B=$TIME_STOP '{if (A + 5 < B) print 1; else print 0;}') = 1 ] ; then
                FLG_ERR=1
            fi
        done
        FN_TPFLOW="CMUDPDS*.out"
        LST=$(find . -maxdepth 1 -type f -name "${FN_TPFLOW}" | awk -F/ '{print $2}' | sort)
        for i in $LST ; do
            FLG_NONE=0
            echo "process flow throughput (tcp) $i ..."
            idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
            TM1=$(tail -n 1 "$i" | awk '{print $1}')
            if [ $(echo | awk -v A=$TM1 -v B=$TIME_STOP '{if (A + 5 < B) print 1; else print 0;}') = 1 ] ; then
                FLG_ERR=1
            fi
        done
        if [ "$FLG_NONE" = "1" ]; then
            FLG_ERR=1
        fi
        cd - > /dev/null
    fi

    if [ "${FLG_ERR}" = "1" ]; then
        #echo "save ${PARAM_FN_LOG_ERROR}: ${PARAM_DN_DEST}" >> "/dev/stderr"
        echo "${PARAM_DN_DEST}" >> "${PARAM_FN_LOG_ERROR}"
    fi
}

if [ ! -f "${DN_TOP}/config-sys.sh" ]; then
  generate_default_config > "${DN_TOP}/config-sys.sh"
fi
read_config_file "${DN_TOP}/config-sys.sh"
check_global_config
