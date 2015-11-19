#!/bin/bash
#####################################################################
# bash library
# config file reader for bash scripts:
#   read_config_file
#
# Copyright 2014 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################

# read config file from pipe
read_config_file () {
    ### Read in some system-wide configurations (if applicable) but do not override
    ### the user's environment
    PARAM_FN_CONF="$1"
    mr_trace "parse config file $1"
    if [ ! -e "$PARAM_FN_CONF" ]; then
        echo -e "debug\t$(hostname)\tread_config_file\tnot_exist_conf_file__$PARAM_FN_CONF"
        mr_trace "not exist config file: $PARAM_FN_CONF"
        return
    fi

    while read LINE; do
        REX='^[^# ]*='
        if [[ ${LINE} =~ ${REX} ]]; then
            VARIABLE=$(echo "${LINE}" | awk -F= '{print $1}' )
            VALUE0=$(echo "${LINE}" | awk -F= '{print $2}' )
            VALUE=$( unquote_filename "${VALUE0}" )
            V0="RCFLAST_VAR_${VARIABLE}"
            if [ "z${!V0}" == "z" ]; then
                if [ "z${!VARIABLE}" == "z" ]; then
                    eval "${V0}=\"${VALUE}\""
                    eval "${VARIABLE}=\"${VALUE}\""
                    #mr_trace "Setting ${VARIABLE}=${VALUE} from $PARAM_FN_CONF"
                #else mr_trace "Keeping $VARIABLE=${!VARIABLE} from user environment"
                fi
            else
                eval "${V0}=\"${VALUE}\""
                eval "${VARIABLE}=\"${VALUE}\""
                #mr_trace "Setting ${VARIABLE}=${VALUE} from $PARAM_FN_CONF"
            fi
            #mr_trace "VARIABLE=${VARIABLE}; VALUE=${VALUE}"
        fi
    done < "$PARAM_FN_CONF"
    mr_trace "parse config file $1 DONE"
}

#####################################################################
# check if the global variable not set, set it to default values.
check_global_config () {
    mr_trace "check_global_config BEGIN"
    if [ "${HDFF_DN_OUTPUT}" = "" ]; then
        # set to ${DN_TOP}/data/output/
        HDFF_DN_OUTPUT=data/output
    fi

    FLG_AUTOCPU=0
    if [ "${HDFF_NUM_CLONE}" = "" ] ; then
        FLG_AUTOCPU=1
        HDFF_NUM_CLONE=1
    fi
    if [ "${HDFF_NUM_CLONE}" -lt 1 ] ; then
        FLG_AUTOCPU=1
    fi
    if [ "${FLG_AUTOCPU}" = "1" ] ; then
        HDFF_NUM_CLONE=1
        # number of CPUs
        NUM_PROC=$(cat /proc/cpuinfo | egrep ^processor | wc -l)
        if [ "${NUM_PROC}" -gt 1 ] ; then
        #HDFF_NUM_CLONE=$(( ${NUM_PROC} * 8 / 9 ))
        #NUM=$(( ${NUM_PROC} / 9 ))
        #if [ "${NUM}" -gt 8 ] ; then
        #  HDFF_NUM_CLONE=$(( ${NUM_PROC} - 8 ))
        #fi
        HDFF_NUM_CLONE=${NUM_PROC}
        fi
    fi
    if [ "${HDFF_NUM_CLONE}" -lt 1 ] ; then
        HDFF_NUM_CLONE=1
    fi

    local RET=0
    if [ ! "${HDFF_DN_SCRATCH}" = "" ]; then
        RET=$(is_local "${HDFF_DN_SCRATCH}")
        if [ ! "${RET}" = "l" ]; then
            HDFF_DN_SCRATCH=
        fi
    fi
    if [ "${HDFF_USER}" = "" ]; then
        HDFF_USER=${USER}
    fi
    if [ "${HDFF_DN_SCRATCH}" = "" ]; then
        # search if such device exist
        HDFF_DN_SCRATCH="/tmp/${HDFF_USER}/"
        DN_SHM=$(df | grep shm | tail -n 1 | awk '{print $6}')
        if [ ! "$DN_SHM" = "" ]; then
            HDFF_DN_SCRATCH="${DN_SHM}/${HDFF_USER}/"
        fi

        # the size
        SZK=$(df -P -T "${HDFF_DN_SCRATCH}" | awk '{print $5}')
        if (( $SZK < 1000000 )) ; then
            # 1000000: 1GB
            HDFF_DN_SCRATCH="/tmp/${HDFF_USER}/"
        fi
        SZK=$(df -P -T "${HDFF_DN_SCRATCH}" | awk '{print $5}')
        if (( $SZK < 1000000 )) ; then
            if [ -d "/local_scratch" ]; then
                HDFF_DN_SCRATCH="/local_scratch/${HDFF_USER}"
            fi
        fi
        mr_trace "reset HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"
    fi
    # create all of the directories
    mr_trace make_dir "${HDFF_DN_BASE}"
    make_dir "${HDFF_DN_BASE}" > /dev/null
    mr_trace make_dir "${HDFF_DN_OUTPUT}"
    make_dir "${HDFF_DN_OUTPUT}" > /dev/null
    mr_trace make_dir "${HDFF_DN_SCRATCH}"
    make_dir "${HDFF_DN_SCRATCH}" > /dev/null
    if [ ! "${HDFF_DN_BIN}" = "" ]; then
        mr_trace make_dir "${HDFF_DN_BIN}"
        make_dir "${HDFF_DN_BIN}" > /dev/null
    fi
    if [ ! "${HDFF_FN_TAR_MRNATIVE}" = "" ]; then
        mr_trace make_dir "$(dirname ${HDFF_FN_TAR_APP})"
        make_dir "$(dirname ${HDFF_FN_TAR_APP})" > /dev/null
    fi
    if [ ! "${HDFF_FN_TAR_MRNATIVE}" = "" ]; then
        mr_trace make_dir "$(dirname ${HDFF_FN_TAR_MRNATIVE})"
        make_dir "$(dirname ${HDFF_FN_TAR_MRNATIVE})" > /dev/null
    fi
    # only change the mode for others user's access in HDFS, because the user changed in hadoop only
    [[ "${HDFF_DN_OUTPUT}"  =~ ^hdfs:// ]] && chmod_file -R 777 "${HDFF_DN_OUTPUT}"  > /dev/null
    [[ "${HDFF_DN_SCRATCH}" =~ ^hdfs:// ]] && chmod_file -R 777 "${HDFF_DN_SCRATCH}" > /dev/null
    [[ "${HDFF_DN_BIN}"     =~ ^hdfs:// ]] && chmod_file -R 777 "${HDFF_DN_BIN}"     > /dev/null
    [[ "${HDFF_FN_TAR_APP}" =~ ^hdfs:// ]] && chmod_file -R 777 "$(dirname ${HDFF_FN_TAR_APP})" > /dev/null
    [[ "${HDFF_FN_TAR_MRNATIVE}" =~ ^hdfs:// ]] && chmod_file -R 777 "$(dirname ${HDFF_FN_TAR_MRNATIVE})" > /dev/null
    [[ "${HDFF_DN_BASE}"    =~ ^hdfs:// ]] && chmod_file -R 777 "${HDFF_DN_BASE}"    > /dev/null  # this line should be the last line

    RET=$(is_local "${HDFF_DN_SCRATCH}")
    if [ ! "${RET}" = "l" ]; then
        mr_trace "Warning: the scratch dir is not in local disk: ${HDFF_DN_SCRATCH}"
    fi
    mr_trace "check_global_config DONE"
}

#####################################################################
generate_default_config () {

  cat << EOF
# default configure file for HDFF generated by $(basename $0)
# the project id for name prefix
HDFF_PROJ_ID=${HDFF_PROJ_ID}
# description
HDFF_PROJ_DESC=${HDFF_PROJ_DESC}

# how many running processes in each node
# 0 -- auto detect the CPU cores, use all of them
HDFF_NUM_CLONE=0

# total number of nodes (machines) in the system, default = 1
HDFF_TOTAL_NODES=1

HDFF_FN_LOG="/dev/null"

# the user start the task
# please set it in your start script or by manual
HDFF_USER=${HDFF_USER}

# we have to use /tmp file for both local and hdfs file systems,
# since the runner may not be the user submitted the job;
# and the /tmp(or /dev/shm) is the only directory that can be
# accessed by both the user and runner (and also other users)

HDFF_DN_BASE="hdfs:///tmp/${HDFF_USER}"

# the output file directory
#HDFF_DN_OUTPUT=mapreduce-results
#HDFF_DN_OUTPUT=hdfs://${HDFF_DN_BASE}/mapreduce-results/
#HDFF_DN_OUTPUT="hdfs:///user/${USER}/mapreduce-results/"
#HDFF_DN_OUTPUT="file://$HOME/mapreduce-results/"
#HDFF_DN_OUTPUT="file:///scratch1/$USER/mapreduce-results/"
HDFF_DN_OUTPUT=${HDFF_DN_BASE}/mapreduce-results/

# the temporary directory for NS2 simulator
#HDFF_DN_SCRATCH="/tmp/${HDFF_USER}/"
#HDFF_DN_SCRATCH="/run/shm/${HDFF_USER}/"
#HDFF_DN_SCRATCH="/dev/shm/${HDFF_USER}/"
#HDFF_DN_SCRATCH="/local_scratch/${HDFF_USER}/"
HDFF_DN_SCRATCH=/dev/shm/${HDFF_USER}/

# the directory for save the un-tar binary files
# it should be a directory in a local disk
#HDFF_DN_BIN="/run/shm/${HDFF_USER}/bin"
#HDFF_DN_BIN="/dev/shm/${HDFF_USER}/bin"
HDFF_DN_BIN=/dev/shm/${HDFF_USER}/bin

# the tar file for application binary
#HDFF_FN_TAR_APP=hdfs:///tmp/${HDFF_USER}/app-test-binary.tar.gz
HDFF_FN_TAR_APP=${HDFF_FN_TAR_APP}

# the tar file for mrnative-ns2
#HDFF_FN_TAR_MRNATIVE=hdfs:///tmp/${HDFF_USER}/mrtest-1.0.tar.gz
HDFF_FN_TAR_MRNATIVE=${HDFF_FN_TAR_MRNATIVE}
EOF
}
