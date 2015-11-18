#!/bin/bash
#####################################################################
# run hadoop job
#
#
# Copyright 2014 Yunhui Fu
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
#DN_EXEC=`echo "$0" | ${EXEC_AWK} -F/ '{b=$1; for (i=2; i < NF; i ++) {b=b "/" $(i)}; print b}'`
DN_EXEC=$(dirname $(my_getpath "$0") )
if [ ! "${DN_EXEC}" = "" ]; then
    DN_EXEC="$(my_getpath "${DN_EXEC}")/"
else
    export DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
DN_EXEC="$(my_getpath "${DN_TOP}/projtools/")"
DN_LIB="$(my_getpath "${DN_TOP}/lib/")"
#####################################################################
source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libfs.sh
source ${DN_LIB}/libconfig.sh

#####################################################################
# read basic config from mrsystem.conf
# such as HDFF_PROJ_ID, HDFF_NUM_CLONE etc
read_config_file "${DN_TOP}/mrsystem.conf"

HDFF_USER=${USER}
sed -i -e "s|HDFF_USER=.*$|HDFF_USER=${HDFF_USER}|" "${DN_TOP}/mrsystem.conf"

HDFF_DN_BASE="hdfs:///tmp/${HDFF_USER}"
sed -i -e "s|HDFF_DN_BASE=.*$|HDFF_DN_BASE=${HDFF_DN_BASE}|" "${DN_TOP}/mrsystem.conf"

# redirect the output to HDFS so we can fetch back later
HDFF_DN_OUTPUT="${HDFF_DN_BASE}/mapreduce-results/"
sed -i -e "s|^HDFF_DN_OUTPUT=.*$|HDFF_DN_OUTPUT=${HDFF_DN_OUTPUT}|" "${DN_TOP}/mrsystem.conf"

# scratch(temp) dir
HDFF_DN_SCRATCH="/dev/shm/${HDFF_USER}/"
sed -i -e "s|^HDFF_DN_SCRATCH=.*$|HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}|" "${DN_TOP}/mrsystem.conf"

# the directory for save the un-tar binary files
HDFF_DN_BIN="/dev/shm/${HDFF_USER}/bin"
sed -i -e "s|^HDFF_DN_BIN=.*$|HDFF_DN_BIN=${HDFF_DN_BIN}|" "${DN_TOP}/mrsystem.conf"

# tar the binary and save it to HDFS for the node extract it later
# the tar file for ns2 exec
FN_TAR_APP="ns2docsis-ds31profile-i386-compiled.tar.gz"
HDFF_FN_TAR_APP="${HDFF_DN_BASE}/mapreduce-working/${HDFF_PROJ_ID}/${FN_TAR_APP}"
sed -i -e "s|^HDFF_FN_TAR_APP=.*$|HDFF_FN_TAR_APP=${HDFF_FN_TAR_APP}|" "${DN_TOP}/mrsystem.conf"

# the HDFS path to this project
cd ..
make dist-gzip
FN_TAR_MRNATIVE=$(ls mrnative*.tar.gz | sort | tail -n 1)
cd -
cp "../${FN_TAR_MRNATIVE}" .
HDFF_FN_TAR_MRNATIVE="${HDFF_DN_BASE}/mapreduce-working/${HDFF_PROJ_ID}/${FN_TAR_MRNATIVE}"
sed -i -e "s|^HDFF_FN_TAR_MRNATIVE=.*$|HDFF_FN_TAR_MRNATIVE=${HDFF_FN_TAR_MRNATIVE}|" "${DN_TOP}/mrsystem.conf"

FN_CONF_SYS="${HDFF_DN_BASE}/mapreduce-working/${HDFF_PROJ_ID}/mrsystem.conf"
make_dir "$(dirname ${FN_CONF_SYS})"
copy_file "${DN_TOP}/mrsystem.conf" "${FN_CONF_SYS}"

check_global_config

#####################################################################
if [ -f "${DN_EXEC}/mod-setenv-hadoop.sh" ]; then
.   ${DN_EXEC}/mod-setenv-hadoop.sh
else
    mr_trace "Error: not found file ${DN_EXEC}/mod-setenv-hadoop.sh"
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

# put the file to HDFS ...
mr_trace "copying '${FN_TAR_MRNATIVE}' to '${HDFF_FN_TAR_MRNATIVE}' ..."
DN1="$(dirname ${HDFF_FN_TAR_MRNATIVE})"
RET=$(make_dir "${DN1}")
if [ ! "$RET" = "0" ]; then
    mr_trace "Warning: failed to hadoop mkdir ${DN1}, try again ..."
    hadoop dfsadmin -safemode leave
    hdfs dfsadmin -safemode leave
    RET=$(make_dir "${DN1}")
    if [ ! "$RET" = "0" ]; then
        mr_trace "Error in hadoop mkdir ${DN1}"
        return
    fi
fi

rm_f_dir "${HDFF_FN_TAR_MRNATIVE}"
RET=$(copy_file "${FN_TAR_MRNATIVE}" "${HDFF_FN_TAR_MRNATIVE}")
if [ ! "$RET" = "0" ]; then
    mr_trace "Warning: failed to hadoop copy file ${FN_TAR_MRNATIVE}, try again ..."
    hadoop dfsadmin -safemode leave
    hdfs dfsadmin -safemode leave
    RET=$(copy_file "${FN_TAR_MRNATIVE}" "${HDFF_FN_TAR_MRNATIVE}")
    if [ ! "$?" = "0" ]; then
        mr_trace "Error in hadoop copyfile ${FN_TAR_MRNATIVE}"
        return
    fi
fi

make_dir "$(dirname ${HDFF_FN_TAR_APP})"
mr_trace "copying '${FN_TAR_APP}' to '${HDFF_FN_TAR_APP}' ..."
rm_f_dir "${HDFF_FN_TAR_APP}"
copy_file "${FN_TAR_APP}"      "${HDFF_FN_TAR_APP}"
#exit 0 # debug

#### Run your jobs here
mr_trace "Run some test Hadoop jobs"
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -mkdir Data
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -copyFromLocal /home/srkrishnan/Data/gutenberg Data
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -ls Data/gutenberg
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} jar ${HADOOP_HOME}/hadoop-0.20.2-examples.jar wordcount Data/gutenberg Outputs
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -ls Outputs

. ${DN_EXEC}/mod-share-worker.sh
echo
mapred_main

jps | grep NameNode
#if [ "$?" = "0" ]; then
if [ 0 = 1 ]; then
    stop_hadoop
fi
