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
  DNORIG=$(pwd)
  cd "${DN}" > /dev/null 2>&1
  DN=$(pwd)
  cd "${DNORIG}"
  if [ "${FN}" = "" ]; then
    echo "${DN}"
  else
    echo "${DN}/${FN}"
  fi
}
DN_EXEC=$(dirname $(my_getpath "$0") )
#####################################################################

FN_TCL=main.tcl

#HDFF_DN_SCRATCH="/dev/shm/$USER/"

# PARAM_DN_PARENT -- the parent dir for the data to be saved.
# PARAM_DN_TEST   -- the sub dir for the data, related dir name to PARAM_DN_PARENT
# PARAM_FN_CONFIG_PROJ -- the config file for this simulation
run_one_ns2 () {
    local PARAM_DN_PARENT=$1
    shift
    local PARAM_DN_TEST=$1
    shift
    local PARAM_FN_CONFIG_PROJ=$1
    shift

    # read in the config file for this test group
    # in this case, is to read the config for USE_MEDIUMPACKET
    local FN_TMP="/dev/shm/config-$(uuidgen)"
    copy_file "${PARAM_FN_CONFIG_PROJ}" "${FN_TMP}" > /dev/null 2>&1
    read_config_file "${FN_TMP}"
    rm_f_dir "${FN_TMP}" > /dev/null 2>&1

    # set the scratch dir, which is used to store temperary files.
    local RET=0

    local DN_WORKING="${PARAM_DN_PARENT}/${PARAM_DN_TEST}/"
    local FLG_USETMP=0
    RET=$(is_local "${PARAM_DN_PARENT}")
    if [ ! "${RET}" = "l" ]; then
        FLG_USETMP=1
    fi
    if [ ! "${HDFF_DN_SCRATCH}" = "" ]; then
        FLG_USETMP=1
    fi
    DN_ORIG2=$(pwd)
    if [ ! "${FLG_USETMP}" = "0" ]; then
        RET=$(is_local "${HDFF_DN_SCRATCH}")
        if [ ! "${RET}" = "l" ]; then
            mr_trace "Error in prepare the scratch dir: ${HDFF_DN_SCRATCH}"
            return
        fi

        DN_WORKING="${HDFF_DN_SCRATCH}/run-${PARAM_DN_TEST}-$(uuidgen)/"
        mkdir -p "${DN_WORKING}"
        mr_trace "run ns2: copy from parent to working dir: ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/ --> ${DN_WORKING}/"
        #rsync -av --log-file "${PARAM_DN_PARENT}/rsync-log-runns2-copytemp-1.log" "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" "${DN_WORKING}/" 1>&2
        find_file "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" -name "*.tcl" | while read a; do copy_file "$a" "${DN_WORKING}/" > /dev/null 2>&1; done
        find_file "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" -name "*.dat" | while read a; do copy_file "$a" "${DN_WORKING}/" > /dev/null 2>&1; done
        find_file "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" -name "*.sh" | while read a; do copy_file "$a" "${DN_WORKING}/" > /dev/null 2>&1; done
        RET=$?
        if [ ! "$RET" = "0" ]; then
            mr_trace "Error: copy temp dir: $PARAM_DN_TEST to ${DN_WORKING}/"
            return
        fi
        cd "${DN_WORKING}"
    else
        cd "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/"
    fi
    mr_trace "rm -f *.bin *.txt *.out out.* *.tr *.log tmp*"
    rm -f *.bin *.txt *.out out.* *.tr *.log tmp*
    mr_trace ${EXEC_NS2} ${FN_TCL} 1 "${PARAM_DN_TEST}" FILTER grep PFSCHE TO "${HDFF_FN_LOG}"
    if [ ! -x "${EXEC_NS2}" ]; then
        mr_trace "Error: not correctly set ns2 env EXEC_NS2=${EXEC_NS2}, which ns=$(which ns)"
    else
        #${EXEC_NS2} ${FN_TCL} 1 "${PARAM_DN_TEST}" 2>&1 | grep PFSCHE >> "${HDFF_FN_LOG}"
        ${EXEC_NS2} ${FN_TCL} 1 "${PARAM_DN_TEST}" >> "${HDFF_FN_LOG}" 2>&1
    fi

    mr_trace "USE_MEDIUMPACKET='${USE_MEDIUMPACKET}'"
    if [ "${USE_MEDIUMPACKET}" = "1" ]; then
        if [ -f mediumpacket.out ]; then
            mr_trace "rm -f mediumpacket.out.gz ..."
            rm -f mediumpacket.out.gz
            mr_trace "compressing mediumpacket.out ..."
            gzip mediumpacket.out
        else
            mr_trace "Warning: not found mediumpacket.out."
        fi
    else
        mr_trace "Warning: remove mediumpacket.out*!"
        rm -f mediumpacket.out*
    fi

    cd "${DN_ORIG2}"
    if [ ! "${FLG_USETMP}" = "0" ]; then
        mr_trace "run ns2: copy back from working to parent dir: ${DN_WORKING}/ --> ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/"
        #rsync -av  --log-file "${PARAM_DN_PARENT}/rsync-log-runns2-copyback-1-${PARAM_DN_TEST}.log" "${DN_WORKING}/" "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" 1>&2
        RET=$(copy_file "${DN_WORKING}/" "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/")
        if [ ! "$RET" = "0" ]; then
            mr_trace "Error: copy temp dir: ${DN_WORKING} to $PARAM_DN_TEST"
            return
        fi
        mr_trace "remove working dir: rm -f ${DN_WORKING} ..."
        #rm -rf "${DN_WORKING}"
    fi
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

    RET=$(is_local "${PARAM_DN_TARGET}")
    if [ ! "${RET}" = "l" ]; then
        mr_trace "Error: The target dir should be in a local disk!"
        return
    fi

    PARAM_DN_TEST=$(simulation_directory "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}")
    mr_trace "generate folder: ${PARAM_DN_TARGET}/${PARAM_DN_TEST}/ ..."
    mr_trace "remove trash first: rm -rf ${PARAM_DN_TARGET}/${PARAM_DN_TEST}/ ..."
    rm -rf   "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
    mr_trace "mkdir -p ${PARAM_DN_TARGET}/${PARAM_DN_TEST}/ ..."
    mkdir -p "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"

    mr_trace "Copy common scripts and data files to ${PARAM_DN_TARGET}/${PARAM_DN_TEST}/ ..."
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

    mr_trace "modify the settings in ${PARAM_DN_TARGET}/${PARAM_DN_TEST}/ ..."
    case $PARAM_TYPE in
    "udp")
        # setup the number of flows
        mr_trace "setup udp ..."
        sed -i \
            -e "s|set NUM_FTPs\s[0-9]*|set NUM_FTPs  0|" \
            -e "s|set NUM_UDPs\s[0-9]*|set NUM_UDPs  ${PARAM_NUM}|" \
            -e "s|set NUM_DASHs\s[0-9]*|set NUM_DASHs 0|" \
            -e "s|set NUM_WEBs\s[0-9]*|set NUM_WEBs  0|" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/run-conf.tcl"
        mr_trace "setup udp done!"
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
    mr_trace "LOGINTERVAL=$LOGINTERVAL"

    # set stop time
    mr_trace "setup stoptime, log interval ..."
    sed -i \
        -e "s|set[ \t[:space:]]\+stoptime[ \t[:space:]]\+.*$|set stoptime ${TIME_STOP}|g" \
        -e 's|set[ \t[:space:]]\+TCPUDP_THROUGHPUT_MONITORS_ON[ \t[:space:]]\+.*$|set TCPUDP_THROUGHPUT_MONITORS_ON 1|g' \
        -e "s|set[ \t[:space:]]\+THROUGHPUT_MONITOR_INTERVAL[ \t[:space:]]\+.*$|set THROUGHPUT_MONITOR_INTERVAL ${LOGINTERVAL}|g" \
        -e "s|.*set[ \t[:space:]]\+BADGUY_UDP_FLOWS_START_TIME[ \t[:space:]]\+.*$|set BADGUY_UDP_FLOWS_START_TIME ${TIME_START}|g" \
        -e "s|.*set[ \t[:space:]]\+BADGUY_UDP_FLOWS_STOP_TIME[ \t[:space:]]\+.*$|set BADGUY_UDP_FLOWS_STOP_TIME  ${TIME_STOP}|g" \
        "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/run-conf.tcl"

    # set channel bandwidth
    mr_trace "setup channel bandwidth ..."
    sed -i \
        -e "s|42880000|${BW_CHANNEL}|g" \
        -e "s|1000000000|${BW_CHANNEL}|g" \
        "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/channels.dat"
    if (( ${BW_CHANNEL} > 42880000 )) ; then
        mr_trace "setup high speed channel ..."
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
    mr_trace "setup profile ..."
    sed -i \
        -e "s|set curr_profile .*$|set curr_profile \$${NS2_PROFILE}|g" \
        "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"

    # init the profile
    if [ "${FLG_INIT_PROFILE_LOW}" = "1" ]; then
        mr_trace "use init profile low ..."
        sed -i \
            -e 's|proc init_profiles\s.*$|proc init_profiles {cm_node_start cm_node_count} { set_lower_profile $cm_node_start $cm_node_count }|' \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"
    fi
    if [ "${FLG_INIT_PROFILE_HIGH}" = "1" ]; then
        mr_trace "use init profile high ..."
        sed -i \
            -e 's|proc init_profiles\s.*$|proc init_profiles {cm_node_start cm_node_count} { set_high_profile $cm_node_start $cm_node_count }|' \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"
    fi
    if [ "${FLG_INIT_PROFILE_INTERVAL}" = "1" ]; then
        mr_trace "use init profile interval ..."
        sed -i \
            -e 's|proc init_profiles\s.*$|proc init_profiles {cm_node_start cm_node_count} { set_interval_profiles $cm_node_start $cm_node_count }|' \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"
    fi

    # change the profile in the middle of test
    if [ "${FLG_CHANGE_PROFILE_HIGH}" = "1" ]; then
        mr_trace "use change profile high ..."
        sed -i \
            -e "s|set[ \t[:space:]]\+CHANGE_PROFILE_HIGH[ \t[:space:]]\+.*$|set CHANGE_PROFILE_HIGH 1|g" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"
    fi
    if [ "${FLG_CHANGE_PROFILE_LOW}" = "1" ]; then
        mr_trace "use change profile low ..."
        sed -i \
            -e "s|set[ \t[:space:]]\+CHANGE_PROFILE_LOW[ \t[:space:]]\+.*$|set CHANGE_PROFILE_LOW 1|g" \
            "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/profile.tcl"
    fi

    mr_trace "rm -f ${PARAM_DN_TARGET}/${PARAM_DN_TEST}/mediumpacket.out*"
    rm -f "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/mediumpacket.out*"
    if [ ! "${USE_MEDIUMPACKET}" = "1" ]; then
        ln -s /dev/null "${PARAM_DN_TARGET}/${PARAM_DN_TEST}/mediumpacket.out"
    fi
    mr_trace "TCL script done: ${PARAM_DN_TARGET}/${PARAM_DN_TEST}/"
}

# generate the TCL scripts for all of the settings
# my_getpath, DN_EXEC, DN_COMM, HDFF_DN_OUTPUT, should be defined before call this function
# HDFF_DN_SCRATCH should be in global config file (config-sys.sh)
# PREFIX, LIST_NODE_NUM, LIST_TYPES, LIST_SCHEDULERS should be in the config file passed by argument
prepare_all_tcl_scripts () {
    PARAM_COMMAND=$1
    shift
    PARAM_FN_CONFIG_PROJ=$1
    shift

    local FN_TMP="/dev/shm/config-$(uuidgen)"
    copy_file "${PARAM_FN_CONFIG_PROJ}" "${FN_TMP}" > /dev/null 2>&1
    read_config_file "${FN_TMP}"
    rm_f_dir "${FN_TMP}" > /dev/null 2>&1

mr_trace "prepare_all_tcl_scripts, HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"

    DN_TMP_CREATECONF="${HDFF_DN_SCRATCH}/tmp-createconf-$(uuidgen)"
    mr_trace "remove tmp trash first: rm -rf ${DN_TMP_CREATECONF}"
    rm_f_dir"${DN_TMP_CREATECONF}"
    mr_trace "mkdir -p ${DN_TMP_CREATECONF}"
    make_dir "${DN_TMP_CREATECONF}"
    mr_trace "LIST_NODE_NUM='${LIST_NODE_NUM}'"
    mr_trace "LIST_TYPES='${LIST_TYPES}'"
    mr_trace "LIST_SCHEDULERS='${LIST_SCHEDULERS}'"
    for idx_num9 in $LIST_NODE_NUM ; do
        for idx_type9 in $LIST_TYPES ; do
            for idx_sche9 in $LIST_SCHEDULERS ; do
                mr_trace "prefix='${PREFIX}', type='$idx_type9', sche='$idx_sche9', num='$idx_num9', exec='${DN_EXEC}', comm='${DN_COMM}', tmp='${DN_TMP_CREATECONF}'"
                case "${PARAM_COMMAND}" in
                sim)
                    prepare_one_tcl_scripts "${PREFIX}" "$idx_type9" "$idx_sche9" "$idx_num9" "${DN_EXEC}" "${DN_COMM}" "${DN_TMP_CREATECONF}"
                    ;;
                esac
                echo -e "${PARAM_COMMAND}\t\"${PARAM_FN_CONFIG_PROJ}\"\t\"${PREFIX}\"\t\"${idx_type9}\"\tunknown\t\"${idx_sche9}\"\t${idx_num9}"
            done
        done
    done
    make_dir "${HDFF_DN_OUTPUT}/dataconf/"

    #DN_ORIG15=$(pwd)
    #cd "${DN_TMP_CREATECONF}"
    #tar -cf - * | tar -C "${HDFF_DN_OUTPUT}/dataconf/" -xf -
    #cd "${DN_ORIG15}"

    case "${PARAM_COMMAND}" in
    sim)
        mr_trace "create conf: rsync from temp to result dir: ${DN_TMP_CREATECONF}/ --> ${HDFF_DN_OUTPUT}/dataconf/"
        #rsync -av --log-file "${HDFF_DN_OUTPUT}/rsync-log-createconf-copyback-1-${PREFIX}.log" "${DN_TMP_CREATECONF}/" "${HDFF_DN_OUTPUT}/dataconf/" 1>&2
        RET=$(copy_file "${DN_TMP_CREATECONF}/" "${HDFF_DN_OUTPUT}/dataconf/")
        #rm_f_dir "${DN_TMP_CREATECONF}/"*
        if [ ! "$RET" = "0" ]; then
            mr_trace "Error: copy temp dir: ${DN_TMP_CREATECONF}/ to ${HDFF_DN_OUTPUT}/dataconf/"
            exit 1
        fi
        ;;
    esac

    #rm -rf "${DN_TMP_CREATECONF}"

    mr_trace "DONE create config files"
exit 1 # debug
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
        find_file "${PARAM_DN_DEST}" -name "tmp-*" | xargs -n 1 rm_f_dir
    fi

    if [ "${FLG_ERR}" = "1" ]; then
        echo -e "error-clean\t${DN_TEST}"
    fi
}

# check the throughput log file, if the log time reach to the pre-set end time.
# checked both for UDP and TCP packets, with file prefix CMTCPDS and CMUDPDS
# get the TIME_STOP from your config file
check_one_tcldir () {
    PARAM_FN_CONF=$1
    shift
    PARAM_DN_DEST=$1
    shift
    # output file save the failed directories
    PARAM_FN_LOG_ERROR=$1
    shift

    local FN_TMP="/dev/shm/config-$(uuidgen)"
    copy_file "${PARAM_FN_CONF}" "${FN_TMP}" > /dev/null 2>&1
    read_config_file "${FN_TMP}"
    rm_f_dir "${FN_TMP}" > /dev/null 2>&1

    FLG_ERR=1
    mr_trace "checking $(basename ${PARAM_DN_DEST}) ..."
    local RET
    RET=$(is_file_or_dir "${PARAM_DN_DEST}")
    if [ "${RET}" = "d" ]; then
        FLG_ERR=0
        FLG_NONE=1

        FN_TPFLOW="CMTCPDS*.out"
        mr_trace "checking tcp FN_TPFLOW=$FN_TPFLOW ..."
        #mr_trace "find_file '${PARAM_DN_DEST}' -name '${FN_TPFLOW}' ..."
        LST=$(find_file "${PARAM_DN_DEST}" -name "${FN_TPFLOW}" | sort)
        for i in $LST ; do
            FLG_NONE=0
            mr_trace "process flow throughput (tcp) $i ..."
            idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
            #mr_trace "curr dir=$(pwd), tail i=$i"
            TM1=$(tail -n 1 "$i" | awk '{print $1}')
            # we assume it done correctly if the time different is in 8 seconds
            if [ $(echo | awk -v A=$TM1 -v B=$TIME_STOP '{if (A + 8 < B) print 1; else print 0;}') = 1 ] ; then
                FLG_ERR=1
            fi
        done

        FN_TPFLOW="CMUDPDS*.out"
        mr_trace "checking udp FN_TPFLOW=$FN_TPFLOW ..."
        #mr_trace "find_file '${PARAM_DN_DEST}' -name '${FN_TPFLOW}' ..."
        LST=$(find_file "${PARAM_DN_DEST}" -name "${FN_TPFLOW}" | sort)
        for i in $LST ; do
            FLG_NONE=0
            mr_trace "process flow throughput (udp) $i ..."
            idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
            TM1=$(tail -n 1 "$i" | awk '{print $1}')
            if [ $(echo | awk -v A=$TM1 -v B=$TIME_STOP '{if (A + 5 < B) print 1; else print 0;}') = 1 ] ; then
                FLG_ERR=1
            fi
        done
        if [ "$FLG_NONE" = "1" ]; then
            FLG_ERR=1
        fi
    fi

    if [ "${FLG_ERR}" = "1" ]; then
        mr_trace "save ${PARAM_FN_LOG_ERROR}: ${PARAM_DN_DEST}"
        echo "${PARAM_DN_DEST}" >> "${PARAM_FN_LOG_ERROR}"
    fi
}
