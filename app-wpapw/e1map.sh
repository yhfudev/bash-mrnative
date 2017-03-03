#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief Run aircrack using Map/Reduce paradigm -- Step 1 Map part
##
##   In this part, the script check the config file name, and
##   generate all of the task config lines.
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
mr_trace "e1map, DN_TOP=${DN_TOP}, DN_EXEC=${DN_EXEC}, FN_CONF_SYS=${FN_CONF_SYS}"

RET0=$(is_file_or_dir "${FN_CONF_SYS}")
if [ ! "$RET0" = "f" ]; then
    echo -e "debug\t$(hostname)\tgenerated_config\t${FN_CONF_SYS}"
    mr_trace "Warning: not found config file '${FN_CONF_SYS}'!"
    mr_trace "generating new config file '${FN_CONF_SYS}' ..."
    generate_default_config | save_file "${FN_CONF_SYS}"
fi
FN_TMP_1m="/tmp/config-$(uuidgen)"
copy_file "${FN_CONF_SYS}" "${FN_TMP_1m}" > /dev/null
read_config_file "${FN_TMP_1m}"

if [ $(is_local "${FN_TMP_1m}") = l ]; then
    #cat_file "${FN_TMP_1m}" | awk -v P=debug -v H=$(hostname) '{print P "\t" H "\ttmpconfig____"$0}'
    rm_f_dir "${FN_TMP_1m}" 1>&2
else
    echo -e "debug\tError_file_is_not_local\t${FN_TMP_1m}"
fi
check_global_config

# read the application's config file
FN_CONF_APP="${DN_EXEC}/config-wpapw.conf"
RET0=$(is_file_or_dir "${FN_CONF_APP}")
if [ "$RET0" = "f" ]; then
    read_config_file "${FN_CONF_APP}"
fi

mr_trace "e1map, DN_TOP=${DN_TOP}, DN_EXEC=${DN_EXEC}, FN_CONF_SYS=${FN_CONF_SYS}"
mr_trace "e1map, HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"
#echo -e "debug\tFN_CONF_SYS=${FN_CONF_SYS},FN_TMP=${FN_TMP_1m},HDFF_FN_TAR_MRNATIVE=${HDFF_FN_TAR_MRNATIVE}"

#####################################################################
# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

# extract the mrnative, include the data files?
libapp_prepare_mrnative_binary
DN_EXEC="${DN_TOP}/projtools/"
DN_COMM="${DN_EXEC}/common/"

#####################################################################

## @fn generate_custom_mask_lines()
## @brief generate the WPA crack mask lines for hashcat
## @param num_segment the number of words in a segment
## @param max_num the length of the string
## @param charset the charset string, such as 1234567890ABCDEF
## @param line_prefix the prefix line with the mask, such as "wpa\t${FN_HCCAP}\tmask\t"
##
generate_custom_mask_lines() {
    local PARAM_NUM_SEGMENT="$1"
    shift
    local PARAM_MAX="$1"
    shift
    local PARAM_CHARSET="$1"
    shift
    local PARAM_STR_PREFIX="$1"
    shift

    FN_AWK="/tmp/app-wpapw-awk-$(uuidgen)"
    cat << EOF > "${FN_AWK}"
{
    num_charset=length(CHARSET);
    split(CHARSET, charset_array, "")
    num_suffix=0;
    val_suffix=1;
    while (val_suffix < NUM_SEGMENT) {
        val_suffix = val_suffix * num_charset;
        num_suffix = num_suffix + 1;
    }
    if (num_suffix >= MAX) {
        num_suffix = MAX;
    }
    num_prefix = MAX - num_suffix;
    suffix = "";
    for (i = 0; i < num_suffix; i ++) {
        suffix = suffix "?1";
    }
    # init prefix array
    for (i = 0; i < num_prefix; i ++) {
        prefix_idx[i] = 0;
    }
    while (1) {
        # get the prefix of the mask
        prefix_mask = ""
        for (i = 0; i < num_prefix; i ++) {
            prefix_mask = prefix_mask charset_array[prefix_idx[i] + 1];
        }
        print STR_PREFIX "-1 " CHARSET " " prefix_mask suffix "\t";
        # increase prefix index by 1
        c = 1;
        for (i = 0; (c > 0) && (i < num_prefix); i ++) {
            prefix_idx[i] = prefix_idx[i] + c;
            if (prefix_idx[i] >= num_charset) {
                c = 1;
                prefix_idx[i] = 0;
            } else {
                c = 0;
            }
        }
        if (c > 0) {
            break;
        }
    }
}
EOF
    echo | awk -v CHARSET=${PARAM_CHARSET} -v MAX=${PARAM_MAX} -v NUM_SEGMENT=${PARAM_NUM_SEGMENT} -v STR_PREFIX=${PARAM_STR_PREFIX} -f "${FN_AWK}"
}

## @fn worker_create_wpa_config()
## @brief create command lines for WPA crack
## @param session_id the session id
## @param input_file .hccap file
##
## create command lines according to the predefined configs
worker_create_wpa_config() {
    local PARAM_SESSION_ID="$1"
    shift
    local PARAM_INPUT_FILE="$1"
    shift

    local RET=0
    RET=$(is_file_or_dir "input/${PARAM_INPUT_FILE}")
    if [ ! "${RET}" = "f" ]; then
        mr_trace "Error: not found input file: input/$PARAM_INPUT_FILE"
        return
    fi

    mr_trace "infunc create wpa config: PARAM_INPUT_FILE=${PARAM_INPUT_FILE}"
    BSSID=
    ESSID=
    FN_HCCAP="input/${PARAM_INPUT_FILE}"
    # get the name,bssid of AP
    case "${PARAM_INPUT_FILE}" in
    *-hs.hccap)
        FN_MSG="/tmp/app-wpapw-msg-$(uuidgen)"
        FN_HCCAP="input/${PARAM_INPUT_FILE}"
        $MYEXEC ${EXEC_HASHCAT} -m 2500 "input/${PARAM_INPUT_FILE}" -a 3 1234567890 > "${FN_MSG}"
        # example:
        #Hash.Target......: This is my ESSID! (00:11:22:33:44:55 <-> 66:77:88:99:aa:bb)
        mr_trace "detect line 1=$(cat "${FN_MSG}" | grep "Hash.Target")"
        BSSID=$(cat "${FN_MSG}" | grep "Hash.Target" | awk -F\( '{print $2}' | awk      '{print $1}')
        ESSID=$(cat "${FN_MSG}" | grep "Hash.Target" | awk -F:  '{print $2}' | awk -F\( '{print $1}')
        grep "All hashes found in potfile!" "${FN_MSG}" 2>&1 > /dev/null
        if [ "$?" = "0" ]; then
            RES=$(${EXEC_HASHCAT} -m 2500 "input/${PARAM_INPUT_FILE}" --show)
            echo -e "outwpa\tinput/${PARAM_INPUT_FILE}\tfound\t${RES}"
            mr_trace "pre-found wpa: ${RES}"
            return
        fi
        rm -f "${FN_MSG}"
        ;;

    *-hs.cap)
        FN_MSG="/tmp/app-wpapw-msg-$(uuidgen)"
        local PREFIX1=$(generate_prefix_from_filename "`basename ${PARAM_INPUT_FILE}`" )
        FN_HCCAP="${HDFF_DN_OUTPUT}/tmp-hccap-${PREFIX1}"
        $MYEXEC ${EXEC_AIRCRACK} -J "${FN_HCCAP}" "input/${PARAM_INPUT_FILE}" > "${FN_MSG}"
        FN_HCCAP="${FN_HCCAP}.hccap"
        # essid example:
        # [*] ESSID (length: 12): This is my ESSID!
        # bssid example:
        # [*] BSSID: 00:11:22:33:44:55
        mr_trace "detect line 2= $(cat "${FN_MSG}" | grep "*] ESSID (length:")"
        mr_trace "detect line 2= $(cat "${FN_MSG}" | grep "*] BSSID:"        )"
        ESSID=$(cat "${FN_MSG}" | grep "*] ESSID (length:" | awk -F: '{print $3}')
        BSSID=$(cat "${FN_MSG}" | grep "*] BSSID:"         | awk     '{print $3}')
        rm -f "${FN_MSG}"
        ;;

    *.cap)
        FN_MSG="/tmp/app-wpapw-msg-$(uuidgen)"
        local PREFIX1=$(generate_prefix_from_filename "`basename ${PARAM_INPUT_FILE}`" )
        FN_HCCAP="${HDFF_DN_OUTPUT}/tmp-hccap-${PREFIX1}"
        FN_CAP="${HDFF_DN_OUTPUT}/tmp-cap-${PREFIX1}"
        $MYEXEC ${EXEC_WPACLEAN} "${FN_CAP}" "input/${PARAM_INPUT_FILE}" > /dev/null
        $MYEXEC ${EXEC_AIRCRACK} -J "${FN_HCCAP}" "${FN_CAP}" > "${FN_MSG}"
        FN_HCCAP="${FN_HCCAP}.hccap"
        # essid example:
        # [*] ESSID (length: 12): This is my ESSID!
        # bssid example:
        # [*] BSSID: 00:11:22:33:44:55
        mr_trace "detect line 3= $(cat "${FN_MSG}" | grep "*] ESSID (length:")"
        mr_trace "detect line 3= $(cat "${FN_MSG}" | grep "*] BSSID:"        )"
        ESSID=$(cat "${FN_MSG}" | grep "*] ESSID (length:" | awk -F: '{print $3}')
        BSSID=$(cat "${FN_MSG}" | grep "*] BSSID:"         | awk     '{print $3}')
        rm -f "${FN_MSG}"
        ;;

    *)
        mr_trace "Warning: unknown file 'input/${PARAM_INPUT_FILE}'."
        ;;
    esac
    mr_trace "BSSID=${BSSID}; ESSID=${ESSID};"

    if [ "${BSSID}" = "" ]; then
        mr_trace "Warning: not found BSSID for file ${FN_HCCAP}"
        mp_notify_child_exit ${PARAM_SESSION_ID}
        return
    fi

    # for each word list
    # HDFF_WORDLISTS
    if [ ! "${HDFF_WORDLISTS}" = "" ]; then
        IFS=':'; array=($HDFF_WORDLISTS)
        for i in "${!array[@]}"; do
            FN_DIC="${array[i]}"
            echo -e "wpa\t${FN_HCCAP}\tdictionary\t${FN_DIC}"
        done
    fi

    # continue to parse the ESSID
    if [ "${HDFF_USE_MASK}" = "1" ]; then
        # HDFF_SIZE_SEGMENT
        if [ "${HDFF_SIZE_SEGMENT}" = "" ]; then
            HDFF_SIZE_SEGMENT=10000000
        fi
        mr_trace "HDFF_SIZE_SEGMENT=${HDFF_SIZE_SEGMENT};"

        # calculate the number of digit of the suffix base 10
        NUMLAST10=0
        V=1
        while (( $V < $HDFF_SIZE_SEGMENT )); do
            V=$(( $V * 10 ))
            NUMLAST10=$(( $NUMLAST10 + 1 ))
        done

        # the number of the prefix for 10 digital base 10 values
        MAX_PREFIX_B10_10=1
        C=$(( 10 - NUMLAST10 ))
        while (( $C > 0 )); do
            MAX_PREFIX_B10_10=$(( MAX_PREFIX_B10_10 * 10 ))
            C=$(( C - 1 ))
        done
        mr_trace "NUMLAST10=${NUMLAST10}; MAX_PREFIX_B10_10=${MAX_PREFIX_B10_10};"

        # ATTXXX
        # 10 digits of 0-9 (17 hrs)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*ATT[0-9]{3}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "ATTXXX(${ESSID})"
if [ 1 = 1 ]; then
            #mr_trace generate_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 10 "0123456789" "wpa\t${FN_HCCAP}\tmask\t"
            generate_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 10 "0123456789" "wpa\t${FN_HCCAP}\tmask\t"
            #generate_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 4 "0123456789" "wpa\t${FN_HCCAP}\tmask\t" # debug
            #MASK="91132055?d?d"; echo -e "wpa\t${FN_HCCAP}\tmask\t${MASK}" # debug
else
            C=0
            while (( $C < $MAX_PREFIX_B10_10 )); do
                # N -- number of total digitals
                # S -- the length of suffix
                # V -- the index value
                MASK=$( echo | awk -v N=10 -v S=${NUMLAST10} -v V=${C} '{ suffix=""; for(i=0;i<S;i++) {suffix=suffix "?d";} fmt="%0" (N-S) "d%s\n"; printf(fmt,V,suffix);}' )
                C=$(( C + 1 ))
                mr_trace -e "wpa\t${FN_HCCAP}\tmask\t${MASK}"
                echo -e "wpa\t${FN_HCCAP}\tmask\t${MASK}"
            done
fi
        fi

        # 2WIREXXX
        # 10 digits of 0-9 (17 hrs)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*2WIRE[0-9]{3}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "2WIREXXX(${ESSID})"
            C=0
            while (( $C < $MAX_PREFIX_B10_10 )); do
                MASK=$( echo | awk -v N=10 -v S=${NUMLAST10} -v V=${C} '{ suffix=""; for(i=0;i<S;i++) {suffix=suffix "?d";} fmt="%0" (N-S) "d%s\n"; printf(fmt,V,suffix);}' )
                C=$(( C + 1 ))
                echo -e "wpa\t${FN_HCCAP}\tmask\t${MASK}"
            done
        fi

        # NETGEARXX
        # Adjective + Noun + 3 numbers (dict)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*NETGEAR[0-9]{2}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "NETGEARXX(${ESSID})"
        fi

        # 3Wireless-Modem-XXXX
        # 8 digits of 0-9 A-F, and the first 4 digits are the same as the 4 digits on the SSID!
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*3Wireless-Modem-[0-9]{4}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "3Wireless-Modem-XXXX(${ESSID})"
            F4=$( echo ${ESSID} | awk -F- '{print $3}' )
            MASK="-1 ?dABCDEF ${F4}?1?1?1?1"
            echo -e "wpa\t${FN_HCCAP}\tmask\t${MASK}"
        fi

        # BOLT!SUPER 4G-XXXX
        # 8 digits, 4 numbers + Last 4 of SSID (1 sec)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*BOLT!SUPER 4G-[0-9A-F]{6}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "BOLT!SUPER 4G-XXXX(${ESSID})"
            L4=$( echo ${ESSID} | awk -F- '{print $3}' )
            MASK="?d?d?d?d${L4}"
            echo -e "wpa\t${FN_HCCAP}\tmask\t${MASK}"
        fi

        # belkin.xxx
        # 8 digits of 2-9 a-f (2.5 hrs)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*belkin.[0-9a-f]{3}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "belkin.xxx(${ESSID})"
            generate_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "23456789abcdef" "wpa\t${FN_HCCAP}\tmask\t"
        fi

        # belkin.xxxx
        # 8 digits of 0-9 A-F (7.5 hrs)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*belkin.[0-9a-f]{4}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "belkin.xxxx(${ESSID})"
            generate_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "0123456789ABCDEF" "wpa\t${FN_HCCAP}\tmask\t"
        fi

        # Belkin.XXXX
        # 8 digits of 0-9 A-F (7.5 hrs)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*Belkin.[0-9A-F]{4}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "Belkin.XXXX(${ESSID})"
            generate_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "0123456789ABCDEF" "wpa\t${FN_HCCAP}\tmask\t"
        fi

        # Belkin_XXXXXX
        # 8 digits of 0-9 A-F (7.5 hrs)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*Belkin_[0-9A-F]{6}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "Belkin_XXXXXX(${ESSID})"
            generate_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "0123456789ABCDEF" "wpa\t${FN_HCCAP}\tmask\t"
        fi

        # Orange-0a0aa0
        # 8 digits of 0-9 a-f (7.5 hrs)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*Orange-[0-9a-f]{6}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "Orange-0a0aa0(${ESSID})"
            generate_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "0123456789abcdef" "wpa\t${FN_HCCAP}\tmask\t"
        fi

        # Orange-XXXX
        # 8 digits of 2345679 ACEF (23 min)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*Orange-[0-9a-f]{6}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "Orange-XXXX(${ESSID})"
            generate_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "2345679ACEF" "wpa\t${FN_HCCAP}\tmask\t"
        fi

    fi

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

#####################################################################
## @fn worker_create_exec_config()
## @brief create exec directories
## @param session_id the session id
## @param config_file config file
##
worker_create_exec_config() {
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

#<command> <input_file>
# wpa "/path/to/test-hs.hccap"
while IFS=$'\t' read -r MR_CMD MR_CONFIG_FILE ; do
    FN_CONFIG_FILE=$( unquote_filename "${MR_CONFIG_FILE}" )

    mr_trace "1 HDFF_FUNCTION=${HDFF_FUNCTION}; FN_CONFIG_FILE='${FN_CONFIG_FILE}'"

    mr_trace received: "${MR_CMD}\t${MR_CONFIG_FILE}"

    case "${MR_CMD}" in
    config)
        #worker_create_exec_config "$(mp_get_session_id)" "${MR_CONFIG_FILE}" &
        #PID_CHILD=$!
        #mp_add_child_check_wait ${PID_CHILD}
        # ignore
        mr_trace "ignore config file: '${FN_CONFIG_FILE}'"
        ;;

    wpa)
        worker_create_wpa_config "$(mp_get_session_id)" "${FN_CONFIG_FILE}" &
        PID_CHILD=$!
        mp_add_child_check_wait ${PID_CHILD}
        ;;

    *)
        mr_trace "Warning: unknown mr command '${MR_CMD}'."
        ;;
    esac
done

mp_wait_all_children
