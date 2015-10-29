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
#####################################################################
mr_trace () {
    echo "$(date +"%Y-%m-%d %H:%M:%S,%N" | cut -c1-23) [self=${BASHPID},$(basename $0)] $@" 1>&2
}

#####################################################################
start_hadoop () {
    mr_trace "Start all Hadoop daemons"
    if [ -x "${HADOOP_HOME}/sbin/start-yarn.sh" ]; then
        ${HADOOP_HOME}/sbin/start-dfs.sh && ${HADOOP_HOME}/sbin/start-yarn.sh

    elif [ -x "${HADOOP_HOME}/bin/start-all.sh" ]; then
        ${HADOOP_HOME}/bin/start-all.sh

    else
        mr_trace "Not found ${HADOOP_HOME}/bin/start-all.sh"
        exit 1
    fi
    #${HADOOP_HOME}/bin/hadoop dfsadmin -safemode leave
    echo
    jps

    mr_trace "wait for hadoop ready, sleep 10 ..."
    sleep 10
}

stop_hadoop () {
    mr_trace "Stop all Hadoop daemons"
    jps
    if [ -x "${HADOOP_HOME}/sbin/stop-yarn.sh" ]; then
        ${HADOOP_HOME}/sbin/stop-yarn.sh && ${HADOOP_HOME}/sbin/stop-dfs.sh

    elif [ -x "${HADOOP_HOME}/bin/stop-all.sh" ]; then
        ${HADOOP_HOME}/bin/stop-all.sh

    else
        mr_trace "Not found ${HADOOP_HOME}/bin/stop-all.sh"
        exit 1
    fi
    echo
    jps
}

#####################################################################
# redirect the output to HDFS so we can fetch back later
HDFF_DN_OUTPUT="hdfs:///user/${USER}/mapreduce-results/"
sed -i -e "s|HDFF_DN_OUTPUT=.*$|HDFF_DN_OUTPUT=${HDFF_DN_OUTPUT}|" "${DN_TOP}/config-sys.sh"

# scratch(temp) dir
HDFF_DN_SCRATCH="/dev/shm/${USER}/"
sed -i -e "s|^HDFF_DN_SCRATCH=.*$|HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}|" "${DN_TOP}/config-sys.sh"

# tar the binary and save it to HDFS for the node extract it later
# TODO:
#   1. the tar file for ns2 exec
#   2. the HDFS path to this project

#####################################################################
stop_hadoop
#exit 0 # debug
jps | grep NameNode
if [ "$?" = "1" ]; then
    #### Start the Hadoop cluster
    start_hadoop
fi
#exit 0 # debug
#hadoop dfsadmin -safemode leave
#hdfs dfsadmin -safemode leave

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
if [ "$?" = "0" ]; then
#if [ 0 = 1 ]; then
    stop_hadoop
fi
