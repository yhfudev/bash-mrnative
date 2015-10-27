#!/bin/bash
#####################################################################
# Run ns2 in a single machine using Map/Reduce paradigm -- Step 1 Map part
#
# In this part, the script check the config file name, and
# generate all of the TCL scripts files for ns2 and send the name of
# config file directory to output.
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

EXEC_NS2="$(my_getpath "${DN_EXEC}/../../ns")"

DN_COMM="$(my_getpath "${DN_EXEC}/common")"
DN_LIB="$(my_getpath "${DN_TOP}/lib")"

source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libshrt.sh
source ${DN_LIB}/libplot.sh
source ${DN_LIB}/libns2figures.sh
source ${DN_EXEC}/libapp.sh

DN_PARENT="$(my_getpath ".")"

#source ${DN_TOP}/config-sys.sh
read_config_file "${DN_TOP}/config-sys.sh"
DN_RESULTS="$(my_getpath "${HDFF_DN_OUTPUT}")"

check_global_config

#####################################################################
# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

#####################################################################
# create TCL directories
worker_create_tcl_config () {
    PARAM_SESSION_ID="$1"
    shift
    PARAM_CONFIG_FILE="$1"
    shift

    if [ "${HDFF_FUNCTION}" = "plot" ]; then
        prepare_all_tcl_scripts "plot" "${PARAM_CONFIG_FILE}"
    elif [ "${HDFF_FUNCTION}" = "check" ]; then
        prepare_all_tcl_scripts "check" "${PARAM_CONFIG_FILE}"
    elif [ "${HDFF_FUNCTION}" = "clean" ]; then
        prepare_all_tcl_scripts "clean" "${PARAM_CONFIG_FILE}"
    else
        prepare_all_tcl_scripts "sim" "${PARAM_CONFIG_FILE}"
    fi

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

#<command> <config_file>
# config "/path/to/config.sh"
while read MR_CMD MR_CONFIG_FILE ; do
    FN_CONFIG_FILE=$( unquote_filename "${MR_CONFIG_FILE}" )

    mr_trace "HDFF_FUNCTION=${HDFF_FUNCTION}"
    mr_trace "FN_CONFIG_FILE='${FN_CONFIG_FILE}'"
    case "${MR_CMD}" in
    config)
        worker_create_tcl_config "$(mp_get_session_id)" "${FN_CONFIG_FILE}" &
        PID_CHILD=$!
        mp_add_child_check_wait ${PID_CHILD}
        ;;

    *)
        mr_trace "Warning: unknown command '${MR_CMD}'."
        ;;
    esac
done

mp_wait_all_children
