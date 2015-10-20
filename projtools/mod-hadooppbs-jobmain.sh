#!/bin/bash
#PBS -N myhadoop-0.2
#PBS -l select=5:ncpus=16:mem=61gb
#PBS -o pbs_hadoop_run.stdout
#PBS -e pbs_hadoop_run.stderr
#PBS -q workq
#PBS -l walltime=72:00:00
#PBS -M yfu@clemson.edu
#PBS -m ea

# the number of nodes: select=xxx
NUM_NODES=5

source /etc/profile.d/modules.sh
module purge
module add java

cd $PBS_O_WORKDIR

export PROJ_HOME=/home/$USER/software/src/furnace
if [ ! -d "${PROJ_HOME}" ]; then
  export PROJ_HOME=/home/$USER/temp/furnace
fi
DN_EXEC1="${PROJ_HOME}/bin"

### Run the myHadoop environment script to set the appropriate variables
#
# Note: ensure that the variables are set correctly in bin/mod-hadooppbs-setenv.sh
if [ -f "${DN_EXEC1}/mod-hadooppbs-setenv.sh" ]; then
. ${DN_EXEC1}/mod-hadooppbs-setenv.sh
else
echo "Error: not found file ${DN_EXEC1}/mod-hadooppbs-setenv.sh"
exit 1
fi
#### Set this to the directory where Hadoop configs should be generated
# Don't change the name of this variable (HADOOP_CONF_DIR) as it is
# required by Hadoop - all config files will be picked up from here
#
# Make sure that this is accessible to all nodes
export HADOOP_CONF_DIR="${DN_EXEC1}/hadoopconfig-$PBS_JOBID"
mkdir -p "${HADOOP_CONF_DIR}"

#### Set up the configuration
# Make sure number of nodes is the same as what you have requested from PBS
# usage: ${MY_HADOOP_HOME}/bin/pbs-configure.sh -h
echo "Set up the configurations for myHadoop"

FLG_FMT_HDFS=0
if [ "${FLG_HDFS_PERSISTENT}" = "1" ]; then
  # this is the non-persistent mode
  ${MY_HADOOP_HOME}/bin/pbs-configure.sh -n ${NUM_NODES} -c ${HADOOP_CONF_DIR}
  FLG_FMT_HDFS=1
else
  # this is the persistent mode
  ${MY_HADOOP_HOME}/bin/pbs-configure.sh -n ${NUM_NODES} -c ${HADOOP_CONF_DIR} -p -d "${HDFF_HADOOP_HDFS}"
  if [ ! -d "${HDFF_HADOOP_HDFS}" ]; then
    FLG_FMT_HDFS=1
  fi
fi
echo

#### Format HDFS, if this is the first time or not a persistent instance
if [ "${FLG_FMT_HDFS}" = "1" ]; then
  echo "Format HDFS"
  ${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} namenode -format
  echo
fi

#### Start the Hadoop cluster
echo "Start all Hadoop daemons"
if [ -x "${HADOOP_HOME}/sbin/start-yarn.sh" ]; then
  ${HADOOP_HOME}/sbin/start-dfs.sh && ${HADOOP_HOME}/sbin/start-yarn.sh

elif [ -x "${HADOOP_HOME}/bin/start-all.sh" ]; then
  ${HADOOP_HOME}/bin/start-all.sh

else
  echo "Not found ${HADOOP_HOME}/bin/start-all.sh"
  exit 1
fi
#${HADOOP_HOME}/bin/hadoop dfsadmin -safemode leave
echo
jps

echo "wait for hadoop ready, sleep 30 ..."
sleep 30

#### Run your jobs here
echo "Run some test Hadoop jobs"
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -mkdir Data
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -copyFromLocal /home/srkrishnan/Data/gutenberg Data
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -ls Data/gutenberg
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} jar ${HADOOP_HOME}/hadoop-0.20.2-examples.jar wordcount Data/gutenberg Outputs
#${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR} dfs -ls Outputs
. ${DN_EXEC1}/mod-share-worker.sh
echo

#### Stop the Hadoop cluster
echo "Stop all Hadoop daemons"
jps
if [ -x "${HADOOP_HOME}/sbin/stop-yarn.sh" ]; then
  ${HADOOP_HOME}/sbin/stop-yarn.sh && ${HADOOP_HOME}/sbin/stop-dfs.sh

elif [ -x "${HADOOP_HOME}/bin/stop-all.sh" ]; then
  ${HADOOP_HOME}/bin/stop-all.sh

else
  echo "Not found ${HADOOP_HOME}/bin/stop-all.sh"
  exit 1
fi
echo
jps

#### Clean up the working directories after job completion
echo "Clean up"
${MY_HADOOP_HOME}/bin/pbs-cleanup.sh -n ${NUM_NODES}
echo
