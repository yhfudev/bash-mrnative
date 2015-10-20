#!/bin/bash

# Set this to location of myHadoop 
export MY_HADOOP_HOME="/home/$USER/software/src/myhadoop-svn/myHadoop-core/"
if [ ! -d "${MY_HADOOP_HOME}" ]; then
    export MY_HADOOP_HOME="/home/$USER/Downloads/hadoop/hadoopsys-myhadoop/myhadoop-svn/myHadoop-core"
fi

if [ ! -d "${JAVA_HOME}" ]; then
    export JAVA_HOME="/home/$USER/software/bin/jdk1.7.0_51"
fi
if [ ! -d "${JAVA_HOME}" ]; then
    export JAVA_HOME="/usr/java/latest"
fi
if [ ! -d "${JAVA_HOME}" ]; then
    export JAVA_HOME="/software/java/1.7.0_51/"
fi

# Set this to the location of the Hadoop installation
export HADOOP_HOME="/opt/applications/hadoop-2.3.0"
if [ ! -d "${HADOOP_HOME}" ]; then
    export HADOOP_HOME="/opt/applications/hadoop-1.2.1"
fi
if [ ! -d "${HADOOP_HOME}" ]; then
    export HADOOP_HOME="/home/$USER/software/bin/hadoop-2.3.0/"
fi
if [ ! -d "${HADOOP_HOME}" ]; then
    export HADOOP_HOME="/home/$USER/software/bin/hadoop-1.2.1/"
fi
# don't use /newscratch, the hadoop will write lot to the folder, and it downgrade the perfomance!
#export HADOOP_HOME="/newscratch/$USER/software/hadoop-1.2.1/"
rm -rf ${HADOOP_HOME}/logs/*

# Set this to the location you want to use for HDFS
# Note that this path should point to a LOCAL directory, and
# that the path should exist on all slave nodes
export HADOOP_DATA_DIR="/local_scratch/$USER/hadoop/data"

# Set this to the location where you want the Hadoop logfies
export HADOOP_LOG_DIR="/local_scratch/$USER/hadoop/log"

#if [ ! -d "/local_scratch/" ]; then
if [ 1 = 1 ]; then
export HADOOP_DATA_DIR="/home/$USER/hadoop/hdfs/datatmp"
export HADOOP_LOG_DIR="/home/$USER/hadoop/logs"

# the dir name for HDFS persistent mode
export HDFF_HADOOP_HDFS="/home/$USER/hadoop/hdfs/"

mkdir -p "${HADOOP_LOG_DIR}"
fi

# if use persistent for hadoop, set it to 1
FLG_HDFS_PERSISTENT=1
