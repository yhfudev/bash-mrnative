#!/bin/bash
#####################################################################
# Run ns2 in a single machine using Map/Reduce paradigm -- Step 3 Map part
#
# In this part, the script plots time-consumed figures
# generate stats files.
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
if [ -f "${DN_EXEC}/libshall.sh" ]; then
. ${DN_EXEC}/libshall.sh
fi

if [ ! "${DN_EXEC_4HADOOP}" = "" ]; then
  DN_EXEC="${DN_EXEC_4HADOOP}"
  DN_TOP="${DN_TOP_4HADOOP}"
fi
#####################################################################

DN_COMM="$(my_getpath "${DN_EXEC}/common")"
DN_LIB="$(my_getpath "${DN_TOP}/lib")"
source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libshrt.sh
source ${DN_LIB}/libplot.sh
source ${DN_LIB}/libns2figures.sh
source ${DN_EXEC}/libapp.sh

source "${DN_TOP}/config-sys.sh"
#DN_RESULTS="$(my_getpath "${HDFF_DN_OUTPUT}")"

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

    #mr_trace "worker_flow_throughput(): " ${DN_EXEC}/plotfigns2.sh tpflow "${PARAM_PREFIX}" "${PARAM_TYPE}" "${MR_FLOW_TYPE}" "${PARAM_SCHEDULE}" "${PARAM_NODE}"
    ${DN_EXEC}/plotfigns2.sh tpflow "${PARAM_PREFIX}" "${PARAM_TYPE}" "${MR_FLOW_TYPE}" "${PARAM_SCHEDULE}" "${PARAM_NODE}"

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

# process packet time stats
worker_stats_packet () {
    PARAM_SESSION_ID="$1"
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

    ${DN_EXEC}/plotfigns2.sh pktstat "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_FLOW_TYPE}" "${PARAM_SCHEDULE}" "${PARAM_NODE}"

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

# process packet time stats
worker_trans_packet () {
    PARAM_SESSION_ID="$1"
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

    #mr_trace ${DN_EXEC}/plotfigns2.sh pkttrans "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_FLOW_TYPE}" "${PARAM_SCHEDULE}" "${PARAM_NODE}"
    ${DN_EXEC}/plotfigns2.sh pkttrans "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_FLOW_TYPE}" "${PARAM_SCHEDULE}" "${PARAM_NODE}"

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
  tpflow)
    # plot figure for each flow
    worker_flow_throughput "$(mp_get_session_id)" "${MR_PREFIX1}" "${MR_TYPE1}" "${MR_FLOW_TYPE1}" "${MR_SCHEDULER1}" "${MR_NUM_NODE}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  packetsche)
    # the packet scheduling time distribution
    worker_stats_packet "$(mp_get_session_id)" "${MR_PREFIX1}" "${MR_TYPE1}" "${MR_FLOW_TYPE1}" "${MR_SCHEDULER1}" "${MR_NUM_NODE}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  packettran)
    # the packet transfering time distribution
    worker_trans_packet "$(mp_get_session_id)" "${MR_PREFIX1}" "${MR_TYPE1}" "${MR_FLOW_TYPE1}" "${MR_SCHEDULER1}" "${MR_NUM_NODE}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  *)
    mr_trace "Error: unknown type: ${MR_CMD}"
    # throw the command to output again
    echo -e "${MR_CMD}\t${MR_CONFIG_FILE}\t${MR_PREFIX}\t${MR_TYPE}\t${MR_FLOW_TYPE}\t${MR_SCHEDULER}\t${MR_NUM_NODE}"
    ERR=1
    ;;
  esac

done

mp_wait_all_children
