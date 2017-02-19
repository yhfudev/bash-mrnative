#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief Run ns2 using Map/Reduce paradigm -- Step 2 Reduce part
##
##   In this part, the script handle ploting stats figures.
##
## @author Yunhui Fu <yhfudev@gmail.com>
## @copyright GPL v3.0 or later
## @version 1
##
#####################################################################

## @fn my_getpath()
## @brief get the real name of a path
## @param dn the path name
##
## get the real name of a path, return the real path
my_getpath() {
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
RET0=$(is_file_or_dir "${FN_CONF_SYS}")
if [ ! "$RET0" = "f" ]; then
    echo -e "debug\t$(hostname)\tgenerated_config\t${FN_CONF_SYS}"
    mr_trace "Warning: not found config file '${FN_CONF_SYS}'!"
    mr_trace "generating new config file '${FN_CONF_SYS}' ..."
    generate_default_config | save_file "${FN_CONF_SYS}"
fi
FN_TMP_2r="/tmp/config-$(uuidgen)"
copy_file "${FN_CONF_SYS}" "${FN_TMP_2r}" > /dev/null 2>&1
read_config_file "${FN_TMP_2r}"
rm_f_dir "${FN_TMP_2r}" > /dev/null 2>&1

check_global_config

#####################################################################
# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

#####################################################################

## @fn worker_stats_throughput()
## @brief process throughput stats
## @param session_id the session id
## @param config_file config file
## @param prefix the prefix of the test
## @param type the test type, one of "udp", "tcp", "has", "udp+has", "tcp+has"
##
worker_stats_throughput() {
    PARAM_SESSION_ID="$1"
    shift
    PARAM_CONFIG_FILE="$1"
    shift
    PARAM_PREFIX="$1"
    shift
    PARAM_TYPE="$1"
    shift

    #mr_trace plot_ns2_type tpstat "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}"
    $MYEXEC plot_ns2_type tpstat "${PARAM_CONFIG_FILE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" 1>&2

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

  mr_trace received: "${MR_CMD}\t${MR_CONFIG_FILE}\t${MR_PREFIX}\t${MR_TYPE}\t${MR_FLOW_TYPE}\t${MR_SCHEDULER}\t${MR_NUM_NODE}"

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
