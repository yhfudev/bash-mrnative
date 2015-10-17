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
#DN_EXEC="$(my_getpath "${DN_TOP}/bin/")"
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
source ${DN_COMM}/libbash.sh
source ${DN_COMM}/libshrt.sh
source ${DN_COMM}/libplot.sh

DN_PARENT="$(my_getpath ".")"

#read_config_file "${DN_PARENT}/config.conf"
source ${DN_PARENT}/config.sh

check_global_config

#####################################################################
# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

#####################################################################
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
    PARAM_SCHEDULE="$1"
    shift
    PARAM_NODE="$1"
    shift

    # run the work here:
    # ...

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
    PARAM_SCHEDULE="$1"
    shift
    PARAM_NODE="$1"
    shift

    # run the work here:
    # ...

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

#####################################################################
# destination file name is the key of the data
PICGROUP_T_TAG=
PICGROUP_T_PREFIX=
PICGROUP_T_TYPE_FLOW=
PICGROUP_T_SCHEDULER=
PICGROUP_T_CONFIG_FILE=

PICGROUP_P_TAG=
PICGROUP_P_PREFIX=
PICGROUP_P_TYPE_FLOW=
PICGROUP_P_SCHEDULER=
PICGROUP_P_CONFIG_FILE=

#<type> <config_file> <prefix> <type> <scheduler> <number_of_node>
#throughput <config_file> <prefix> <type> <scheduler> <number_of_node>
#packet <config_file> <prefix> <type> <scheduler> <number_of_node>
# throughput "config-xx.sh" "jjmbase"  "tcp" "PF" 24
# packet "config-xx.sh" "jjmbase"  "tcp" "PF" 24
while read MR_TYPE MR_CONFIG_FILE MR_PREFIX MR_TYPE_FLOW MR_SCHEDULER MR_NUM_NODE ; do
  FN_CONFIG_FILE=$( unquote_filename "${MR_CONFIG_FILE}" )
  GROUP_STATS="${MR_PREFIX}|${MR_TYPE_FLOW}|${MR_SCHEDULER}|${FN_CONFIG_FILE}|"

  case "${MR_TYPE}" in
  throughput)
    # REDUCE: read until reach to a different key, then reduce it
    if [ ! "${PICGROUP_T_TAG}" = "${GROUP_STATS}" ] ; then
      # new file set
      # save previous
      if [ ! "${PICGROUP_T_TAG}" = "" ] ; then
        worker_stats_throughput "$(mp_get_session_id)" "${PICGROUP_T_CONFIG_FILE}" "${PICGROUP_T_PREFIX}" "${PICGROUP_T_TYPE_FLOW}" "${PICGROUP_T_SCHEDULER}" &
        PID_CHILD=$!
        mp_add_child_check_wait ${PID_CHILD}
      fi

      PICGROUP_T_TAG="${GROUP_STATS}"
      PICGROUP_T_PREFIX="${MR_PREFIX}"
      PICGROUP_T_TYPE_FLOW="${MR_TYPE_FLOW}"
      PICGROUP_T_SCHEDULER="${MR_SCHEDULER}"
      PICGROUP_T_CONFIG_FILE="${FN_CONFIG_FILE}"
    fi
    ;;

  packet)
    # REDUCE: read until reach to a different key, then reduce it
    if [ ! "${PICGROUP_P_TAG}" = "${GROUP_STATS}" ] ; then
      # new file set
      # save previous
      if [ ! "${PICGROUP_P_TAG}" = "" ] ; then
        worker_stats_packet "$(mp_get_session_id)" "${PICGROUP_P_CONFIG_FILE}" "${PICGROUP_P_PREFIX}" "${PICGROUP_P_TYPE_FLOW}" "${PICGROUP_P_SCHEDULER}" &
        PID_CHILD=$!
        mp_add_child_check_wait ${PID_CHILD}
      fi

      PICGROUP_P_TAG="${GROUP_STATS}"
      PICGROUP_P_PREFIX="${MR_PREFIX}"
      PICGROUP_P_TYPE_FLOW="${MR_TYPE_FLOW}"
      PICGROUP_P_SCHEDULER="${MR_SCHEDULER}"
      PICGROUP_P_CONFIG_FILE="${FN_CONFIG_FILE}"
    fi
    ;;

  *)
    echo "e1red [DBG] Err: unknown type: ${MR_TYPE}" 1>&2
    continue
    ;;
  esac
  if [ ! "${ERR}" = "0" ] ; then
    echo "e1red [DBG] ignore line: ${MR_TYPE} ${MR_VIDEO_IN} ${MR_AUDIO_FILE} ${MR_VIDEO_OUT} ${MR_SEGSEC} ${MR_VIDEO_FPS} ${MR_N_START}" 1>&2
    continue
  fi

done

if [ ! "${PICGROUP_T_TAG}" = "" ]; then
    # the rest of the files
    worker_stats_throughput "$(mp_get_session_id)" "${PICGROUP_T_CONFIG_FILE}" "${PICGROUP_T_PREFIX}" "${PICGROUP_T_TYPE_FLOW}" "${PICGROUP_T_SCHEDULER}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
fi
if [ ! "${PICGROUP_P_TAG}" = "" ]; then
    # the rest of the files
    worker_stats_packet "$(mp_get_session_id)" "${PICGROUP_P_CONFIG_FILE}" "${PICGROUP_P_PREFIX}" "${PICGROUP_P_TYPE_FLOW}" "${PICGROUP_P_SCHEDULER}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
fi

mp_wait_all_children
