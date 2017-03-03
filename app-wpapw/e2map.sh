#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief Run aircrack using Map/Reduce paradigm -- Step 2 Map part
##
##   In this part, the script run the aircrack
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
EXEC_HASHCAT=`which hashcat`
EXEC_AIRCRACK=`which aircrack-ng`
EXEC_PYRIT=`which pyrit`
EXEC_WPACLEAN=$(which "wpaclean")

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
mr_trace "e2map, DN_TOP=${DN_TOP}, DN_EXEC=${DN_EXEC}, FN_CONF_SYS=${FN_CONF_SYS}"

RET0=$(is_file_or_dir "${FN_CONF_SYS}")
if [ ! "$RET0" = "f" ]; then
    echo -e "debug\t$(hostname)\tgenerated_config\t${FN_CONF_SYS}"
    mr_trace "Warning: not found config file '${FN_CONF_SYS}'!"
    mr_trace "generating new config file '${FN_CONF_SYS}' ..."
    generate_default_config | save_file "${FN_CONF_SYS}"
fi
FN_TMP_2m="/tmp/config-$(uuidgen)"
copy_file "${FN_CONF_SYS}" "${FN_TMP_2m}" > /dev/null
read_config_file "${FN_TMP_2m}"

if [ $(is_local "${FN_TMP_2m}") = l ]; then
    rm_f_dir "${FN_TMP_2m}" 1>&2
else
    echo -e "debug\tError_file_is_not_local\t${FN_TMP_2m}"
fi
check_global_config

# read the application's config file
FN_CONF_APP="${DN_EXEC}/config-wpapw.conf"
RET0=$(is_file_or_dir "${FN_CONF_APP}")
if [ "$RET0" = "f" ]; then
    read_config_file "${FN_CONF_APP}"
fi

mr_trace "e2map, DN_TOP=${DN_TOP}, DN_EXEC=${DN_EXEC}, FN_CONF_SYS=${FN_CONF_SYS}"
mr_trace "e2map, HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"

#####################################################################
# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

libapp_prepare_app_binary

#####################################################################
## @fn worker_crack_hashcat()
## @brief run oclhashcat command to crack
## @param session_id the session id
## @param bssid the BSSID
## @param fn_dump the dump file name
## @param pattern the pattern
## @param start the start
## @param count the count
##
## run hashcat command to crack
worker_crack_hashcat() {
    #worker_crack_hashcat "$(mp_get_session_id)" "${MR_PWTYPE}" "${FN_DUMP}" "${MR_PATTERN}" "${MR_RULE}" &
    local PARAM_SESSION_ID="$1"
    shift
    local PARAM_PWTYPE=$1
    shift
    local PARAM_FN_DUMP="$1"
    shift
    local PARAM_PATTERN=$1
    shift
    local PARAM_RULE=$1
    shift

    mr_trace "worker_crack_hashcat(SESSION_ID=${PARAM_SESSION_ID}; PWTYPE=${PARAM_PWTYPE}; FN_DUMP=${PARAM_FN_DUMP}; PATTERN=${PARAM_PATTERN}; RULE=${PARAM_RULE}; )"
    case "${MR_PWTYPE}" in
    dictionary)
        ;;
    mask)
        #VAL=$(seq ${PARAM_START} $(( ${PARAM_START} + ${PARAM_COUNT} )) | $MYEXEC ${EXEC_AIRCRACK} -b ${PARAM_BSSID} -w- ${PARAM_FN_DUMP} | grep -i found )
        #VAL=$(seq ${PARAM_START} $(( ${PARAM_START} + ${PARAM_COUNT} )) | $MYEXEC ${EXEC_PYRIT} -r ${PARAM_FN_DUMP} -i - -b ${PARAM_BSSID} attack_passthrough | grep -i found )

        FN_MSG="/tmp/app-wpapw-msg-$(uuidgen)"
        $MYEXEC ${EXEC_HASHCAT} -m 2500 ${PARAM_FN_DUMP} -a 3 ${PARAM_PATTERN} --outfile-check-dir=$(pwd)/aaa -session-dir=$(pwd)/bbb --opencl-platform 1 > "${FN_MSG}"
        RET=$?
        mr_trace "end of wpa hashcat"
        if [ $RET = 0 ]; then
            # found!
            T=$(cat "${FN_MSG}" | grep Hash.Target | awk '{print $2}')
            V0=$(cat "${FN_MSG}" | grep $T | grep -v Hash.Target)
            V=$(echo " ${V0}" | sed -e 's|\([^\:]*[[:space:]]\+\)||' -e '/^$/d' )
            echo -e "outwpa\t${PARAM_FN_DUMP}\tfound\t${V}"
        else
            mr_trace "outwpa\t${PARAM_FN_DUMP}\tnotfound\t:-("
            echo -e "outwpa\t${PARAM_FN_DUMP}\tnotfound\t:-("
        fi
        mr_trace "end of wpa mask"
        ;;
    rule)
        ;;
    *)
        mr_trace "Error: unknown hashcat type '${PARAM_PWTYPE}'."
        ;;
    esac

    mp_notify_child_exit ${PARAM_SESSION_ID}
}


#<command> <dump.cap> <pwtype> <pattern> <rule>
#wpa <dump.cap> <pwtype> <pattern> <rule>
while IFS=$'\t' read -r MR_CMD MR_FN_DUMP MR_PWTYPE MR_PATTERN MR_RULE ; do
  FN_DUMP=$( unquote_filename "${MR_FN_DUMP}" )
  #GROUP_STATS="${MR_PREFIX1}|${MR_TYPE1}|${MR_SCHEDULER1}|${FN_CONFIG_FILE}|"

  mr_trace received: "${MR_CMD}\t${MR_FN_DUMP}\t${MR_PWTYPE}\t${MR_PATTERN}\t${MR_RULE}"

  case "${MR_CMD}" in
  wpa)
    worker_crack_hashcat "$(mp_get_session_id)" "${MR_PWTYPE}" "${FN_DUMP}" "${MR_PATTERN}" "${MR_RULE}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  *)
    mr_trace "Warning: unknown mr command '${MR_CMD}'."
    # throw the command to output again
    echo -e "${MR_CMD}\t${MR_FN_DUMP}\t${MR_PWTYPE}\t${MR_PATTERN}\t${MR_RULE}"
    ERR=1
    ;;
  esac

done

mp_wait_all_children
