#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief run hadoop job
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
#DN_EXEC=`echo "$0" | ${EXEC_AWK} -F/ '{b=$1; for (i=2; i < NF; i ++) {b=b "/" $(i)}; print b}'`
DN_EXEC=$(dirname $(my_getpath "$0") )
if [ ! "${DN_EXEC}" = "" ]; then
    DN_EXEC="$(my_getpath "${DN_EXEC}")/"
else
    export DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
DN_BIN="$(my_getpath "${DN_TOP}/bin/")"
DN_EXEC="$(my_getpath ".")"
DN_LIB="$(my_getpath "${DN_TOP}/lib/")"

#####################################################################
source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libfs.sh
source ${DN_LIB}/libconfig.sh

#####################################################################
if [ -f "${DN_BIN}/mod-setenv-hadoop.sh" ]; then
.   ${DN_BIN}/mod-setenv-hadoop.sh
else
    mr_trace "Error: not found file ${DN_BIN}/mod-setenv-hadoop.sh"
    exit 1
fi

#stop_hadoop
#exit 0 # debug
jps | grep NameNode
if [ "$?" = "1" ]; then
    #### Start the Hadoop cluster
    start_hadoop
fi
#exit 0 # debug
#hadoop dfsadmin -safemode leave
#hdfs dfsadmin -safemode leave

#####################################################################

## @fn create_mrsystem_config_hadoop()
## @brief create mrsystem config file for hadoop cluster
## @param fn_config the config file name
##
create_mrsystem_config_hadoop() {
    local PARAM_FN_CONFIG=$1
    shift

    HDFF_USER=${USER}
    sed -i -e "s|^HDFF_USER=.*$|HDFF_USER=${HDFF_USER}|" "${FN_CONFIG_WORKING}"

    HDFF_DN_BASE="hdfs:///tmp/${HDFF_USER}/output-${HDFF_PROJ_ID}/"
    sed -i -e "s|^HDFF_DN_BASE=.*$|HDFF_DN_BASE=${HDFF_DN_BASE}|" "${FN_CONFIG_WORKING}"

    # redirect the output to HDFS so we can fetch back later
    HDFF_DN_OUTPUT="${HDFF_DN_BASE}"
    sed -i -e "s|^HDFF_DN_OUTPUT=.*$|HDFF_DN_OUTPUT=${HDFF_DN_OUTPUT}|" "${FN_CONFIG_WORKING}"

    # scratch(temp) dir
    HDFF_DN_SCRATCH="/dev/shm/${HDFF_USER}/working-${HDFF_PROJ_ID}/"
    sed -i -e "s|^HDFF_DN_SCRATCH=.*$|HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}|" "${FN_CONFIG_WORKING}"

    # the directory for save the un-tar binary files
    HDFF_DN_BIN="/dev/shm/${HDFF_USER}/working-${HDFF_PROJ_ID}/bin"
    sed -i -e "s|^HDFF_DN_BIN=.*$|HDFF_DN_BIN=${HDFF_DN_BIN}|" "${FN_CONFIG_WORKING}"

    # tar the binary and save it to HDFS for the node extract it later
    # the tar file for application exec
    HDFF_PATHTO_TAR_APP="${HDFF_DN_BASE}/${HDFF_FN_TAR_APP}"
    sed -i -e "s|^HDFF_PATHTO_TAR_APP=.*$|HDFF_PATHTO_TAR_APP=${HDFF_PATHTO_TAR_APP}|" "${FN_CONFIG_WORKING}"

    # the HDFS path to this project
    HDFF_PATHTO_TAR_MRNATIVE="${HDFF_DN_BASE}/${HDFF_FN_TAR_MRNATIVE}"
    sed -i -e "s|^HDFF_PATHTO_TAR_MRNATIVE=.*$|HDFF_PATHTO_TAR_MRNATIVE=${HDFF_PATHTO_TAR_MRNATIVE}|" "${FN_CONFIG_WORKING}"

    FN_CONF_SYS="${HDFF_DN_BASE}/mrsystem-working.conf"
    make_dir "$(dirname ${FN_CONF_SYS})"
    copy_file "${FN_CONFIG_WORKING}" "${FN_CONF_SYS}"

}


# read basic config from mrsystem.conf
# such as HDFF_PROJ_ID, HDFF_NUM_CLONE etc
read_config_file "${DN_TOP}/mrsystem.conf"

# set the generated config file
FN_CONFIG_WORKING="${DN_EXEC}/mrsystem-working.conf"
rm_f_dir "${FN_CONFIG_WORKING}"
copy_file "${DN_TOP}/mrsystem.conf" "${FN_CONFIG_WORKING}"
FN_CONF_SYS="${FN_CONFIG_WORKING}"

create_mrsystem_config_hadoop "${FN_CONFIG_WORKING}"

check_global_config

# put the file to HDFS ...
DN1="$(dirname ${HDFF_PATHTO_TAR_MRNATIVE})"
RET=$(make_dir "${DN1}")
if [ ! "$RET" = "0" ]; then
    mr_trace "Warning: failed to hadoop mkdir ${DN1}, try again ..."
    $MYEXEC hadoop dfsadmin -safemode leave
    hdfs dfsadmin -safemode leave
    RET=$(make_dir "${DN1}")
    if [ ! "$RET" = "0" ]; then
        mr_trace "Error in hadoop mkdir ${DN1}"
        return
    fi
fi

# copy the file to HDFS so all of the hadoop node can access it
rm_f_dir "${HDFF_PATHTO_TAR_MRNATIVE}"

cd ${DN_TOP}
if [ ! -f "${DN_TOP}/${HDFF_FN_TAR_MRNATIVE}" ]; then
    ./autogen.sh
    ./configure
fi
make dist-gzip
cd -

if [ ! -f "${DN_TOP}/${HDFF_FN_TAR_MRNATIVE}" ]; then
    mr_trace "Error: not found file ${DN_TOP}/${HDFF_FN_TAR_MRNATIVE}"
    exit 1
fi
mr_trace "copying '${DN_TOP}/${HDFF_FN_TAR_MRNATIVE}' to '${HDFF_PATHTO_TAR_MRNATIVE}' ..."
RET=$(copy_file "${DN_TOP}/${HDFF_FN_TAR_MRNATIVE}" "${HDFF_PATHTO_TAR_MRNATIVE}")
if [ ! "$RET" = "0" ]; then
    mr_trace "Warning: failed to hadoop copy file ${DN_TOP}/${HDFF_FN_TAR_MRNATIVE}, try again ..."
    $MYEXEC hadoop dfsadmin -safemode leave
    hdfs dfsadmin -safemode leave
    RET=$(copy_file "${DN_TOP}/${HDFF_FN_TAR_MRNATIVE}" "${HDFF_PATHTO_TAR_MRNATIVE}")
    if [ ! "$?" = "0" ]; then
        mr_trace "Error in hadoop copyfile ${DN_TOP}/${HDFF_FN_TAR_MRNATIVE}"
        return
    fi
fi

if [ ! -f "${DN_TOP}/${HDFF_FN_TAR_APP}" ]; then
    mr_trace "Error: not found file ${DN_TOP}/${HDFF_FN_TAR_APP}"
    exit 1
fi
make_dir "$(dirname ${HDFF_PATHTO_TAR_APP})"
mr_trace "copying '${DN_TOP}/${HDFF_FN_TAR_APP}' to '${HDFF_PATHTO_TAR_APP}' ..."
rm_f_dir "${HDFF_PATHTO_TAR_APP}"
copy_file "${DN_TOP}/${HDFF_FN_TAR_APP}" "${HDFF_PATHTO_TAR_APP}"
#exit 0 # debug

#### Run your jobs here
mr_trace "Run some test Hadoop jobs"
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -mkdir Data
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -copyFromLocal /home/srkrishnan/Data/gutenberg Data
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -ls Data/gutenberg
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} jar ${HADOOP_HOME}/hadoop-0.20.2-examples.jar wordcount Data/gutenberg Outputs
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -ls Outputs

if [ -f "${DN_BIN}/mod-share-worker.sh" ]; then
. ${DN_BIN}/mod-share-worker.sh
else
    mr_trace "Error: not found file ${DN_BIN}/mod-share-worker.sh"
    exit 1
fi


echo
mapred_main

jps | grep NameNode
#if [ "$?" = "0" ]; then
if [ 0 = 1 ]; then
    stop_hadoop
fi
