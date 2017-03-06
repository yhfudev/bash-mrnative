#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#PBS -N ns2docsis
#PBS -l select=5:ncpus=16:mem=61gb
#PBS -q workq
#PBS -l walltime=72:00:00
#PBS -M yfu@clemson.edu
#PBS -m ea
#####################################################################
## @file
## @brief the main entry for HPC PBS
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
#####################################################################
mr_trace() {
    echo "$(date +"%Y-%m-%d %H:%M:%S.%N" | cut -c1-23) [self=${BASHPID},$(basename $0)] $@" 1>&2
}

#####################################################################

if [ "z$PBS_JOBID" != "z" ]; then
    MH_WORKDIR=$PBS_O_WORKDIR
    MH_JOBID=$PBS_JOBID
elif [ "z$PE_NODEFILE" != "z" ]; then
    MH_WORKDIR=$SGE_O_WORKDIR
    MH_JOBID=$JOB_ID
elif [ "z$SLURM_JOBID" != "z" ]; then
    MH_WORKDIR=$SLURM_SUBMIT_DIR
    MH_JOBID=$SLURM_JOBID
else
    MH_WORKDIR=$PWD
    MH_JOBID=$$
fi

cd $MH_WORKDIR

DN_EXEC="$(my_getpath "$(pwd)")"
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
DN_BIN="$(my_getpath "${DN_TOP}/bin/")"
DN_EXEC="$(my_getpath ".")"
if [ ! -f "${FN_CONF_SYS}" ]; then
    FN_CONF_SYS="${DN_EXEC}/mrsystem-working.conf"
fi
if [ ! -f "${FN_CONF_SYS}" ]; then
    FN_CONF_SYS="${DN_TOP}/mrsystem.conf"
fi
if [ ! -f "${FN_CONF_SYS}" ]; then
    mr_trace "not found config file: ${FN_CONF_SYS}"
fi

mr_trace "PBS_O_WORKDIR=$PBS_O_WORKDIR"
mr_trace "0 DN_TOP=$DN_TOP; DN_EXEC=${DN_EXEC}"

export PROJ_HOME=$DN_TOP
if [ ! -d "${PROJ_HOME}" ]; then
    export PROJ_HOME=/home/$USER/mapreduce-mrnative
fi
if [ ! -d "${PROJ_HOME}" ]; then
    mr_trace "Error: not exit dir $PROJ_HOME"
    exit 1
fi
DN_BIN="${PROJ_HOME}/bin"

mr_trace "02 DN_TOP=$DN_TOP; DN_EXEC=${DN_EXEC}"

### Run the myHadoop environment script to set the appropriate variables

#### Set this to the directory where Hadoop configs should be generated
# Don't change the name of this variable (HADOOP_CONF_DIR) as it is
# required by Hadoop - all config files will be picked up from here
#
# Make sure that this is accessible to all nodes
# where your personal cluster's configuration will be located
export HADOOP_CONF_DIR=${MH_WORKDIR}/hadoopconfigs-$MH_JOBID
mkdir -p "${HADOOP_CONF_DIR}"
if [ ! "$?" = "0" ]; then mr_trace "Error in mkdir ${HADOOP_CONF_DIR}" ; fi

mr_trace "03 DN_TOP=$DN_TOP; DN_EXEC=${DN_EXEC}"
# Note: ensure that the variables are set correctly in bin/mod-setenv-hadoop.sh
if [ -f "${DN_BIN}/mod-setenv-hadoop.sh" ]; then
.   ${DN_BIN}/mod-setenv-hadoop.sh
else
    mr_trace "Error: not found file ${DN_BIN}/mod-setenv-hadoop.sh"
    exit 1
fi
mr_trace "04 DN_TOP=$DN_TOP; DN_EXEC=${DN_EXEC}"

rm -rf ${HADOOP_HOME}/logs/*
#mkdir -p "${HADOOP_LOG_DIR}"
#if [ ! "$?" = "0" ]; then mr_trace "Error in mkdir ${HADOOP_LOG_DIR}" ; fi

export PATH=$HADOOP_HOME/bin:$MH_HOME/bin:$PATH

### Cleanup script and signal trap
plboot_hadoop_terminate() {
  $HADOOP_HOME/bin/stop-all.sh
  stop_hadoop
  ${MY_HADOOP_HOME}/bin/myhadoop-cleanup.sh
  exit
}
trap plboot_hadoop_terminate SIGHUP SIGINT SIGTERM


#### Set up the configuration
# Make sure number of nodes is the same as what you have requested from PBS
# usage: ${MY_HADOOP_HOME}/bin/myhadoop-configure.sh -h
mr_trace "Set up the configurations for myHadoop"
mr_trace ${MY_HADOOP_HOME}/bin/myhadoop-configure.sh
${MY_HADOOP_HOME}/bin/myhadoop-configure.sh || exit 1

#### Start the Hadoop cluster
start_hadoop

#### Run your jobs here
mr_trace "Run some test Hadoop jobs"
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -mkdir Data
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -copyFromLocal /home/srkrishnan/Data/gutenberg Data
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -ls Data/gutenberg
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} jar ${HADOOP_HOME}/hadoop-0.20.2-examples.jar wordcount Data/gutenberg Outputs
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -ls Outputs
mr_trace "05 DN_TOP=$DN_TOP; DN_EXEC=${DN_EXEC}"

mr_trace "you may access the web page: http://firstnode:8088"

if [ 1 = 1 ]; then
    if [ -f "${DN_BIN}/mod-share-worker.sh" ]; then
. ${DN_BIN}/mod-share-worker.sh
    else
        mr_trace "Error: not found file ${DN_BIN}/mod-share-worker.sh"
        exit 1
    fi
    mr_trace "06 DN_TOP=$DN_TOP; DN_EXEC=${DN_EXEC}"

    echo
    mapred_main

    mr_trace copy_file "${HDFF_DN_OUTPUT}" output1
    copy_file "${HDFF_DN_OUTPUT}" output1
    sleep $(( 15 * 60 ))

else
    sleep $(( 72 * 60 * 60 ))
fi

#### Clean up the working directories after job completion
mr_trace "Clean up"
plboot_hadoop_terminate
mr_trace "Done hadoop"
