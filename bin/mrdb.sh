#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief debug my app
##
##
## @author Yunhui Fu <yhfudev@gmail.com>
## @copyright GPL v3.0 or later
## @version 1
##
#####################################################################

# $0 <command>
# commands:
#   start, stop, backup
usage() {
    echo "Please specify one of commands: start, stop, or backup" > /dev/stderr
}

if [ "$1" = "" ]; then
    usage
    exit 1
fi

case "$1" in
clean)
    ;;
start)
    ;;
stop)
    ;;
backup)
    ;;
*)
    usage
    exit 1
    ;;
esac

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

# from myhadoop
MH_LIST_NODES=
function print_nodelist {
    if [ "z$RESOURCE_MGR" == "zpbs" ]; then
        cat $PBS_NODEFILE | sed -e "$MH_IPOIB_TRANSFORM"
    elif [ "z$RESOURCE_MGR" == "zsge" ]; then
        cat $PE_NODEFILE | sed -e "$MH_IPOIB_TRANSFORM"
    elif [ "z$RESOURCE_MGR" == "zslurm" ]; then
        scontrol show hostname $SLURM_NODELIST | sed -e "$MH_IPOIB_TRANSFORM"
    else
        IFS=':'; array=($MH_LIST_NODES)
        for i in "${!array[@]}"; do
            echo "${array[i]}"
        done
    fi
}

## @fn backup_logs()
## @brief Collect logs, config files etc
backup_logs() {

    local LIST_FILES_REMOTE=(
        "/tmp/hsperfdata_yfu/"
        "/tmp/hadoop/"
        "/dev/shm/yfu/"
    )
    local LIST_FILES_LOCAL=(
        "myhadoop.conf"
        "mrsystem-working.conf"
        "mrtrace.log"
        "output1"
        "${HADOOP_CONF_DIR}"
        "hadoopconfigs-*"
        "HADOOP_TMP_DIR"
    )
    local TIMESTAMP="$(date +'%Y%m%d-%H%M')"
    local DN_COLLECT="log-${TIMESTAMP}"

    mkdir -p "${DN_COLLECT}"

    # save the contents from slaves
    local CNT=1
    for HOST_ADDR in $(print_nodelist) ; do
        local DN_TARGET="${DN_COLLECT}/slave-${CNT}"
        make_dir "${DN_TARGET}"
        for i in "${!LIST_FILES_REMOTE[@]}"; do
            mr_trace "copy TO ${DN_TARGET} FROM ${HOST_ADDR}:${LIST_FILES_REMOTE[i]}"
            scp -r "${HOST_ADDR}:${LIST_FILES_REMOTE[i]}" "${DN_TARGET}"
        done
        CNT=$((CNT + 1))
    done

    for i in "${!LIST_FILES_LOCAL[@]}"; do
        copy_file "${LIST_FILES_LOCAL[i]}" "${DN_COLLECT}"
    done
}

## @fn clean_dir()
## @brief clean the dirs
##
## clean the dirs
clean_dir() {
    local LIST_FILES_REMOTE=(
        "/tmp/hsperfdata_yfu/"
        "/tmp/hadoop/"
        "/dev/shm/yfu/"
        "/tmp/tmp-*"
    )
    local LIST_FILES_LOCAL=(
        "mrtrace.log"
        "output1"
        "${HADOOP_CONF_DIR}"
        "hadoopconfigs-*"
        "HADOOP_TMP_DIR"
    )

    # remove the contents from slaves
    for i in "${!LIST_FILES_REMOTE[@]}"; do
        rm_f_dir "${LIST_FILES_REMOTE[i]}"
        for HOST_ADDR in $(print_nodelist) ; do
            mr_trace "remove ${LIST_FILES_REMOTE[i]} FROM ${HOST_ADDR}"
            ssh "${HOST_ADDR}" "rm -rf ${LIST_FILES_REMOTE[i]}"
        done
    done

    for i in "${!LIST_FILES_LOCAL[@]}"; do
        rm_f_dir "${LIST_FILES_LOCAL[i]}"
    done
}

## @fn stop_job()
## @brief stop job
##
## stop all of instance of the cluster
stop_job() {
    # stop slaves
    for HOST_ADDR in $(print_nodelist) ; do
        if [ "${HOST_ADDR}" = "`hostname`" ]; then
            mr_trace "skip job AT ${HOST_ADDR}"
            continue
        fi
        mr_trace "stop job AT ${HOST_ADDR}"
        ssh "${HOST_ADDR}" "killall java"
        ssh "${HOST_ADDR}" "ps -ef | egrep 'bash|java' | grep "^\$USER" | awk '{print \$2}' | while read a; do kill -9 \$a; done"
        ssh "${HOST_ADDR}" "killall bash"
    done

    # stop local
    killall java
    killall bash
    ps -ef | egrep 'bash|java' | grep "^$USER" | awk '{print $2}' | while read a; do kill -9 $a; done
}

## @fn start_job()
## @brief start a new job
##
## clean the dirs first, then start the job
start_job() {
    clean_dir

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -x # start DEBUG
    ${DN_BIN}/plboot-lan.sh
set +x # stop DEBUG
}

read_config_file "mrsystem-working.conf"
read_config_file "myhadoop.conf"

echo "HDFF_DN_OUTPUT=${HDFF_DN_OUTPUT}"
echo "HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"

echo "MH_LIST_NODES=${MH_LIST_NODES}"
echo "MH_SCRATCH_DIR=${MH_SCRATCH_DIR}"

case "$1" in
clean)
    clean_dir
    ;;
start)
    start_job
    ;;
stop)
    stop_job
    ;;
backup)
    backup_logs
    ;;
*)
    usage
    exit 1
    ;;
esac

exit 0

