#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief Run machine test using Map/Reduce paradigm -- Step 2 Map part
##
##   In this part, the script get the sw/hw config of the machines in the cluster
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
DN_TMP="/tmp/${USER}"
mkdir -p "${DN_TMP}"
FN_TMP="${DN_TMP}/config-$(uuidgen)"
mr_trace copy_file "${FN_CONF_SYS}" "${FN_TMP}"
cat_file "${FN_CONF_SYS}" | save_file "${FN_TMP}"
#cat_file "${FN_CONF_SYS}" | awk -v P=debug -v H=$(hostname) -v D=e1map_orig_catline___ '{print P "\t" H "\t" D "/" $0}'
#cat_file "${FN_TMP}" | awk -v P=debug -v H=$(hostname) -v D=e1map_copy_catline___ '{print P "\t" H "\t" D "/" $0}'
read_config_file "${FN_TMP}"

if [ $(is_local "${FN_TMP}") = l ]; then
    #cat_file "${FN_TMP}" | awk -v P=debug -v H=$(hostname) '{print P "\t" H "\ttmpconfig____"$0}'
    rm_f_dir "${FN_TMP}" > /dev/null 2>&1
else
    echo -e "debug\tError_file_is_not_local\t${FN_TMP}"
fi
check_global_config

#mr_trace "HDFF_NUM_CLONE=$HDFF_NUM_CLONE"
echo -e "debug\tFN_CONF_SYS=${FN_CONF_SYS},FN_TMP=${FN_TMP},HDFF_FN_TAR_MRNATIVE=${HDFF_FN_TAR_MRNATIVE}"

# remove the tmp files
rm_f_dir "hdfs:///tmp/tmp-*.gz"

#####################################################################
# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

# extract the mrnative, include the files in projtool/common which are used in setting ns2 TCL scripts
libapp_prepare_mrnative_binary
libapp_prepare_app_binary

#####################################################################
# check host config
worker_check_host0() {
    PARAM_SESSION_ID="$1"
    shift
    PARAM_CONFIG_FILE="$1"
    shift

    mr_trace "get info ..."

    # host id
    HOSTNAME=$(hostname)
    detect_os_type 1>&2
    echo -e "host-os\t$HOSTNAME\tostype=$OSTYPE,dist=$OSDIST,ver=$OSVERSION,name=$OSNAME"

    IPS=$(ip a | grep global | awk '{print $2}' | (b=""; while read a ; do if [ "$b" = "" ]; then b="$a" ; else b="$b,$a"; fi; done; echo $b))
    echo -e "host-ips\t$HOSTNAME\t$IPS"
   # get the mem
    MEM=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
    echo -e "memory-size\t$HOSTNAME\t$MEM"
    # get cpu
    CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
    DESC=$(cat /proc/cpuinfo | grep "model name" | sort | uniq | awk -F: '{print $2}')
    echo -e "cpu-cores\t$HOSTNAME\t$CORES"
    echo -e "cpu-desc\t$HOSTNAME\t$DESC"
    top -bn1 | grep Cpu | awk -v H=$HOSTNAME '{print "cpu-usage\t" H "\t" $1 "\t" $3}'

    # total, used, mount, dev
    df -h | grep -v Filesystem | awk -v H=$HOSTNAME 'BEGIN{c=0;}{print "host-disks\t" H "\t" c "\t" $2 "\t" $5 "\t" $6 "\t" $1; c++;}'
    lspci | grep controller | egrep -i 'vga|3d|2d' | awk -v H=$HOSTNAME 'BEGIN{c=0;}{print "cards\t" H "\t" c "\t" $0; c++;}'

    EXEC_HADOOP=$(which hadoop)
    echo -e "bin\t$HOSTNAME\thadoop\t$EXEC_HADOOP"
    echo -e "bin\t$HOSTNAME\tgawk\t$(which gawk)\t$(gawk --version | grep Awk)"
    echo -e "bin\t$HOSTNAME\tgnuplot\t$(which gnuplot)\t$(gnuplot --version)"
    echo -e "bin\t$HOSTNAME\tgrep\t$(which grep)\t$(grep --version | grep 'GNU grep')"
    echo -e "bin\t$HOSTNAME\tgzip\t$(which gnuplot)\t$(gzip --version | grep gzip)"
    echo -e "env\t$HOSTNAME\tUSER\t$USER\tme=${HDFF_USER}"
    echo -e "env\t$HOSTNAME\thdfs\t$HDFS_URL"

    SRC="/tmp/tmp-$(uuidgen).gz"
    DEST="hdfs://${SRC}"

    rm_f_dir "${DEST}" >/dev/null 2>&1
    echo "abd" | gzip > "${SRC#file://}"
    copy_file "${SRC}" "${DEST}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${DEST}")
    if [ "$RET" = "f" ]; then
        echo -e "test\t$HOSTNAME\thadoop\tOK\tcopyfile\t${SRC}\t${DEST}"
    else
        echo -e "test\t$HOSTNAME\thadoop\tFAILED\tcopyfile\t${SRC}\t${DEST}"
    fi
    rm_f_dir "${SRC#file://}.tmp" >/dev/null 2>&1
    copy_file "${DEST}" "${SRC}.tmp" >/dev/null 2>&1
    M1=$(md5sum "${SRC#file://}" | awk '{print $1}')
    M2=$(md5sum "${SRC#file://}.tmp" | awk '{print $1}')
    if [ "$M1" = "$M2" ]; then
        echo -e "test\t$HOSTNAME\thadoop\tOK\tmd5sum\t${SRC}\t${DEST}"
    else
        echo -e "test\t$HOSTNAME\thadoop\tFAILED\tmd5sum_M1=${M1}_M2=${M2}"
    fi
    rm_f_dir "${SRC}*" >/dev/null 2>&1
    rm_f_dir "${DEST}" >/dev/null 2>&1

    # test config file
    SRC="/tmp/tmp-$(uuidgen).conf"
    DEST="hdfs://user/${USER}/tmp/$(basename ${SRC})"
    echo "HDFF_PROJ_ID=mrtest" > "${SRC#file://}"
    echo "HDFF_NUM_CLONE=0" > "${SRC#file://}"
    echo -e "test\t$HOSTNAME\ttry_copy_file\t${SRC}\t${DEST}"
    copy_file "${SRC}" "${DEST}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${DEST}")
    if [ "$RET" = "f" ]; then
        echo -e "test\t$HOSTNAME\thadoop\tOK\tcopyfile\t${SRC}\t${DEST}"
    else
        echo -e "test\t$HOSTNAME\thadoop\tFAILED\tcopyfile\t${SRC}\t${DEST}"
    fi
    rm_f_dir "${SRC#file://}.tmp" >/dev/null 2>&1
    copy_file "${DEST}" "${SRC}.tmp" >/dev/null 2>&1
    M1=$(md5sum "${SRC#file://}" | awk '{print $1}')
    M2=$(md5sum "${SRC#file://}.tmp" | awk '{print $1}')
    if [ "$M1" = "$M2" ]; then
        echo -e "test\t$HOSTNAME\thadoop\tOK\tmd5sum\t${SRC}\t${DEST}"
    else
        echo -e "test\t$HOSTNAME\thadoop\tFAILED\tmd5sum_M1=${M1}_M2=${M2}"
    fi
    rm_f_dir "${SRC}*" >/dev/null 2>&1
    rm_f_dir "${DEST}" >/dev/null 2>&1

    mp_notify_child_exit ${PARAM_SESSION_ID}
    mr_trace "get info done"
}

worker_check_host1() {
    PARAM_SESSION_ID="$1"
    shift
    PARAM_CONFIG_FILE="$1"
    shift

    #echo -e "tryrun\tbegin\t${EXEC_TEST}"
    ${EXEC_TEST}
    #echo -e "tryrun\tend\t${EXEC_TEST}"

    mp_notify_child_exit ${PARAM_SESSION_ID}
    mr_trace "get info done"
}

#<command> <config_file>
#run <config_file>
# run "config-xx.sh"
while read MR_CMD MR_CONFIG_FILE ; do
  FN_CONFIG_FILE=$( unquote_filename "${MR_CONFIG_FILE}" )

  case "${MR_CMD}" in
  sim)
    mr_trace "run ..."
    worker_check_host0 "$(mp_get_session_id)" "${FN_CONFIG_FILE}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  *)
    mr_trace "Error: unknown type: ${MR_CMD}"
    # throw the command to output again
    echo -e "${MR_CMD}\t${MR_CONFIG_FILE}\t${MR_PREFIX}\t${MR_TYPE}\t${MR_FLOW_TYPE}\t${MR_SCHEDULER}\t${MR_NUM_NODE}"
    ERR=1
    ;;
  esac
done

mp_wait_all_children
mr_trace "done!"
