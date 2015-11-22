#!/bin/sh
#####################################################################
# run hadoop in HPC PBS
#
# To setup the hadoop, you need to first add the patch for it:
#     cd software/bin/hadoop-2.7.1/etc/hadoop
#     patch -p1 < ~/software/src/myhadoop-glennklockwood-git/myhadoop-2.2.0.patch
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
    DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
DN_EXEC="$(my_getpath "${DN_TOP}/projtools/")"
DN_LIB="$(my_getpath "${DN_TOP}/lib/")"
#####################################################################
source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libfs.sh
source ${DN_LIB}/libconfig.sh
source ${DN_EXEC}/libapp.sh

#####################################################################
# sum the nodes of same or greater # cores
convert_avail_settings () {
    MYCORES=0
    MYMEM=0
    MYNODES=0
    while read CORES MEM NODES ; do
        if [ ! "${MYCORES}" = "${CORES}" ]; then
            if (( ${MYCORES} > 0 )) ; then
                echo "${MYCORES} ${MYMEM} ${MYNODES}"
            fi
            MYCORES=${CORES}
            MYMEM=${MEM}
            MYNODES=${NODES}
        elif [ ! "${MYMEM}" = "${MEM}" ]; then
            echo "${MYCORES} ${MYMEM} ${MYNODES}"
            MYMEM=${MEM}
            MYNODES=$(( ${MYNODES} + ${NODES} ))
        else
            MYMEM=${MEM}
            MYNODES=$(( ${MYNODES} + ${NODES} ))
        fi
    done
    if (( ${MYCORES} > 0 )) ; then
        echo "${MYCORES} ${MYMEM} ${MYNODES}"
    fi
}

# find the fit settings
# ARG 1: the # of task
# ARG 2: the required memory for each task, GB
get_optimized_settings() {
    PARAM_MAXCORES=$1
    shift
    PARAM_MEM_PER_CORE=$1
    shift

    if [ "${PARAM_MAXCORES}" = "" ] ; then
        PARAM_MAXCORES=1
    fi
    if [ "${PARAM_MEM_PER_CORE}" = "" ] ; then
        PARAM_MEM_PER_CORE=0
    fi
    if (( ${PARAM_MAXCORES} < 1 )) ; then
        PARAM_MAXCORES=1
    fi

    cat << EOF > tmp-opt-cores.awk
BEGIN{
    fit=0; avail_c=0; avail_m=0; avail_n=0;
}{
    cores=\$1; mem=\$2; nodes=\$3;
    if (fit==0 && avail_c*avail_n <= cores*nodes && cores > 0 && mem/cores >= MPC) {
        avail_c = cores;
        avail_n = nodes;
        avail_m = mem;
    }
    if (fit==0 && MAXC <= cores * nodes && cores > 0 && MC <= mem / cores) {
        avail_c = cores;
        avail_n = nodes;
        avail_m = mem;
        fit=1;
    }
}END{
    if (avail_c * avail_n < MAXC) {
        print avail_c " " avail_m " " avail_n;
    } else {
        # cores, mem, nodes
        printf("%d %d %d\n", avail_c, avail_m, (MAXC + avail_c - 1) / avail_c);
    }
}
EOF

    #echo "ARGS: '${PARAM_MAXCORES} ${PARAM_MEM_PER_CORE}'"
    convert_avail_settings | awk -v MAXC=$PARAM_MAXCORES -v MPC=$PARAM_MEM_PER_CORE -f tmp-opt-cores.awk
}

# get # of simulation tasks from the config files in folder projconfigs
get_sim_tasks () {
    PARAM_DN_CONF=$1
    shift

    if [ ! -d "${PARAM_DN_CONF}" ]; then
        mr_trace "not exit file $PARAM_DN_CONF"
        echo 0
        return
    fi
    TASKS=0
    find "${PARAM_DN_CONF}" -maxdepth 1 -name "config*" \
        | (TASKS=0;
        while read get_sim_tasks_tmp_a; do
            A=$(cat $get_sim_tasks_tmp_a | libapp_get_tasks_number_from_config)
            TASKS=$(( $TASKS + $A ))
            mr_trace "got $A cores for file $a"
        done;
        echo $TASKS)
}

#get the # of needed nodes from config-xxx.sh file
NEEDED_CORES=$(get_sim_tasks ../mytest)
NEEDED_MEM_PER_CORE=1

mr_trace "needed cores=$NEEDED_CORES"
#debug:
#NEEDED_CORES=3000
#exit 0 # debug

mr_trace "checking cores quota ..."
if [ ! -x "$(which whatsfree)" ]; then
    mr_trace "Error: not found 'checkqueuecfg'!"
    exit 1
fi
checkqueuecfg > tmp-checkqueuecfg.txt
MAX_CORES=$(cat tmp-checkqueuecfg.txt  | grep "(" | grep -v "gpus" | awk 'BEGIN{max=0;}{if ($4 > 0) {a=split($1,b,"-"); if (max<b[2]) max=b[2]; } }END{print max;}')
if (( $NEEDED_CORES > $MAX_CORES )) ; then
    NEEDED_CORES=$MAX_CORES
fi

mr_trace "checking avail cores ..."
if [ ! -x "$(which whatsfree)" ]; then
    mr_trace "Error: not found 'whatsfree'!"
    exit 1
fi
# get the free nodes list: (cores, mem, num)
whatsfree | grep -v 24 | grep -v "PHASE 0" | grep -v "TOTAL NODES" \
    | awk 'BEGIN{cnt=0;}{nodes=$8; cores=$19; mem=$21; if (nodes > 0) print cores " " (0+mem) " " nodes;}END{}' \
    | grep -v "  0" | sort -n -r -k1 -k2 -k3 \
    > tmp-whatsfree.txt

A=$(cat tmp-whatsfree.txt | get_optimized_settings $NEEDED_CORES $NEEDED_MEM_PER_CORE )
if [ "$A" = "" ]; then
    mr_trace "Error in get # of nodes."
    exit 1
fi
REQ=$(echo $A | awk '{print "select=" $3 ":ncpus=" $1 ":mem=" ($2 - 3) "gb";}')
CORES=$(echo $A | awk '{print $1;}')
NODES=$(echo $A | awk '{print $3;}')
MEM=$(echo $A | awk '{print ($2-3)*1024;}')

HDFF_USER=${USER}
sed -i -e "s|HDFF_USER=.*$|HDFF_USER=${HDFF_USER}|" "${DN_TOP}/mrsystem.conf"

HDFF_DN_BASE="file:///scratch1/$USER/${HDFF_PROJ_ID}/"
sed -i -e "s|HDFF_DN_BASE=.*$|HDFF_DN_BASE=${HDFF_DN_BASE}|" "${DN_TOP}/mrsystem.conf"

# set cores in mrsystem.conf file
sed -i -e "s|HDFF_NUM_CLONE=.*$|HDFF_NUM_CLONE=$CORES|" "${DN_TOP}/mrsystem.conf"
sed -i -e "s|HDFF_TOTAL_NODES=.*$|HDFF_TOTAL_NODES=$NODES|" "${DN_TOP}/mrsystem.conf"

# output dir
#HDFF_DN_OUTPUT="hdfs:///user/${USER}/${HDFF_PROJ_ID}/results/"
#HDFF_DN_OUTPUT="file://$HOME/${HDFF_PROJ_ID}/results/"
#HDFF_DN_OUTPUT="file:///scratch1/$USER/${HDFF_PROJ_ID}/results/"
HDFF_DN_OUTPUT="${HDFF_DN_BASE}/results"
sed -i -e "s|HDFF_DN_OUTPUT=.*$|HDFF_DN_OUTPUT=${HDFF_DN_OUTPUT}|" "${DN_TOP}/mrsystem.conf"

# scratch(temp) dir
#HDFF_DN_SCRATCH="/tmp/${USER}/${HDFF_PROJ_ID}/"
#HDFF_DN_SCRATCH="/run/shm/${USER}/${HDFF_PROJ_ID}/"
#HDFF_DN_SCRATCH="/dev/shm/${USER}/${HDFF_PROJ_ID}/"
#HDFF_DN_SCRATCH="/local_scratch/\$USER/${HDFF_PROJ_ID}/"
HDFF_DN_SCRATCH="/dev/shm/${USER}/${HDFF_PROJ_ID}/"
sed -i -e "s|^HDFF_DN_SCRATCH=.*$|HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}|" "${DN_TOP}/mrsystem.conf"

# the directory for save the un-tar binary files
HDFF_DN_BIN=""
sed -i -e "s|^HDFF_DN_BIN=.*$|HDFF_DN_BIN=${HDFF_DN_BIN}|" "${DN_TOP}/mrsystem.conf"

# tar the binary and save it to HDFS for the node extract it later
# the tar file for application exec
HDFF_PATHTO_TAR_APP=""
sed -i -e "s|^HDFF_PATHTO_TAR_APP=.*$|HDFF_PATHTO_TAR_APP=${HDFF_PATHTO_TAR_APP}|" "${DN_TOP}/mrsystem.conf"

# the HDFS path to this project
HDFF_PATHTO_TAR_MRNATIVE=""
sed -i -e "s|^HDFF_PATHTO_TAR_MRNATIVE=.*$|HDFF_PATHTO_TAR_MRNATIVE=${HDFF_PATHTO_TAR_MRNATIVE}|" "${DN_TOP}/mrsystem.conf"

# set the vcores to 1 to let bash script generate multiple processes.
CORES=1
# in this block, you need set two files in the hadoop 2.x config files
# mapred-site.xml.template
# <property>
#     <name>mapreduce.map.memory.mb</name>
#     <value>512</value>
# </property>
# <property>
#     <name>mapreduce.reduce.memory.mb</name>
#     <value>1024</value>
# </property>
# <property>
#     <name>mapreduce.map.java.opts</name>
#     <value>-Xmx384m</value>
# </property>
# <property>
#     <name>mapreduce.reduce.java.opts</name>
#     <value>-Xmx768m</value>
# </property>
#<!-- A value of 0 disables the timeout -->
#<!--
#<property>
#    <name>mapreduce.task.timeout</name>
#    <value>0</value>
#</property>
#-->
#<!-- setting the vcores -->
#<property>
#    <name>mapreduce.map.cpu.vcores</name>
#    <value>1</value>
#</property>
#<property>
#    <name>mapreduce.reduce.cpu.vcores</name>
#    <value>1</value>
#</property>
#
# yarn-site.xml.template
# <property>
#     <name>yarn.nodemanager.resource.memory-mb</name>
#     <value>3072</value>
# </property>
# <property>
#     <name>yarn.scheduler.minimum-allocation-mb</name>
#     <value>256</value>
# </property>
# <property>
#     <name>yarn.scheduler.maximum-allocation-mb</name>
#     <value>3072</value>
# </property>
# <property>
#     <name>yarn.nodemanager.vmem-check-enabled</name>
#     <value>false</value>
#     <description>Whether virtual memory limits will be enforced for containers</description>
# </property>
# <property>
#     <name>yarn.nodemanager.vmem-pmem-ratio</name>
#     <value>4</value>
#     <description>Ratio between virtual memory to physical memory when setting memory limits for containers</description>
# </property>
#<!-- setting the vcores -->
#<property>
#    <name>yarn.app.mapreduce.am.resource.cpu-vcores</name>
#    <value>1</value>
#</property>
#<property>
#    <name>yarn.scheduler.maximum-allocation-vcores</name>
#    <value>24</value>
#</property>
#<property>
#    <name>yarn.scheduler.minimum-allocation-vcores</name>
#    <value>1</value>
#</property>
#<property>
#    <name>yarn.nodemanager.resource.cpu-vcores</name>
#    <value>24</value>
#</property>
#
# or hadoop 1.x config files mapred-site.xml.template
# <property>
#     <name>mapred.job.map.memory.mb</name>
#     <value>512</value>
# </property>
# <property>
#     <name>mapred.job.reduce.memory.mb</name>
#     <value>1024</value>
# </property>
# <property>
#     <name>mapred.map.child.java.opts</name>
#     <value>-Xmx384m</value>
# </property>
# <property>
#     <name>mapred.reduce.child.java.opts</name>
#     <value>-Xmx768m</value>
# </property>
MR_JOB_MEM=2048
MR_JOB_MEM=8192
MR_JOB_MEM=512
if (( ${MR_JOB_MEM} < ${MEM}/${CORES} )) ; then
    MR_JOB_MEM=$(( ${MEM}/${CORES} ))
fi
if (( ${MR_JOB_MEM} * 6 > ${MEM} )) ; then
    MR_JOB_MEM=$(( ${MEM} / 6 ))
fi

. ./mod-setenv-hadoop.sh
if [ -d "${HADOOP_HOME}/conf" ]; then           # Hadoop 1.x
    mr_trace "set hadoop 1.x memory: cores=$CORES, mem=$MEM; mem/cores=$((${MEM}/${CORES})), MR_JOB_MEM=${MR_JOB_MEM}"
    DN_ORIG7=$(pwd)
    cd "${HADOOP_HOME}/conf"
    cp mapred-site.xml.template mapred-site.xml
    sed -i \
        -e  "s|<value>512</value>|<value>$(( ${MR_JOB_MEM}     ))</value>|" \
        -e "s|<value>1024</value>|<value>$(( ${MR_JOB_MEM}*3   ))</value>|" \
        -e  "s|<value>-Xmx384m</value>|<value>-Xmx$(( ${MR_JOB_MEM}*3/4 ))m</value>|" \
        -e  "s|<value>-Xmx768m</value>|<value>-Xmx$(( ${MR_JOB_MEM}*3*3/4   ))m</value>|" \
        mapred-site.xml
    cd "${DN_ORIG7}"

elif [ -d "${HADOOP_HOME}/etc/hadoop" ]; then   # Hadoop 2.x

    mr_trace "set hadoop 2.x memory: cores=$CORES, mem=$MEM; mem/cores=$((${MEM}/${CORES})), MR_JOB_MEM=${MR_JOB_MEM}"
    DN_ORIG7=$(pwd)
    cd "${HADOOP_HOME}/etc/hadoop"
    cp mapred-site.xml.template mapred-site.xml
    cp   yarn-site.xml.template   yarn-site.xml

    sed -i \
        -e "s|<value>3072</value>|<value>${MEM}</value>|" \
        -e  "s|<value>256</value>|<value>${MR_JOB_MEM}</value>|" \
        -e   "s|<value>24</value>|<value>${CORES}</value>|" \
        yarn-site.xml

    sed -i \
        -e  "s|<value>512</value>|<value>$(( ${MR_JOB_MEM}     ))</value>|" \
        -e "s|<value>1024</value>|<value>$(( ${MR_JOB_MEM}*3   ))</value>|" \
        -e  "s|<value>-Xmx384m</value>|<value>-Xmx$(( ${MR_JOB_MEM}*3/4 ))m</value>|" \
        -e  "s|<value>-Xmx768m</value>|<value>-Xmx$(( ${MR_JOB_MEM}*3*3/4   ))m</value>|" \
        mapred-site.xml
    cd "${DN_ORIG7}"
else
    mr_trace "unknown hadoop version"
    exit 1
fi

mr_trace "needed cores=$NEEDED_CORES"

#ARG_OTHER="-o pbs_hadoop_run.stdout -e pbs_hadoop_run.stderr"
mr_trace qsub -N ns2ds31 -l $REQ ${ARG_OTHER} "mod-hadooppbs-jobmain.sh"
if [ ! -x "$(which qsub)" ]; then
    mr_trace "Error: not found 'qsub'!"
    exit 1
fi
qsub -N ns2ds31 -l $REQ ${ARG_OTHER} "mod-hadooppbs-jobmain.sh"

mr_trace "waitting for queueing ..."
sleep 8
qstat -anu ${USER}
