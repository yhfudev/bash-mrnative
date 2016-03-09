#!/bin/bash

#####################################################################
mr_trace () {
    echo "$(date +"%Y-%m-%d %H:%M:%S,%N" | cut -c1-23) [self=${BASHPID},$(basename $0)] $@" 1>&2
}

#####################################################################
# Set this to location of myHadoop
export MY_HADOOP_HOME="/home/$USER/software/src/myhadoop-glennklockwood-git/"
if [ ! -d "${MY_HADOOP_HOME}" ]; then
    export MY_HADOOP_HOME="/home/$USER/Downloads/hadoop/hadoopsys-myhadoop/myhadoop-svn/myHadoop-core"
fi
export MH_HOME=${MY_HADOOP_HOME}

#####################################################################
if [ ! -d "${JAVA_HOME}" ]; then
    export JAVA_HOME="/home/$USER/software/bin/jdk1.7.0_51"
fi
if [ ! -d "${JAVA_HOME}" ]; then
    export JAVA_HOME="/usr/java/latest"
fi
if [ ! -d "${JAVA_HOME}" ]; then
    export JAVA_HOME="/software/java/1.7.0_51/"
fi

#####################################################################
# Set this to the location of the Hadoop installation

export HADOOP_HOME="/usr/hdp/current/hadoop-client/"
if [ ! -d "${HADOOP_HOME}" ]; then
    export HADOOP_HOME="/opt/applications/hadoop-2.7.1"
fi
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
export PATH=$PATH:$HADOOP_HOME/bin

#####################################################################
EXEC_HADOOP=$(which hadoop)
if [ ! -x "${EXEC_HADOOP}" ]; then
if [ -d "${HADOOP_CONF_DIR}" ]; then
    EXEC_HADOOP="${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR}"
fi
fi

HADOOP_JAR_STREAMING=/usr/hdp/current/hadoop-mapreduce-client/hadoop-streaming.jar
if [ ! -f "${HADOOP_JAR_STREAMING}" ]; then
    HADOOP_JAR_STREAMING=${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-streaming-2.7.1.jar
fi
if [ ! -f "${HADOOP_JAR_STREAMING}" ]; then
    HADOOP_JAR_STREAMING=${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-streaming-2.3.0.jar
fi
if [ ! -f "${HADOOP_JAR_STREAMING}" ]; then
    HADOOP_JAR_STREAMING=/usr/lib/hadoop-0.20-mapreduce/contrib/streaming/hadoop-streaming-2.0.0-mr1-cdh4.4.0.jar
fi
if [ ! -f "${HADOOP_JAR_STREAMING}" ]; then
    HADOOP_JAR_STREAMING=/usr/lib/hadoop-mapreduce/hadoop-streaming.jar
fi

#####################################################################
start_hadoop () {
    mr_trace "Start all Hadoop daemons"
    if [ -x "${HADOOP_HOME}/sbin/start-yarn.sh" ]; then
        ${HADOOP_HOME}/sbin/start-dfs.sh && ${HADOOP_HOME}/sbin/start-yarn.sh

        mr_trace "wait for hadoop ready, sleep 15 ..."
        sleep 15

    elif [ -x "${HADOOP_HOME}/bin/start-all.sh" ]; then
        ${HADOOP_HOME}/bin/start-all.sh

        mr_trace "wait for hadoop ready, sleep 15 ..."
        sleep 15

    else
        mr_trace "Warning: Not found ${HADOOP_HOME}/bin/start-all.sh"
        #exit 1
    fi
    #${HADOOP_HOME}/bin/hadoop dfsadmin -safemode leave
    echo
    jps
}

stop_hadoop () {
    mr_trace "Stop all Hadoop daemons"
    jps
    if [ -x "${HADOOP_HOME}/sbin/stop-yarn.sh" ]; then
        ${HADOOP_HOME}/sbin/stop-yarn.sh && ${HADOOP_HOME}/sbin/stop-dfs.sh

    elif [ -x "${HADOOP_HOME}/bin/stop-all.sh" ]; then
        ${HADOOP_HOME}/bin/stop-all.sh

    else
        mr_trace "Warning: Not found ${HADOOP_HOME}/bin/stop-all.sh"
        #exit 1
    fi
    echo
    jps
}
