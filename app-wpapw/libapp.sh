#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief the library for the app
## @author Yunhui Fu <yhfudev@gmail.com>
## @copyright GPL v3.0 or later
## @version 1
##
#####################################################################

#config binary for map/reduce task
# <config line> format: "<map>,<reduce>,<# of output key>,<# of partition key>,<callback end function>"
#   java streaming argument 'stream.num.map.output.key.fields' is map to '# of output key'
#   java streaming argument 'num.key.fields.for.partition' is map to '# of partition key'
#   stream.num.map.output.key.fields >= num.key.fields.for.partition
#   'callback end function' is called at the end of function
#
# config line example: "e1map.sh,e1red.sh,6,5,cb_end_stage1"
LIST_MAPREDUCE_WORK="e1map.sh,,3,2, e2map.sh,,2,1,"


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
#DN_EXEC=$(dirname $(my_getpath "$0") )
#####################################################################
EXEC_HASHCAT=$(which "hashcat")
EXEC_AIRCRACK=$(which "aircrack-ng")
EXEC_PYRIT=$(which "pyrit")
EXEC_WPACLEAN=$(which "wpaclean")

FN_CONF_HASHCAT="input/config-wpapw.conf"

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
## @fn generate_default_wpapw_config()
## @brief generate a default config file for wpapw
## @param fn the config file name
##
generate_default_wpapw_config() {
    local PARAM_FN_CONFIG=$1
    shift
    cat << EOF > "${PARAM_FN_CONFIG}"
# the config file for the application

# the word list
#HDFF_WORDLISTS=wl1.txt:wl2.txt
HDFF_WORDLISTS=

# the rule list for the hashcat
#HDFF_RULELISTS=best64:combinator
HDFF_RULELISTS=

# the number of entries for each segment of wordlist/pattern
# default: 10m
HDFF_SIZE_SEGMENT=10000000

# if we use mask, such as ?d?d?d?d?d for hashcat
HDFF_USE_MASK=1
EOF
}

#####################################################################
mr_trace "DN_TOP=${DN_TOP}, DN_EXEC=${DN_EXEC}, FN_CONF_SYS=${FN_CONF_SYS}"

RET0=$(is_file_or_dir "${FN_CONF_SYS}")
if [ ! "$RET0" = "f" ]; then
    echo -e "debug\t$(hostname)\tgenerated_config\t${FN_CONF_SYS}"
    mr_trace "Warning: not found config file '${FN_CONF_SYS}'!"
    mr_trace "generating new config file '${FN_CONF_SYS}' ..."
    generate_default_config | save_file "${FN_CONF_SYS}"
fi
FN_TMP_1m="/tmp/config-$(uuidgen)"
copy_file "${FN_CONF_SYS}" "${FN_TMP_1m}" 1>&2
read_config_file "${FN_TMP_1m}"

FN_TMP_1m="/tmp/config-$(uuidgen)"

RET0=$(is_file_or_dir "${FN_CONF_HASHCAT}")
if [ ! "$RET0" = "f" ]; then
    mr_trace "Warning: not found config file '${FN_CONF_HASHCAT}'!"

    # generate default application configs?
    generate_default_wpapw_config "${FN_TMP_1m}"

else
    copy_file "${FN_CONF_HASHCAT}" "${FN_TMP_1m}" 1>&2
fi
read_config_file "${FN_TMP_1m}"

if [ $(is_local "${FN_TMP_1m}") = l ]; then
    #cat_file "${FN_TMP_1m}" | awk -v P=debug -v H=$(hostname) '{print P "\t" H "\ttmpconfig____"$0}'
    rm_f_dir "${FN_TMP_1m}" 1>&2
else
    echo -e "debug\tError_file_is_not_local\t${FN_TMP_1m}"
fi
check_global_config

mr_trace "DN_TOP=${DN_TOP}, DN_EXEC=${DN_EXEC}, FN_CONF_SYS=${FN_CONF_SYS}"
mr_trace "HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"
#echo -e "debug\tFN_CONF_SYS=${FN_CONF_SYS},FN_TMP=${FN_TMP_1m},HDFF_FN_TAR_MRNATIVE=${HDFF_FN_TAR_MRNATIVE}"

DN_DATATMP="${HDFF_DN_SCRATCH}"


## @fn extrace_binary()
## @brief untar the app binary
## @param fn_tar the file name
##
## untar the app binary from the file specified by HDFF_PATHTO_TAR_APP
extrace_binary() {
    PARAM_FN_TAR=$1
    shift

    local RET=$(is_local "${HDFF_DN_BIN}")
    if [ ! "${RET}" = "l" ]; then
        mr_trace "Error: binary is not local dir: ${HDFF_DN_BIN}"
        echo -e "error-extractbin\tnot-local-dir\t${HDFF_DN_BIN}"
        exit 1
    fi
    mr_trace "extract ${PARAM_FN_TAR} to dir ${HDFF_DN_BIN} ..."
    extract_file "${PARAM_FN_TAR}" ${HDFF_DN_BIN} >/dev/null 2>&1
    P=$(echo $(basename "${PARAM_FN_TAR}") | awk -F. '{name=$1; for (i=2; i + 1 < NF; i ++) name=name "." $i } END {print name}')

    #DN=$(ls ${HDFF_DN_BIN}/${P}* | head -n 1)
    mr_trace "DN1=$(ls ${HDFF_DN_BIN}/${P}* | head -n 1)"
    DN="${HDFF_DN_BIN}/${P}"
    mr_trace "DN=$DN"
    echo $DN
}

## @fn libapp_prepare_app_binary()
## @brief setup some environment variable for application
##
## to setup some environment variable for application
## and extract the apllication binaries and data if the config HDFF_PATHTO_TAR_APP exist
## (MUST be implemented)
libapp_prepare_app_binary() {
    if [ "${HDFF_PATHTO_TAR_APP}" = "" ]; then
        # detect the application execuable
        EXEC_HASHCAT="$(my_getpath "${DN_TOP}/3rd/aircrack-bin/usr/bin/hashcat")"
        mr_trace "try detect hashcat 1: ${EXEC_HASHCAT}"
        #echo -e "error-prepapp\ttry-get-file\t${DN_TOP}/3rd/aircrack-bin/usr/bin/hashcat"
    else
        local DN2=$(extrace_binary "${HDFF_PATHTO_TAR_APP}")
        EXEC_HASHCAT="$(my_getpath "${DN2}/usr/bin/hashcat")"
        mr_trace "try detect hashcat 2: ${EXEC_HASHCAT}"
        if [ ! -x "${EXEC_HASHCAT}" ]; then
            EXEC_HASHCAT="$(my_getpath "${DN2}/hashcat-git/hashcat")"
            mr_trace "try detect hashcat 3: ${EXEC_HASHCAT}"
        fi
        #echo -e "error-prepapp\ttry-get-file\t${DN2}/usr/bin/hashcat"
        if [ ! -x "${EXEC_HASHCAT}" ]; then
            EXEC_HASHCAT="$(dirname ${DN2})/aircrack-git-x86_64/usr/bin/hashcat"
            mr_trace "try detect hashcat 3: ${EXEC_HASHCAT}"
            #echo -e "error-prepapp\ttry-get-file\t${EXEC_HASHCAT}"
        fi
        if [ ! -x "${EXEC_HASHCAT}" ]; then
            EXEC_HASHCAT="${HDFF_DN_BIN}/aircrack-git-x86_64/usr/bin/hashcat"
            mr_trace "try detect hashcat 4: ${EXEC_HASHCAT}"
            #echo -e "error-prepapp\ttry-get-file\t${EXEC_HASHCAT}"
        fi
        if [ ! -x "${EXEC_HASHCAT}" ]; then
            EXEC_HASHCAT="$(dirname ${HDFF_PATHTO_TAR_APP})/aircrack-git-x86_64/usr/bin/hashcat"
            mr_trace "try detect hashcat 5: ${EXEC_HASHCAT}"
            #echo -e "error-prepapp\ttry-get-file\t${EXEC_HASHCAT}"
        fi
    fi

    lst_app_dirs=(
        "/home/$USER/aircrack-bin/usr/bin/hashcat"
              "$HOME/aircrack-bin/usr/bin/hashcat"
        "/home/$USER/software/bin/aircrack-bin/bin/hashcat"
              "$HOME/software/bin/aircrack-bin/bin/hashcat"
        "/home/$USER/aircrack-git-x86_64/usr/bin/hashcat"
              "$HOME/aircrack-git-x86_64/usr/bin/hashcat"
        "/home/$USER/working/vmshare/ns2docsis-1.0-workingspace/aircrack-git-x86_64/usr/bin/hashcat"
              "$HOME/working/vmshare/ns2docsis-1.0-workingspace/aircrack-git-x86_64/usr/bin/hashcat"
        "/home/$USER/bin/hashcat"
              "$HOME/bin/hashcat"
        )
    if [ ! -x "${EXEC_HASHCAT}" ]; then
        CNT=0
        while [[ ${CNT} < ${#lst_app_dirs[*]} ]] ; do
            mr_trace "try detect hashcat lst_app_dirs(${CNT}):" ${lst_app_dirs[${CNT}]}
            if [ -x "${lst_app_dirs[${CNT}]}" ]; then
                EXEC_HASHCAT=${lst_app_dirs[${CNT}]}
                mr_trace "found: $EXEC_HASHCAT"
                detect_gawk_from "$(dirname ${EXEC_HASHCAT})"
                detect_gnuplot_from "$(dirname ${EXEC_HASHCAT})"
                break
            fi
            CNT=$(( $CNT + 1 ))
        done
    fi
    if [ ! -x "${EXEC_HASHCAT}" ]; then
        EXEC_HASHCAT=$(which hashcat)
        mr_trace "try detect hashcat 13: ${EXEC_HASHCAT}"
    fi
    mr_trace "EXEC_HASHCAT=${EXEC_HASHCAT}"
    if [ -x "${EXEC_HASHCAT}" ]; then
        detect_gawk_from    "$(dirname ${EXEC_HASHCAT})"
        detect_gnuplot_from "$(dirname ${EXEC_HASHCAT})"
        if [ "$?" = "0" ]; then
            GNUPLOT_PS_DIR="$(dirname ${EXEC_PLOT})/../share/gnuplot/5.0/PostScript/"
            export GNUPLOT_PS_DIR="$(my_getpath "${GNUPLOT_PS_DIR}")"
            GNUPLOT_LIB="$(dirname ${EXEC_PLOT})/../share/gnuplot/5.0/"
            export GNUPLOT_LIB="$(my_getpath "${GNUPLOT_LIB}")"
            LD_LIBRARY_PATH="$(dirname ${EXEC_PLOT})/../lib"
            export LD_LIBRARY_PATH="$(my_getpath "${LD_LIBRARY_PATH}")"
        fi
    else
        mr_trace "Error: not found hashcat"
        echo -e "error-prepapp\tNOT-get-file\thashcat"
    fi

    #EXEC_AIRCRACK=`which aircrack-ng`
    if [ ! -x "${EXEC_AIRCRACK}" ]; then
        EXEC_AIRCRACK="$(dirname ${EXEC_HASHCAT})/aircrack-ng"
        mr_trace "try detect aircrack-ng 1: ${EXEC_AIRCRACK}"
    fi
    if [ ! -x "${EXEC_AIRCRACK}" ]; then
        EXEC_AIRCRACK=$(which aircrack-ng)
        mr_trace "try detect aircrack-ng 2: ${EXEC_AIRCRACK}"
    fi
    if [ ! -x "${EXEC_AIRCRACK}" ]; then
        mr_trace "Error: not found aircrack-ng"
        echo -e "error-prepapp\tNOT-get-file\taircrack-ng"
    fi

if [ 0 = 1 ]; then
    #EXEC_PYRIT=`which pyrit`
    if [ ! -x "${EXEC_PYRIT}" ]; then
        EXEC_PYRIT="$(dirname ${EXEC_HASHCAT})/pyrit"
        mr_trace "try detect pyrit 1: ${EXEC_PYRIT}"
    fi
    if [ ! -x "${EXEC_PYRIT}" ]; then
        EXEC_PYRIT=$(which pyrit)
        mr_trace "try detect pyrit 2: ${EXEC_PYRIT}"
    fi
    if [ ! -x "${EXEC_PYRIT}" ]; then
        mr_trace "Error: not found pyrit"
        echo -e "error-prepapp\tNOT-get-file\tpyrit"
    fi
fi

    echo -e "env\thashcat=${EXEC_HASHCAT}\tgawk=${EXEC_AWK}\tplot=${EXEC_PLOT}\tlib=${GNUPLOT_LIB}\tpsdir=${GNUPLOT_PS_DIR}\tLD=${LD_LIBRARY_PATH}"
}

## @fn libapp_prepare_mrnative_binary()
## @brief untar the mrnative binary (this package)
##
## untar the mrnative binary from the file specified by HDFF_PATHTO_TAR_MRNATIVE
## return the path to the untar files
## (MUST be implemented)
libapp_prepare_mrnative_binary() {
    if [ "${HDFF_PATHTO_TAR_MRNATIVE}" = "" ]; then
        # detect the marnative dir
        mr_trace "Error: not found mrnative file '${HDFF_PATHTO_TAR_MRNATIVE}'"
        #echo -e "error-prepnative\tnot-get-tarfile\tHDFF_PATHTO_TAR_MRNATIVE=${HDFF_PATHTO_TAR_MRNATIVE}"
    else
        local DN2=$(extrace_binary "${HDFF_PATHTO_TAR_MRNATIVE}")
        if [ -d "${DN2}" ] ; then
            DN_TOP=$(my_getpath "${DN2}")
            mr_trace "[DBG] set top dir to '${DN_TOP}'"
        else
            mr_trace "Error: not found mrnative top dir '${DN2}'"
            echo -e "error-prepnative\tnot-get-dir\t${DN2}"
        fi
    fi
}

#####################################################################
# functions for generating input lines for cracking

## @fn output_custom_mask_lines()
## @brief generate the WPA crack mask lines for hashcat
## @param num_segment the number of words in a segment
## @param max_num the length of the string
## @param charset the charset string, such as 1234567890ABCDEF
## @param line_prefix the prefix line with the mask, such as "wpa\t${FN_HCCAP}\tmask\t"
##
output_custom_mask_lines() {
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

## @fn output_capture_crack_with_config()
## @brief create command lines for WPA crack
## @param config_file the config file for crack, such as config-wpapw.conf
## @param capture_file .cap, or .hccap file
##
output_capture_crack_with_config() {
    local PARAM_CONFIG_FILE="$1"
    shift
    local PARAM_CAPTURE_FILE="$1"
    shift

    # read the application's config file
    RET0=$(is_file_or_dir "${PARAM_CONFIG_FILE}")
    if [ "$RET0" = "f" ]; then
        read_config_file "${PARAM_CONFIG_FILE}"
    fi

    local RET=0
    RET=$(is_file_or_dir "input/${PARAM_CAPTURE_FILE}")
    if [ ! "${RET}" = "f" ]; then
        mr_trace "Error: not found input file: input/$PARAM_CAPTURE_FILE"
        return
    fi

    mr_trace "infunc create wpa config: PARAM_CAPTURE_FILE=${PARAM_CAPTURE_FILE}"
    BSSID=
    ESSID=
    FN_HCCAP="input/${PARAM_CAPTURE_FILE}"
    # get the name,bssid of AP
    case "${PARAM_CAPTURE_FILE}" in
    *-hs.hccap)
        FN_MSG="/tmp/app-wpapw-msg-$(uuidgen)"
        FN_HCCAP="input/${PARAM_CAPTURE_FILE}"
        $MYEXEC ${EXEC_HASHCAT} -m 2500 "input/${PARAM_CAPTURE_FILE}" -a 3 1234567890 > "${FN_MSG}"
        # example:
        #Hash.Target......: This is my ESSID! (00:11:22:33:44:55 <-> 66:77:88:99:aa:bb)
        mr_trace "detect line 1=$(cat "${FN_MSG}" | grep "Hash.Target")"
        BSSID=$(cat "${FN_MSG}" | grep "Hash.Target" | awk -F\( '{print $2}' | awk      '{print $1}')
        ESSID=$(cat "${FN_MSG}" | grep "Hash.Target" | awk -F:  '{print $2}' | awk -F\( '{print $1}')
        grep "All hashes found in potfile!" "${FN_MSG}" 2>&1 > /dev/null
        if [ "$?" = "0" ]; then
            RES=$(${EXEC_HASHCAT} -m 2500 "input/${PARAM_CAPTURE_FILE}" --show)
            echo -e "outwpa\tinput/${PARAM_CAPTURE_FILE}\tfound\t${RES}"
            mr_trace "pre-found wpa: ${RES}"
            return
        fi
        rm -f "${FN_MSG}"
        ;;

    *-hs.cap)
        FN_MSG="/tmp/app-wpapw-msg-$(uuidgen)"
        local PREFIX1=$(generate_prefix_from_filename "`basename ${PARAM_CAPTURE_FILE}`" )
        FN_HCCAP="${HDFF_DN_OUTPUT}/tmp-hccap-${PREFIX1}"
        $MYEXEC ${EXEC_AIRCRACK} -J "${FN_HCCAP}" "input/${PARAM_CAPTURE_FILE}" > "${FN_MSG}"
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
        local PREFIX1=$(generate_prefix_from_filename "`basename ${PARAM_CAPTURE_FILE}`" )
        FN_HCCAP="${HDFF_DN_OUTPUT}/tmp-hccap-${PREFIX1}"
        FN_CAP="${HDFF_DN_OUTPUT}/tmp-cap-${PREFIX1}"
        $MYEXEC ${EXEC_WPACLEAN} "${FN_CAP}" "input/${PARAM_CAPTURE_FILE}" > /dev/null
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
        mr_trace "Warning: unknown file 'input/${PARAM_CAPTURE_FILE}'."
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
            echo -e "wpa\t${FN_HCCAP}\tdictionary\tinput/${FN_DIC}"
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
            #mr_trace output_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 10 "0123456789" "wpa\t${FN_HCCAP}\tmask\t"
            output_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 10 "0123456789" "wpa\t${FN_HCCAP}\tmask\t"
            #output_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 4 "0123456789" "wpa\t${FN_HCCAP}\tmask\t" # debug
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
            output_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "23456789abcdef" "wpa\t${FN_HCCAP}\tmask\t"
        fi

        # belkin.xxxx
        # 8 digits of 0-9 A-F (7.5 hrs)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*belkin.[0-9a-f]{4}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "belkin.xxxx(${ESSID})"
            output_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "0123456789ABCDEF" "wpa\t${FN_HCCAP}\tmask\t"
        fi

        # Belkin.XXXX
        # 8 digits of 0-9 A-F (7.5 hrs)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*Belkin.[0-9A-F]{4}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "Belkin.XXXX(${ESSID})"
            output_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "0123456789ABCDEF" "wpa\t${FN_HCCAP}\tmask\t"
        fi

        # Belkin_XXXXXX
        # 8 digits of 0-9 A-F (7.5 hrs)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*Belkin_[0-9A-F]{6}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "Belkin_XXXXXX(${ESSID})"
            output_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "0123456789ABCDEF" "wpa\t${FN_HCCAP}\tmask\t"
        fi

        # Orange-0a0aa0
        # 8 digits of 0-9 a-f (7.5 hrs)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*Orange-[0-9a-f]{6}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "Orange-0a0aa0(${ESSID})"
            output_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "0123456789abcdef" "wpa\t${FN_HCCAP}\tmask\t"
        fi

        # Orange-XXXX
        # 8 digits of 2345679 ACEF (23 min)
        OUT=$(echo ${ESSID} | awk '/[[:space:]]*Orange-[0-9a-f]{6}[[:space:]]*/{print $0}')
        if [ ! "${OUT}" = "" ]; then
            mr_trace "Orange-XXXX(${ESSID})"
            output_custom_mask_lines "${HDFF_SIZE_SEGMENT}" 8 "2345679ACEF" "wpa\t${FN_HCCAP}\tmask\t"
        fi

    fi
}


## @fn libapp_get_tasks_number_from_config()
## @brief get number of simulation tasks from a config file
## @param fn_config the config file name
##
## (MUST be implemented) for run-hadooppbs.sh
libapp_get_tasks_number_from_config() {
    local PARAM_FN_CONFIG=$1
    shift

    mr_trace "find ${PARAM_FN_CONFIG} ..."
    find_file "${DN_EXEC}/input" -maxdepth 1 -name "input*" \
        | (TASKS=0;
        while read libapp_get_tasks_number_from_config_tmp_a; do
            A=$(cat "$libapp_get_tasks_number_from_config_tmp_a" | \
                    (B=0; while IFS=$'\t' read -r MR_CMD MR_CAPTURE_FILE ; do
                        FN_CAPTURE_FILE=$( unquote_filename "${MR_CAPTURE_FILE}" )
                        mr_trace "process line: '${MR_CMD} ${MR_CAPTURE_FILE}'"
                        case "${MR_CMD}" in
                        wpa)
                            RET1=$(output_capture_crack_with_config "${FN_CONF_HASHCAT}" "${FN_CAPTURE_FILE}" | wc -l)
                            mr_trace "got #=$RET1 for '${FN_CAPTURE_FILE}' with config file '${FN_CONF_HASHCAT}'"
                            B=$(( $B + $RET1 ))
                            ;;
                        esac
                    done;
                    echo $B)
                )
            TASKS=$(( $TASKS + $A ))
            mr_trace "libapp_get_tasks_number_from_config got $A cores for file '$libapp_get_tasks_number_from_config_tmp_a'"
        done;
        echo $TASKS)
}

#####################################################################

## @fn libapp_generate_script_4hadoop()
## @brief generate scripts for Hadoop environment
## @param orig the path to the app
## @param output the generated script file name
##
## generate scripts for Hadoop environment, because there's no PATH env in it
## (MUST be implemented)
libapp_generate_script_4hadoop() {
    local PARAM_ORIG="$1"
    shift
    local PARAM_OUTPUT="$1"
    shift

    local DN_FILE9=$(dirname "${PARAM_ORIG}")
    local DN_EXEOUT9=$(dirname "${PARAM_OUTPUT}")

    local RET=
    RET=$(is_file_or_dir "${DN_EXEOUT9}")
    if [ ! "${RET}" = "d" ]; then
        make_dir "${DN_EXEOUT9}"
        RET=$(is_file_or_dir "${DN_EXEOUT9}")
        if [ ! "${RET}" = "d" ]; then mr_trace "Error in mkdir $DN_EXEOUT9"; fi
    fi

    rm_f_dir "${PARAM_OUTPUT}"
    mr_trace "generating ${PARAM_OUTPUT} ..."
    echo '#!/bin/bash'                      | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC_4HADOOP=${DN_EXEC}"       | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP_4HADOOP=${DN_TOP}"         | save_file "${PARAM_OUTPUT}"
    echo "FN_CONF_SYS_4HADOOP=${FN_CONF_SYS}" | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC=${DN_EXEC}"               | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP=${DN_TOP}"                 | save_file "${PARAM_OUTPUT}"
    echo "FN_CONF_SYS=${FN_CONF_SYS}"       | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/bin/mod-setenv-hadoop.sh" | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libbash.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libshrt.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libfs.sh"       | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libplot.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libconfig.sh"   | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_FILE9}/libapp.sh"        | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC_4HADOOP=${DN_EXEC}"       | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP_4HADOOP=${DN_TOP}"         | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC=${DN_EXEC}"               | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP=${DN_TOP}"                 | save_file "${PARAM_OUTPUT}"
    cat_file "${PARAM_ORIG}"    \
        | grep -v "libbash.sh"  \
        | grep -v "libshrt.sh"  \
        | grep -v "libfs.sh"    \
        | grep -v "libplot.sh"  \
        | grep -v "libconfig.sh"    \
        | grep -v "libns2figures.sh" \
        | grep -v "libapp.sh"   \
        | sed -e "s|EXEC_HASHCAT=.*$|EXEC_HASHCAT=$(which hashcat)|" \
        | save_file "${PARAM_OUTPUT}"
}


## @fn libapp_prepare_execution_config()
## @brief generate scripts for all of the settings
## @param command the command
## @param fn_config_proj the config file of the application
##
## my_getpath, DN_EXEC, HDFF_DN_OUTPUT, should be defined before call this function
## HDFF_DN_SCRATCH should be in global config file (mrsystem.conf)
## PREFIX, LIST_NODE_NUM, LIST_TYPES, LIST_SCHEDULERS should be in the config file passed by argument
## (MUST be implemented)
libapp_prepare_execution_config() {
    local PARAM_COMMAND=$1
    shift
    local PARAM_FN_CONFIG_PROJ=$1
    shift

    local FN_TMP1="/tmp/config-$(uuidgen)"
    mr_trace "read proj config file: ${PARAM_FN_CONFIG_PROJ} ..."
    copy_file "${PARAM_FN_CONFIG_PROJ}" "${FN_TMP1}" > /dev/null 2>&1
    read_config_file "${FN_TMP1}"
    rm_f_dir "${FN_TMP1}" > /dev/null 2>&1

    mr_trace "parse the config file, HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"

    DN_TMP_CREATECONF="${HDFF_DN_SCRATCH}/tmp-createconf-$(uuidgen)"
    rm_f_dir "${DN_TMP_CREATECONF}" >/dev/null 2>&1
    make_dir "${DN_TMP_CREATECONF}" >/dev/null 2>&1
    mr_trace "HDFF_WORDLISTS='${HDFF_WORDLISTS}'"
    mr_trace "HDFF_RULELISTS='${HDFF_RULELISTS}'"
    mr_trace "HDFF_SIZE_SEGMENT='${HDFF_SIZE_SEGMENT}'"
    mr_trace "HDFF_USE_MASK='${HDFF_USE_MASK}'"

    #rm_f_dir "${DN_TMP_CREATECONF}"

    mr_trace "DONE create config files"
}

#####################################################################
#HDFF_DN_SCRATCH="/dev/shm/$USER/"

# PARAM_DN_PARENT -- the parent dir for the data to be saved.
# PARAM_DN_TEST   -- the sub dir for the data, related dir name to PARAM_DN_PARENT
# PARAM_FN_CONFIG_PROJ -- the config file for this simulation
run_one_ns2 () {
    local PARAM_DN_PARENT=$1
    shift
    local PARAM_DN_TEST=$1
    shift
    local PARAM_FN_CONFIG_PROJ=$1
    shift

    # read in the config file for this test group
    # in this case, is to read the config for USE_MEDIUMPACKET
    local FN_TMP2="/tmp/config-$(uuidgen)"
    copy_file "${PARAM_FN_CONFIG_PROJ}" "${FN_TMP2}" > /dev/null 2>&1
    read_config_file "${FN_TMP2}"
    rm_f_dir "${FN_TMP2}" > /dev/null 2>&1

    # set the scratch dir, which is used to store temperary files.
    local RET=0

    local DN_WORKING="${PARAM_DN_PARENT}/${PARAM_DN_TEST}/"
    local FLG_USETMP=0
    RET=$(is_local "${PARAM_DN_PARENT}")
    if [ ! "${RET}" = "l" ]; then
        FLG_USETMP=1
    fi
    if [ ! "${HDFF_DN_SCRATCH}" = "" ]; then
        FLG_USETMP=1
    fi
    DN_ORIG2=$(pwd)
    if [ ! "${FLG_USETMP}" = "0" ]; then
        RET=$(is_local "${HDFF_DN_SCRATCH}")
        if [ ! "${RET}" = "l" ]; then
            mr_trace "Error in prepare the scratch dir: ${HDFF_DN_SCRATCH}"
            return
        fi

        DN_WORKING="${HDFF_DN_SCRATCH}/run-${PARAM_DN_TEST}-$(uuidgen)/"
        mkdir -p "${DN_WORKING}" > /dev/null 2>&1
        mr_trace "run ns2: copy from parent to working dir: ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/ --> ${DN_WORKING}/"
        #rsync -av --log-file "${PARAM_DN_PARENT}/rsync-log-runns2-copytemp-1.log" "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" "${DN_WORKING}/" 1>&2
        mr_trace "copy ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/*.tcl to ${DN_WORKING}/"
        find_file "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" -name "*.tcl" | while read a; do mr_trace "copy ${a} to ${DN_WORKING}/"; copy_file "$a" "${DN_WORKING}/" > /dev/null 2>&1; done
        mr_trace "copy ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/*.dat to ${DN_WORKING}/"
        find_file "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" -name "*.dat" | while read a; do mr_trace "copy ${a} to ${DN_WORKING}/"; copy_file "$a" "${DN_WORKING}/" > /dev/null 2>&1; done
        mr_trace "copy ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/*.sh to ${DN_WORKING}/"
        find_file "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" -name "*.sh" | while read a; do mr_trace "copy ${a} to ${DN_WORKING}/"; copy_file "$a" "${DN_WORKING}/" > /dev/null 2>&1; done
        RET=$?
        if [ ! "$RET" = "0" ]; then
            mr_trace "Error: copy temp dir: $PARAM_DN_TEST to ${DN_WORKING}/"
            return
        fi
        cd "${DN_WORKING}"
    else
        cd "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/"
    fi
    mr_trace "rm -f *.bin *.txt *.out out.* *.tr *.log tmp*"
    rm -f *.bin *.txt *.out out.* *.tr *.log tmp* > /dev/null 2>&1
    mr_trace ${EXEC_HASHCAT} ${FN_TCL} 1 "${PARAM_DN_TEST}" FILTER grep PFSCHE TO "${HDFF_FN_LOG}"
    if [ ! -x "${EXEC_HASHCAT}" ]; then
        mr_trace "Error: not correctly set ns2 env EXEC_HASHCAT=${EXEC_HASHCAT}, which ns=$(which ns)"
    else
        #${EXEC_HASHCAT} ${FN_TCL} 1 "${PARAM_DN_TEST}" 2>&1 | grep PFSCHE >> "${HDFF_FN_LOG}"
        mr_trace ${EXEC_HASHCAT} ${FN_TCL} 1 "${PARAM_DN_TEST}" TO "${HDFF_FN_LOG}"
        ${EXEC_HASHCAT} ${FN_TCL} 1 "${PARAM_DN_TEST}" >> "${HDFF_FN_LOG}"
    fi

    mr_trace "USE_MEDIUMPACKET='${USE_MEDIUMPACKET}'"
    if [ "${USE_MEDIUMPACKET}" = "1" ]; then
        if [ -f mediumpacket.out ]; then
            rm_f_dir mediumpacket.out.gz > /dev/null
            mr_trace "compressing mediumpacket.out ..."
            gzip mediumpacket.out > /dev/null 2>&1
        else
            mr_trace "Warning: not found mediumpacket.out."
        fi
    else
        mr_trace "Warning: remove mediumpacket.out*!"
        rm_f_dir mediumpacket.out* > /dev/null
    fi

    cd "${DN_ORIG2}"
    if [ ! "${FLG_USETMP}" = "0" ]; then
        mr_trace "run ns2: copy back from working to parent dir: ${DN_WORKING}/ --> ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/"
        #rsync -av  --log-file "${PARAM_DN_PARENT}/rsync-log-runns2-copyback-1-${PARAM_DN_TEST}.log" "${DN_WORKING}/" "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" 1>&2
        RET=$(copy_file "${DN_WORKING}/" "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/")
        if [ ! "$RET" = "0" ]; then
            mr_trace "Error: copy temp dir: ${DN_WORKING} to $PARAM_DN_TEST"
            return
        fi
        #rm_f_dir "${DN_WORKING}"
    fi
}

# parse the parameters and generate the requests for ploting figures
prepare_figure_commands_for_one_stats () {
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

    #${DN_PARENT}/plotfigns2.sh tpflow "${HDFF_DN_OUTPUT}/dataconf/" "${HDFF_DN_OUTPUT}/figures/" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"

    case $PARAM_TYPE in
    udp)
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"udp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    tcp)
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    has*)
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    udp+has*)
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"udp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    tcp+has*)
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    esac
}

# clean temperary files with file name prefix "tmp-"
clean_one_tcldir () {
    # the prefix of the test
    PARAM_DN_DEST=$1
    shift

    FLG_ERR=1
    if [ -d "${PARAM_DN_DEST}" ]; then
        FLG_ERR=0
        find_file "${PARAM_DN_DEST}" -name "tmp-*" | xargs -n 1 rm_f_dir
    fi

    if [ "${FLG_ERR}" = "1" ]; then
        echo -e "error-clean\t${DN_TEST}"
    fi
}

# check the throughput log file, if the log time reach to the pre-set end time.
# checked both for UDP and TCP packets, with file prefix CMTCPDS and CMUDPDS
# get the TIME_STOP from your config file
check_one_tcldir () {
    PARAM_FN_CONF=$1
    shift
    PARAM_DN_DEST=$1
    shift
    # output file save the failed directories
    PARAM_FN_LOG_ERROR=$1
    shift

    local FN_TMP3="/tmp/config-$(uuidgen)"
    copy_file "${PARAM_FN_CONF}" "${FN_TMP3}" > /dev/null 2>&1
    read_config_file "${FN_TMP3}"
    rm_f_dir "${FN_TMP3}" > /dev/null 2>&1

    FLG_ERR=1
    mr_trace "checking $(basename ${PARAM_DN_DEST}) ..."
    local RET
    RET=$(is_file_or_dir "${PARAM_DN_DEST}")
    if [ "${RET}" = "d" ]; then
        FLG_ERR=0
        FLG_NONE=1

        FN_TPFLOW="CMTCPDS*.out"
        mr_trace "checking tcp FN_TPFLOW=$FN_TPFLOW ..."
        #mr_trace "find_file '${PARAM_DN_DEST}' -name '${FN_TPFLOW}' ..."
        LST=$(find_file "${PARAM_DN_DEST}" -name "${FN_TPFLOW}" | sort)
        for i in $LST ; do
            FLG_NONE=0
            mr_trace "process flow throughput (tcp) $i ..."
            idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
            #mr_trace "curr dir=$(pwd), tail i=$i"
            TM1=$(tail_file "$i" -n 1 | awk '{print $1}')
            # we assume it done correctly if the time different is in 8 seconds
            if [ $(echo | awk -v A=$TM1 -v B=$TIME_STOP '{if (A + 8 < B) print 1; else print 0;}') = 1 ] ; then
                FLG_ERR=1
            fi
        done

        FN_TPFLOW="CMUDPDS*.out"
        mr_trace "checking udp FN_TPFLOW=$FN_TPFLOW ..."
        #mr_trace "find_file '${PARAM_DN_DEST}' -name '${FN_TPFLOW}' ..."
        LST=$(find_file "${PARAM_DN_DEST}" -name "${FN_TPFLOW}" | sort)
        for i in $LST ; do
            FLG_NONE=0
            mr_trace "process flow throughput (udp) $i ..."
            idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
            TM1=$(tail_file "$i" -n 1 | awk '{print $1}')
            if [ $(echo | awk -v A=$TM1 -v B=$TIME_STOP '{if (A + 5 < B) print 1; else print 0;}') = 1 ] ; then
                FLG_ERR=1
            fi
        done
        if [ "$FLG_NONE" = "1" ]; then
            FLG_ERR=1
        fi
    fi

    if [ "${FLG_ERR}" = "1" ]; then
        mr_trace "save ${PARAM_FN_LOG_ERROR}: ${PARAM_DN_DEST}"
        echo "${PARAM_DN_DEST}" >> "${PARAM_FN_LOG_ERROR}"
    fi
}

