#!/bin/bash

# Set this to location of myHadoop
export MY_HADOOP_HOME="/home/$USER/software/src/myhadoop-glennklockwood-git/"
if [ ! -d "${MY_HADOOP_HOME}" ]; then
    export MY_HADOOP_HOME="/home/$USER/Downloads/hadoop/hadoopsys-myhadoop/myhadoop-svn/myHadoop-core"
fi
export MH_HOME=${MY_HADOOP_HOME}

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
export HADOOP_HOME="/opt/applications/hadoop-2.7.1"
if [ ! -d "${HADOOP_HOME}" ]; then
    export HADOOP_HOME="/opt/applications/hadoop-2.3.0"
fi
if [ ! -d "${HADOOP_HOME}" ]; then
    export HADOOP_HOME="/opt/applications/hadoop-1.2.1"
fi
if [ ! -d "${HADOOP_HOME}" ]; then
    export HADOOP_HOME="/home/$USER/software/bin/hadoop-2.7.1/"
fi
if [ ! -d "${HADOOP_HOME}" ]; then
    export HADOOP_HOME="/home/$USER/software/bin/hadoop-2.3.0/"
fi
if [ ! -d "${HADOOP_HOME}" ]; then
    export HADOOP_HOME="/home/$USER/software/bin/hadoop-1.2.1/"
fi
# don't use /newscratch, the hadoop will write lot to the folder, and it downgrade the perfomance!
#export HADOOP_HOME="/newscratch/$USER/software/hadoop-1.2.1/"
