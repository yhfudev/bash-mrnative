#!/bin/bash
#####################################################################
# Run test using Map/Reduce paradigm -- Step 1 Map part
#
# In this part, the script check the config file name, and
# generate all of the scripts files for test and send the name of
# config file directory to output.
#
# Copyright 2015 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################
my_getpath () {
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
mr_trace "e1map, DN_TOP=${DN_TOP}, DN_EXEC=${DN_EXEC}, FN_CONF_SYS=${FN_CONF_SYS}"

RET0=$(is_file_or_dir "${FN_CONF_SYS}")
if [ ! "$RET0" = "f" ]; then
    echo -e "debug\t$(hostname)\tgenerated_config\t${FN_CONF_SYS}"
    mr_trace "Warning: not found config file '${FN_CONF_SYS}'!"
    mr_trace "generating new config file '${FN_CONF_SYS}' ..."
    generate_default_config | save_file "${FN_CONF_SYS}"
fi
FN_TMP="/tmp/config-$(uuidgen)"
mr_trace copy_file "${FN_CONF_SYS}" "${FN_TMP}"
copy_file "${FN_CONF_SYS}" "${FN_TMP}" > /dev/null 2>&1
read_config_file "${FN_TMP}"

if [ $(is_local "${FN_TMP}") = l ]; then
    #cat_file "${FN_TMP}" | awk -v P=debug -v H=$(hostname) '{print P "\t" H "\ttmpconfig____"$0}'
    rm_f_dir "${FN_TMP}" > /dev/null 2>&1
else
    echo -e "debug\tError_file_is_not_local\t${FN_TMP}"
fi
check_global_config

mr_trace "e1map, DN_TOP=${DN_TOP}, DN_EXEC=${DN_EXEC}, FN_CONF_SYS=${FN_CONF_SYS}"
mr_trace "e1map, HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"
#echo -e "debug\tFN_CONF_SYS=${FN_CONF_SYS},FN_TMP=${FN_TMP},HDFF_FN_TAR_MRNATIVE=${HDFF_FN_TAR_MRNATIVE}"

#####################################################################
# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

# extract the mrnative, include the files in projtool/common which are used in setting ns2 TCL scripts
libapp_prepare_mrnative_binary

#####################################################################
# create TCL directories
worker_create_tcl_config () {
    local PARAM_SESSION_ID="$1"
    shift
    local PARAM_CONFIG_FILE="$1"
    shift

    local RET=0
    RET=$(is_file_or_dir "${PARAM_CONFIG_FILE}")
    if [ ! "${RET}" = "f" ]; then
        mr_trace "Error: not found config file: $PARAM_CONFIG_FILE"
        return
    fi

    mr_trace "infunc create tcl config: HDFF_FUNCTION=${HDFF_FUNCTION}"
    if [ "${HDFF_FUNCTION}" = "plot" ]; then
        libapp_prepare_execution_config "plot" "${PARAM_CONFIG_FILE}"
    elif [ "${HDFF_FUNCTION}" = "check" ]; then
        libapp_prepare_execution_config "check" "${PARAM_CONFIG_FILE}"
    elif [ "${HDFF_FUNCTION}" = "clean" ]; then
        libapp_prepare_execution_config "clean" "${PARAM_CONFIG_FILE}"
    else
        libapp_prepare_execution_config "sim" "${PARAM_CONFIG_FILE}"
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
        mr_trace "Warning: unknown mr command '${MR_CMD}'."
        ;;
    esac
done

mp_wait_all_children
