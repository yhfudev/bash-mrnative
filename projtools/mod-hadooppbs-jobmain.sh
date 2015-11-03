#!/bin/bash
#PBS -N ns2docsis
#PBS -l select=5:ncpus=16:mem=61gb
#PBS -q workq
#PBS -l walltime=72:00:00
#PBS -M yfu@clemson.edu
#PBS -m ea
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
#####################################################################
mr_trace () {
    echo "$(date +"%Y-%m-%d %H:%M:%S,%N" | cut -c1-23) [self=${BASHPID},$(basename $0)] $@" 1>&2
}

#####################################################################

# the number of nodes: select=xxx
export PBS_NUM_NODES=$(cat $PBS_NODEFILE | uniq | wc -l)

mr_trace "PBS_NUM_NODES=$PBS_NUM_NODES"

source /etc/profile.d/modules.sh
module purge
#module add java

cd $PBS_O_WORKDIR

DN_EXEC="$(my_getpath "$(pwd)")"
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
DN_EXEC="$(my_getpath "${DN_TOP}/projtools/")"

mr_trace "PBS_O_WORKDIR=$PBS_O_WORKDIR"
mr_trace "DN_TOP=$DN_TOP"

export PROJ_HOME=$DN_TOP
if [ ! -d "${PROJ_HOME}" ]; then
    export PROJ_HOME=/home/$USER/mapreduce-ns2docsis
fi
if [ ! -d "${PROJ_HOME}" ]; then
    mr_trace "Error: not exit dir $PROJ_HOME"
    exit 1
fi
DN_EXEC1="${PROJ_HOME}/projtools"

### Run the myHadoop environment script to set the appropriate variables

#### Set this to the directory where Hadoop configs should be generated
# Don't change the name of this variable (HADOOP_CONF_DIR) as it is
# required by Hadoop - all config files will be picked up from here
#
# Make sure that this is accessible to all nodes
# where your personal cluster's configuration will be located
export HADOOP_CONF_DIR=${PBS_O_WORKDIR}/hadoopconfigs-$PBS_JOBID
mkdir -p "${HADOOP_CONF_DIR}"
if [ ! "$?" = "0" ]; then mr_trace "Error in mkdir ${HADOOP_CONF_DIR}" ; fi

# Note: ensure that the variables are set correctly in bin/mod-hadooppbs-setenv.sh
if [ -f "${DN_EXEC1}/mod-setenv-hadoop.sh" ]; then
.   ${DN_EXEC1}/mod-setenv-hadoop.sh
else
    mr_trace "Error: not found file ${DN_EXEC1}/mod-hadooppbs-setenv.sh"
    exit 1
fi

rm -rf ${HADOOP_HOME}/logs/*
#mkdir -p "${HADOOP_LOG_DIR}"
#if [ ! "$?" = "0" ]; then mr_trace "Error in mkdir ${HADOOP_LOG_DIR}" ; fi

export PATH=$HADOOP_HOME/bin:$MH_HOME/bin:$PATH

#### Set up the configuration
# Make sure number of nodes is the same as what you have requested from PBS
# usage: ${MY_HADOOP_HOME}/bin/myhadoop-configure.sh -h
mr_trace "Set up the configurations for myHadoop"
${MY_HADOOP_HOME}/bin/myhadoop-configure.sh -n ${PBS_NUM_NODES} -c ${HADOOP_CONF_DIR} -s /local_scratch/$USER/$PBS_JOBID

#### Start the Hadoop cluster
start_hadoop

mr_trace "wait for hadoop ready, sleep 50 ..."
sleep 50

#### Run your jobs here
mr_trace "Run some test Hadoop jobs"
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -mkdir Data
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -copyFromLocal /home/srkrishnan/Data/gutenberg Data
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -ls Data/gutenberg
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} jar ${HADOOP_HOME}/hadoop-0.20.2-examples.jar wordcount Data/gutenberg Outputs
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -ls Outputs
. ${DN_EXEC1}/mod-share-worker.sh
echo
mapred_main

sleep $(( 10 * 60 ))

#### Stop the Hadoop cluster
stop_hadoop

#### Clean up the working directories after job completion
mr_trace "Clean up"
${MY_HADOOP_HOME}/bin/myhadoop-cleanup.sh -n ${PBS_NUM_NODES}
mr_trace "Done hadoop"
