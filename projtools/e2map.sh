#!/bin/bash
#####################################################################
# Run ns2 in a single machine using Map/Reduce paradigm -- Step 2 Map part
#
# In this part, the script run the ns2, and plotting some basic figures,
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
# run ns2
worker_run_ns2() {
    PARAM_SESSION_ID="$1"
    shift
    PARAM_CONFIG_FILE="$1"
    shift

    # run the work here:
    # ...

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

#<type> <config_file> <prefix> <type> <scheduler> <number_of_node>
#sim <config_file> <prefix> <type> <scheduler> <number_of_node>
# sim "config-xx.sh" "jjmbase"  "tcp" "PF" 24
while read MR_TYPE MR_CONFIG_FILE MR_PREFIX MR_TYPE_FLOW MR_SCHEDULER MR_NUM_NODE ; do
  FN_CONFIG_FILE=$( unquote_filename "${MR_CONFIG_FILE}" )
  GROUP_STATS="${MR_PREFIX}|${MR_TYPE_FLOW}|${MR_SCHEDULER}|${FN_CONFIG_FILE}|"

  case "${MR_TYPE}" in
  sim)
    worker_run_ns2 "$(mp_get_session_id)" "${FN_CONFIG_FILE}" ${MR_PREFIX} ${MR_TYPE_FLOW} ${MR_SCHEDULER} ${MR_NUM_NODE} &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  *)
    echo "e1map [DBG] Err: unknown type: ${MR_TYPE}" 1>&2
    ERR=1
    ;;
  esac

done

mp_wait_all_children
