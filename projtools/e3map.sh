#!/bin/bash
#####################################################################
# Run ns2 using Map/Reduce paradigm -- Step 3 Map part
#
# In this part, the script plots time-consumed figures
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
if [ ! "${DN_EXEC}" = "" ]; then
    DN_EXEC="$(my_getpath "${DN_EXEC}")/"
else
    DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
DN_EXEC="$(my_getpath "${DN_TOP}/projtools/")"
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
RET0=$(is_file_or_dir "${FN_CONF_SYS}")
if [ ! "$RET0" = "f" ]; then
    echo -e "debug\t$(hostname)\tgenerated_config\t${FN_CONF_SYS}"
    mr_trace "Warning: not found config file '${FN_CONF_SYS}'!"
    mr_trace "generating new config file '${FN_CONF_SYS}' ..."
    generate_default_config | save_file "${FN_CONF_SYS}"
fi
FN_TMP_3m="/tmp/config-$(uuidgen)"
copy_file "${FN_CONF_SYS}" "${FN_TMP_3m}" > /dev/null 2>&1
read_config_file "${FN_TMP_3m}"
rm_f_dir "${FN_TMP_3m}" > /dev/null 2>&1

check_global_config

#####################################################################
# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

#####################################################################
# process flow throughput figure
worker_flow_throughput () {
    PARAM_SESSION_ID="$1"
    shift
    PARAM_CONFIG_FILE="$1"
    shift
    PARAM_PREFIX="$1"
    shift
    PARAM_TYPE="$1"
    shift
    PARAM_FLOW_TYPE="$1"
    shift
    PARAM_SCHEDULE="$1"
    shift
    PARAM_NODE="$1"
    shift

    #mr_trace "worker_flow_throughput(): " plot_ns2_type tpflow "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_FLOW_TYPE}" "${PARAM_SCHEDULE}" "${PARAM_NODE}"
    TM_START=$(date +%s.%N)
    $MYEXEC plot_ns2_type bitflow "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_FLOW_TYPE}" "${PARAM_SCHEDULE}" "${PARAM_NODE}"
    TM_END=$(date +%s.%N)
    echo -e "time-bitflow\t${PARAM_CONFIG_FILE}\t${PARAM_PREFIX}\t${PARAM_TYPE}\t${PARAM_FLOW_TYPE}\t${PARAM_SCHEDULE}\t${PARAM_NODE}\t${TM_START}\t${TM_END}"

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

# process packet time stats
worker_stats_packet () {
    PARAM_SESSION_ID="$1"
    shift
    PARAM_CONFIG_FILE="$1"
    shift
    PARAM_PREFIX="$1"
    shift
    PARAM_TYPE="$1"
    shift
    PARAM_FLOW_TYPE="$1"
    shift
    PARAM_SCHEDULE="$1"
    shift
    PARAM_NODE="$1"
    shift

    TM_START=$(date +%s.%N)
    $MYEXEC plot_ns2_type pktstat "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_FLOW_TYPE}" "${PARAM_SCHEDULE}" "${PARAM_NODE}"
    TM_END=$(date +%s.%N)
    echo -e "time-pktsche\t${PARAM_CONFIG_FILE}\t${PARAM_PREFIX}\t${PARAM_TYPE}\t${PARAM_FLOW_TYPE}\t${PARAM_SCHEDULE}\t${PARAM_NODE}\t${TM_START}\t${TM_END}"

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

# process packet time stats
worker_trans_packet () {
    PARAM_SESSION_ID="$1"
    shift
    PARAM_CONFIG_FILE="$1"
    shift
    PARAM_PREFIX="$1"
    shift
    PARAM_TYPE="$1"
    shift
    PARAM_FLOW_TYPE="$1"
    shift
    PARAM_SCHEDULE="$1"
    shift
    PARAM_NODE="$1"
    shift

    #mr_trace plot_ns2_type pkttrans "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_FLOW_TYPE}" "${PARAM_SCHEDULE}" "${PARAM_NODE}"
    TM_START=$(date +%s.%N)
    $MYEXEC plot_ns2_type pkttrans "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_FLOW_TYPE}" "${PARAM_SCHEDULE}" "${PARAM_NODE}"
    TM_END=$(date +%s.%N)
    echo -e "time-pkttran\t${PARAM_CONFIG_FILE}\t${PARAM_PREFIX}\t${PARAM_TYPE}\t${PARAM_FLOW_TYPE}\t${PARAM_SCHEDULE}\t${PARAM_NODE}\t${TM_START}\t${TM_END}"

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

#<command> <config_file> <prefix> <type> <flow type> <scheduler> <number_of_node>
#packetsche <config_file> <prefix> <type> <flow type> <scheduler> <number_of_node>
#packettran <config_file> <prefix> <type> <flow type> <scheduler> <number_of_node>
#tpflow <config_file> <prefix> <type> <flow type> <scheduler> <number_of_node>
# tpflow "config-xx.sh" "jjmbase"  "tcp" "tcp" "PF" 24
while read MR_CMD MR_CONFIG_FILE MR_PREFIX MR_TYPE MR_FLOW_TYPE MR_SCHEDULER MR_NUM_NODE ; do

    mr_trace "received: cmd='${MR_CMD}', prefix='${MR_PREFIX}', type='${MR_TYPE}', flow='${MR_FLOW_TYPE}', sche='${MR_SCHEDULER}', num='${MR_NUM_NODE}'"

    FN_CONFIG_FILE=$( unquote_filename "${MR_CONFIG_FILE}" )
    MR_PREFIX1=$( unquote_filename "${MR_PREFIX}" )
    MR_TYPE1=$( unquote_filename "${MR_TYPE}" )
    MR_FLOW_TYPE1=$( unquote_filename "${MR_FLOW_TYPE}" )
    MR_SCHEDULER1=$( unquote_filename "${MR_SCHEDULER}" )
    GROUP_STATS="${MR_PREFIX1}|${MR_TYPE1}|${MR_SCHEDULER1}|${FN_CONFIG_FILE}|"

    case "${MR_CMD}" in
    bitflow)
        # plot figure for each flow
        worker_flow_throughput "$(mp_get_session_id)" "${FN_CONFIG_FILE}" "${MR_PREFIX1}" "${MR_TYPE1}" "${MR_FLOW_TYPE1}" "${MR_SCHEDULER1}" "${MR_NUM_NODE}" &
        PID_CHILD=$!
        mp_add_child_check_wait ${PID_CHILD}
        ;;

    packetsche)
        # the packet scheduling time distribution
        worker_stats_packet "$(mp_get_session_id)" "${FN_CONFIG_FILE}" "${MR_PREFIX1}" "${MR_TYPE1}" "${MR_FLOW_TYPE1}" "${MR_SCHEDULER1}" "${MR_NUM_NODE}" &
        PID_CHILD=$!
        mp_add_child_check_wait ${PID_CHILD}
        ;;

    packettran)
        # the packet transfering time distribution
        worker_trans_packet "$(mp_get_session_id)" "${FN_CONFIG_FILE}" "${MR_PREFIX1}" "${MR_TYPE1}" "${MR_FLOW_TYPE1}" "${MR_SCHEDULER1}" "${MR_NUM_NODE}" &
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
