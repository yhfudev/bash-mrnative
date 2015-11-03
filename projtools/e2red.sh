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
FN_CONF_SYS="${DN_TOP}/config-sys.sh"
#####################################################################
if [ -f "${DN_EXEC}/liball.sh" ]; then
. ${DN_EXEC}/liball.sh
fi

if [ ! "${DN_EXEC_4HADOOP}" = "" ]; then
  DN_EXEC="${DN_EXEC_4HADOOP}"
  DN_TOP="${DN_TOP_4HADOOP}"
  FN_CONF_SYS="${FN_CONF_SYS_4HADOOP}"
fi
#####################################################################
RET0=$(is_file_or_dir "${FN_CONF_SYS}")
if [ ! "$RET0" = "f" ]; then
    mr_trace "Warning: not found config file '${FN_CONF_SYS}'!"
    mr_trace "generating new config file '${FN_CONF_SYS}' ..."
    generate_default_config | save_file "${FN_CONF_SYS}"
fi
FN_TMP="/tmp/config-$(uuidgen)"
copy_file "${FN_CONF_SYS}" "${FN_TMP}" > /dev/null 2>&1
read_config_file "${FN_TMP}"
rm_f_dir "${FN_TMP}" > /dev/null 2>&1

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

    #mr_trace plot_ns2_type tpstat "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_CONFIG_FILE}"
    plot_ns2_type tpstat "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_CONFIG_FILE}"

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
    echo -e "bitflow\t${MR_CONFIG_FILE}\t${MR_PREFIX}\t${MR_TYPE}\t${MR_FLOW_TYPE}\t${MR_SCHEDULER}\t${MR_NUM_NODE}"

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
    echo -e "packetsche\t${MR_CONFIG_FILE}\t${MR_PREFIX}\t${MR_TYPE}\t${MR_FLOW_TYPE}\t${MR_SCHEDULER}\t${MR_NUM_NODE}"
    echo -e "packettran\t${MR_CONFIG_FILE}\t${MR_PREFIX}\t${MR_TYPE}\t${MR_FLOW_TYPE}\t${MR_SCHEDULER}\t${MR_NUM_NODE}"
    ;;

  *)
    #mr_trace "Warning: unknown mr command '${MR_CMD}'."
    # throw the command to output again
    echo -e "${MR_CMD}\t${MR_CONFIG_FILE}\t${MR_PREFIX}\t${MR_TYPE}\t${MR_FLOW_TYPE}\t${MR_SCHEDULER}\t${MR_NUM_NODE}"
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
