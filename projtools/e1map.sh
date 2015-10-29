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
if [ -f "${DN_EXEC}/liball.sh" ]; then
. ${DN_EXEC}/liball.sh
fi

if [ ! "${DN_EXEC_4HADOOP}" = "" ]; then
  DN_EXEC="${DN_EXEC_4HADOOP}"
  DN_TOP="${DN_TOP_4HADOOP}"
fi
#####################################################################
#HDFF_NUM_CLONE=0
#HDFF_TOTAL_NODES=1
#HDFF_FN_LOG="/dev/null"
#HDFF_DN_SCRATCH="/dev/shm1/${USER}/"

RET0=$(is_file_or_dir "${DN_TOP}/config-sys.sh")
if [ ! "$RET0" = "f" ]; then
    generate_default_config | save_file "${DN_TOP}/config-sys.sh"
fi
FN_TMP="/dev/shm/config-$(uuidgen)"
copy_file "${DN_TOP}/config-sys.sh" "${FN_TMP}" > /dev/null 2>&1
read_config_file "${FN_TMP}"
rm_f_dir "${FN_TMP}" > /dev/null 2>&1

check_global_config

mr_trace cat_file "${DN_TOP}/config-sys.sh"
cat_file "${DN_TOP}/config-sys.sh" 1>&2
mr_trace "e1map, global config=${DN_TOP}/config-sys.sh"
mr_trace "e1map, HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"

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

    if [ ! -f "${PARAM_CONFIG_FILE}" ]; then
        mr_trace "Error: not found config file: $PARAM_CONFIG_FILE"
        exit 1
    fi

    mr_trace "infunc create tcl config: HDFF_FUNCTION=${HDFF_FUNCTION}"
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

    mr_trace "1 HDFF_FUNCTION=${HDFF_FUNCTION}"
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
