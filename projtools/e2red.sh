#!/bin/bash
#####################################################################
# Run ns2 in a single machine using Map/Reduce paradigm -- Step 2 Reduce part
#
# In this part, the script handle ploting stats figures.
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

DN_PARENT="$(my_getpath ".")"

#read_config_file "${DN_PARENT}/config.conf"
source ${DN_TOP}/config-sys.sh

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

# process throughput stats
worker_stats_throughput () {
    PARAM_SESSION_ID="$1"
    shift
    PARAM_CONFIG_FILE="$1"
    shift
    PARAM_PREFIX="$1"
    shift
    PARAM_TYPE="$1"
    shift

    #mr_trace ${DN_EXEC}/plotfigns2.sh tpstat "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_CONFIG_FILE}"
    ${DN_EXEC}/plotfigns2.sh tpstat "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_CONFIG_FILE}"

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

#####################################################################
# destination file name is the key of the data
PICGROUP_T_TAG=
PICGROUP_T_PREFIX=
PICGROUP_T_TYPE=
PICGROUP_T_SCHEDULER=
PICGROUP_T_CONFIG_FILE=

#<command> <config_file> <prefix> <type> <flow_type> <scheduler> <number_of_node>
#throughput <config_file> <prefix> <type> <flow_type> <scheduler> <number_of_node>
#packet <config_file> <prefix> <type> <flow_type> <scheduler> <number_of_node>
# throughput "config-xx.sh" "jjmbase"  "tcp" "tcp" "PF" 24
# packet "config-xx.sh" "jjmbase"  "tcp+has" "tcp" "PF" 24
while read MR_CMD MR_CONFIG_FILE MR_PREFIX MR_TYPE MR_FLOW_TYPE MR_SCHEDULER MR_NUM_NODE ; do
  FN_CONFIG_FILE=$( unquote_filename "${MR_CONFIG_FILE}" )
  MR_PREFIX1=$( unquote_filename "${MR_PREFIX}" )
  MR_TYPE1=$( unquote_filename "${MR_TYPE}" )
  MR_FLOW_TYPE1=$( unquote_filename "${MR_FLOW_TYPE}" )
  MR_SCHEDULER1=$( unquote_filename "${MR_SCHEDULER}" )

  GROUP_STATS="${MR_PREFIX1}|${MR_TYPE1}"

  ERR=0
  case "${MR_CMD}" in
  throughput)
    # REDUCE: read until reach to a different key, then reduce it

    # plot figure for each flow
    worker_flow_throughput "$(mp_get_session_id)" "${MR_PREFIX1}" "${MR_TYPE1}" "${MR_FLOW_TYPE1}" "${MR_SCHEDULER1}" "${MR_NUM_NODE}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}

    # plot stats
    if [ ! "${PICGROUP_T_TAG}" = "${GROUP_STATS}" ] ; then
      # new file set
      # save previous
      if [ ! "${PICGROUP_T_TAG}" = "" ] ; then
        worker_stats_throughput "$(mp_get_session_id)" "${PICGROUP_T_CONFIG_FILE}" "${PICGROUP_T_PREFIX}" "${PICGROUP_T_TYPE}" &
        PID_CHILD=$!
        mp_add_child_check_wait ${PID_CHILD}
      fi

      PICGROUP_T_TAG="${GROUP_STATS}"
      PICGROUP_T_PREFIX="${MR_PREFIX1}"
      PICGROUP_T_TYPE="${MR_TYPE1}"
      PICGROUP_T_SCHEDULER="${MR_SCHEDULER1}"
      PICGROUP_T_CONFIG_FILE="${FN_CONFIG_FILE}"
    fi
    ;;

  packet)
    # REDUCE: read until reach to a different key, then reduce it

    worker_stats_packet "$(mp_get_session_id)" "${MR_PREFIX1}" "${MR_TYPE1}" "${MR_FLOW_TYPE1}" "${MR_SCHEDULER1}" "${MR_NUM_NODE}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}

    worker_trans_packet "$(mp_get_session_id)" "${MR_PREFIX1}" "${MR_TYPE1}" "${MR_FLOW_TYPE1}" "${MR_SCHEDULER1}" "${MR_NUM_NODE}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  *)
    mr_trace "Error: unknown command: ${MR_CMD}"
    ERR=1
    continue
    ;;
  esac
  if [ ! "${ERR}" = "0" ] ; then
    mr_trace "ignore line: ${MR_CMD} ${MR_CONFIG_FILE} ${MR_PREFIX} ${MR_TYPE} ${MR_FLOW_TYPE} ${MR_SCHEDULER} ${MR_NUM_NODE}"
    continue
  fi

done

if [ ! "${PICGROUP_T_TAG}" = "" ]; then
    # the rest of the files
    worker_stats_throughput "$(mp_get_session_id)" "${PICGROUP_T_CONFIG_FILE}" "${PICGROUP_T_PREFIX}" "${PICGROUP_T_TYPE}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
fi

mp_wait_all_children
