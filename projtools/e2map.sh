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
DN_LIB="$(my_getpath "${DN_TOP}/lib")"
source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libshrt.sh
source ${DN_LIB}/libplot.sh
source ${DN_LIB}/libns2figures.sh

DN_PARENT="$(my_getpath ".")"

EXEC_NS2="$(my_getpath "${DN_TOP}/../../ns")"
FN_LOG="/dev/null"

#read_config_file "${DN_PARENT}/config.conf"
source ${DN_TOP}/config-sys.sh

check_global_config

source ${DN_EXEC}/libapp.sh

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

    run_one_ns2 "${DN_TOP}/results" "${DN_TEST}"
    prepare_figure_commands_for_one_stats "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"

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

    RET=$(check_one_tcldir "${DN_TOP}/results/${DN_TEST}" "/dev/stdout")
    if [ ! "$RET" = "" ]; then
        run_one_ns2 "${DN_TOP}/results" "${DN_TEST}"
        prepare_figure_commands_for_one_stats "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"
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

    cd "${DN_TOP}/figures/${PARAM_PREFIX}"
    find . -maxdepth 1 -type f -name "tmp-*" | xargs -n 5 rm -f
    find . -maxdepth 1 -type f -name "fig-*" | xargs -n 5 rm -f
    cd -

    clean_one_tcldir "${DN_TOP}/results/${DN_TEST}"

    #prepare_figure_commands_for_one_stats "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

#<command> <config_file> <prefix> <type> <scheduler> <number_of_node>
#sim <config_file> <prefix> <type> <scheduler> <number_of_node>
# sim "config-xx.sh" "jjmbase"  "tcp" "PF" 24
while read MR_CMD MR_CONFIG_FILE MR_PREFIX MR_TYPE MR_SCHEDULER MR_NUM_NODE ; do
  FN_CONFIG_FILE=$( unquote_filename "${MR_CONFIG_FILE}" )
  MR_PREFIX1=$( unquote_filename "${MR_PREFIX}" )
  MR_TYPE1=$( unquote_filename "${MR_TYPE}" )
  MR_SCHEDULER1=$( unquote_filename "${MR_SCHEDULER}" )
  GROUP_STATS="${MR_PREFIX1}|${MR_TYPE1}|${MR_SCHEDULER1}|${FN_CONFIG_FILE}|"

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

  clean)
    worker_clean "$(mp_get_session_id)" "${FN_CONFIG_FILE}" ${MR_PREFIX1} ${MR_TYPE1} ${MR_SCHEDULER1} ${MR_NUM_NODE} &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  *)
    echo "e2map [DBG] Err: unknown type: ${MR_CMD}" 1>&2
    ERR=1
    ;;
  esac

done

mp_wait_all_children
