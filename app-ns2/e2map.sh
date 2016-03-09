#!/bin/bash
#####################################################################
# Run ns2 using Map/Reduce paradigm -- Step 2 Map part
#
# In this part, the script run the ns2, and plotting some basic figures,
# generate stats files.
#
# Copyright 2015 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################
my_getpath () {
    local PARAM_DN="$1"
    shift
    #readlink -f
    local DN="${PARAM_DN}"
    local FN=
    if [ ! -d "${DN}" ]; then
        FN=$(basename "${DN}")
        DN=$(dirname "${DN}")
    fi
    local DNORIG=$(pwd)
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
if [ ! "${DN_EXEC}" = "" ]; then
    DN_EXEC="$(my_getpath "${DN_EXEC}")/"
else
    DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
DN_BIN="$(my_getpath "${DN_TOP}/bin/")"
DN_EXEC="$(my_getpath ".")"
#####################################################################
if [ -f "${DN_EXEC}/liball.sh" ]; then
. ${DN_EXEC}/liball.sh
fi

if [ ! "${DN_EXEC_4HADOOP}" = "" ]; then
  DN_EXEC="${DN_EXEC_4HADOOP}"
  DN_TOP="${DN_TOP_4HADOOP}"
  FN_CONF_SYS="${FN_CONF_SYS_4HADOOP}"
fi

RET=$(is_file_or_dir "${FN_CONF_SYS}")
if [ ! "${RET}" = "f" ]; then
    FN_CONF_SYS="${DN_EXEC}/mrsystem-working.conf"
    RET=$(is_file_or_dir "${FN_CONF_SYS}")
    if [ ! "${RET}" = "f" ]; then
        FN_CONF_SYS="${DN_TOP}/mrsystem.conf"
        RET=$(is_file_or_dir "${FN_CONF_SYS}")
        if [ ! "${RET}" = "f" ]; then
            mr_trace "not found config file: ${FN_CONF_SYS}"
        fi
    fi
fi

#####################################################################
# the default
EXEC_NS2="$(my_getpath "${DN_TOP}/../../ns")"

RET0=$(is_file_or_dir "${FN_CONF_SYS}")
if [ ! "$RET0" = "f" ]; then
    echo -e "debug\t$(hostname)\tgenerated_config\t${FN_CONF_SYS}"
    mr_trace "Warning: not found config file '${FN_CONF_SYS}'!"
    mr_trace "generating new config file '${FN_CONF_SYS}' ..."
    generate_default_config | save_file "${FN_CONF_SYS}"
fi
FN_TMP_2m="/tmp/config-$(uuidgen)"
copy_file "${FN_CONF_SYS}" "${FN_TMP_2m}" > /dev/null 2>&1
read_config_file "${FN_TMP_2m}"
rm_f_dir "${FN_TMP_2m}" > /dev/null 2>&1

check_global_config

mr_trace "e2map, HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"

#####################################################################
# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

libapp_prepare_app_binary

#####################################################################
# check ns2
worker_check_ns2() {
    PARAM_SESSION_ID="$1"
    shift
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

    DN_TEST=$(simulation_directory "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}")

    mr_trace "check_one_tcldir '$(basename ${PARAM_CONFIG_FILE})' '${DN_TEST}' '/dev/stdout' ..."
    RET=$(check_one_tcldir "${PARAM_CONFIG_FILE}" "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "/dev/stdout")
    if [ ! "$RET" = "" ]; then
        # error
        mr_trace "detected error at ${DN_TEST}"
        echo -e "error-check\t${PARAM_CONFIG_FILE}\t${PARAM_PREFIX}\t${PARAM_TYPE}\tunknown\t${PARAM_SCHE}\t${PARAM_NUM}" | tee -a "${DN_EXEC}/checkerror.txt"
    fi

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

# check dir
worker_check_run() {
    PARAM_SESSION_ID="$1"
    shift
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

    DN_TEST=$(simulation_directory "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}")

    RET=$(check_one_tcldir "${PARAM_CONFIG_FILE}" "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "/dev/stdout")
    if [ "$RET" = "" ]; then
        # the task was finished successfully
        prepare_figure_commands_for_one_stats "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
    else
        TM_START=$(date +%s.%N)
        mr_trace "run_one_ns2 ${HDFF_DN_OUTPUT}/dataconf ${DN_TEST} ${PARAM_CONFIG_FILE}"
        run_one_ns2 "${HDFF_DN_OUTPUT}/dataconf" "${DN_TEST}" "${PARAM_CONFIG_FILE}" 1>&2
        TM_END=$(date +%s.%N)
        # check the result
        RET=$(check_one_tcldir "${PARAM_CONFIG_FILE}" "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "/dev/stdout")
        mr_trace check_one_tcldir "${PARAM_CONFIG_FILE}" "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" return $RET
        if [ ! "$RET" = "" ]; then
            # error
            mr_trace "Error in ${DN_TEST}, ${TM_START}, ${TM_END}"
            echo -e "error-run\t${PARAM_CONFIG_FILE}\t${PARAM_PREFIX}\t${PARAM_TYPE}\tunknown\t${PARAM_SCHE}\t${PARAM_NUM}"
        else
            echo -e "time-run\t${PARAM_CONFIG_FILE}\t${PARAM_PREFIX}\t${PARAM_TYPE}\tunknown\t${PARAM_SCHE}\t${PARAM_NUM}\t${TM_START}\t${TM_END}"
            prepare_figure_commands_for_one_stats "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
        fi
    fi

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

# check dir
worker_plotonly () {
    PARAM_SESSION_ID="$1"
    shift
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

    DN_TEST=$(simulation_directory "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}")

    prepare_figure_commands_for_one_stats "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

# clean dir
worker_clean() {
    PARAM_SESSION_ID="$1"
    shift
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

    DN_TEST=$(simulation_directory "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}")

    mr_trace "remove file tmp-*, fig-* from ${HDFF_DN_OUTPUT}/figures/${PARAM_PREFIX}"
    find_file "${HDFF_DN_OUTPUT}/figures/${PARAM_PREFIX}" -name "tmp-*" | xargs -n 1 rm_f_dir > /dev/null 2>&1
    find_file "${HDFF_DN_OUTPUT}/figures/${PARAM_PREFIX}" -name "fig-*" | xargs -n 1 rm_f_dir > /dev/null 2>&1

    clean_one_tcldir "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}"

    #prepare_figure_commands_for_one_stats "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

#<command> <config_file> <prefix> <type> <flow type> <scheduler> <number_of_node>
#sim <config_file> <prefix> <type> <flow type> <scheduler> <number_of_node>
# sim "config-xx.sh" "jjmbase"  "tcp" "unknown" "PF" 24
while read MR_CMD MR_CONFIG_FILE MR_PREFIX MR_TYPE MR_FLOW_TYPE MR_SCHEDULER MR_NUM_NODE ; do
  FN_CONFIG_FILE=$( unquote_filename "${MR_CONFIG_FILE}" )
  MR_PREFIX1=$( unquote_filename "${MR_PREFIX}" )
  MR_TYPE1=$( unquote_filename "${MR_TYPE}" )
  MR_FLOW_TYPE1=$( unquote_filename "${MR_FLOW_TYPE}" )
  MR_SCHEDULER1=$( unquote_filename "${MR_SCHEDULER}" )
  GROUP_STATS="${MR_PREFIX1}|${MR_TYPE1}|${MR_SCHEDULER1}|${FN_CONFIG_FILE}|"

  mr_trace received: "${MR_CMD}\t${MR_CONFIG_FILE}\t${MR_PREFIX}\t${MR_TYPE}\t${MR_FLOW_TYPE}\t${MR_SCHEDULER}\t${MR_NUM_NODE}"

  case "${MR_CMD}" in
  sim)
    worker_check_run "$(mp_get_session_id)" "${FN_CONFIG_FILE}" ${MR_PREFIX1} ${MR_TYPE1} ${MR_SCHEDULER1} ${MR_NUM_NODE} &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  plot)
    worker_plotonly "$(mp_get_session_id)" "${FN_CONFIG_FILE}" ${MR_PREFIX1} ${MR_TYPE1} ${MR_SCHEDULER1} ${MR_NUM_NODE} &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  check)
    worker_check_ns2 "$(mp_get_session_id)" "${FN_CONFIG_FILE}" ${MR_PREFIX1} ${MR_TYPE1} ${MR_SCHEDULER1} ${MR_NUM_NODE} &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  clean)
    worker_clean "$(mp_get_session_id)" "${FN_CONFIG_FILE}" ${MR_PREFIX1} ${MR_TYPE1} ${MR_SCHEDULER1} ${MR_NUM_NODE} &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  error-run)
    mr_trace "regenerate the TCL scripts for ${MR_PREFIX1} ${MR_TYPE1} ${MR_SCHEDULER1} ${MR_NUM_NODE}"
    DN_TMP_CREATECONF="${HDFF_DN_SCRATCH}/tmp-createconf-$(uuidgen)"
    prepare_one_tcl_scripts "${MR_PREFIX1}" "${MR_TYPE1}" "${MR_SCHEDULER1}" "${MR_NUM_NODE}" "${DN_EXEC}" "${DN_COMM}" "${DN_TMP_CREATECONF}"
    copy_file "${DN_TMP_CREATECONF}/"* "${HDFF_DN_OUTPUT}/dataconf/" > /dev/null 2>&1
    rm_f_dir "${DN_TMP_CREATECONF}/"* > /dev/null 2>&1

    mr_trace "redo unfinished run: ${MR_CONFIG_FILE}\t${MR_PREFIX}\t${MR_TYPE}\t${MR_FLOW_TYPE}\t${MR_SCHEDULER}\t${MR_NUM_NODE}"
    worker_check_run "$(mp_get_session_id)" "${FN_CONFIG_FILE}" ${MR_PREFIX1} ${MR_TYPE1} ${MR_SCHEDULER1} ${MR_NUM_NODE} &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  *)
    mr_trace "Warning: unknown mr command '${MR_CMD}'."
    # throw the command to output again
    echo -e "${MR_CMD}\t${MR_CONFIG_FILE}\t${MR_PREFIX}\t${MR_TYPE}\t${MR_FLOW_TYPE}\t${MR_SCHEDULER}\t${MR_NUM_NODE}"
    ERR=1
    ;;
  esac

done

mp_wait_all_children
