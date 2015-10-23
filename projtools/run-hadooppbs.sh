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
  cd "${DN}" > /dev/null 2>&1
  DN=$(pwd)
  cd - > /dev/null 2>&1
  echo "${DN}/${FN}"
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
#####################################################################

rm -f pbs_hadoop_run.stderr
rm -f pbs_hadoop_run.stdout
rm -rf hadoopconfig-*
rm -f /scratch1/$USER/project/myhadoop-example/pbs_hadoop_run.stderr
rm -f /scratch1/$USER/project/myhadoop-example/pbs_hadoop_run.stdout
rm -rf /scratch1/$USER/project/myhadoop-example/hadoopconfig-*

# sum the nodes of same or greater # cores
convert_avail_settings () {
    MYCORES=0
    MYMEM=0
    MYNODES=0
    while read CORES MEM NODES ; do
    if [ ! "${MYCORES}" = "${CORES}" ]; then
        echo "${MYCORES} ${MYMEM} ${MYNODES}"
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
    if [ ! "${MYCORES}" = "0" ]; then
        echo "${MYCORES} ${MYMEM} ${MYNODES}"
    fi
}

# find the fit settings
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
    #echo "ARGS: '${PARAM_MAXCORES} ${PARAM_MEM_PER_CORE}'"
    convert_avail_settings \
        | awk -v MAXC=$PARAM_MAXCORES -v MPC=$PARAM_MEM_PER_CORE 'BEGIN{fit=0; avail_c=0; avail_m=0; avail_n=0;}{cores=$1; mem=$2; nodes=$3; if (fit==0 && avail_c*avail_n <= cores*nodes && cores > 0 && mem/cores >= MPC) {avail_c = cores; avail_n = nodes; avail_m = mem;} if (fit==0 && MAXC <= cores * nodes && cores > 0 && MC <= mem / cores) {avail_c = cores; avail_n = nodes; avail_m = mem; fit=1;} }END{if (avail_c * avail_n < MAXC) {print avail_c " " avail_m " " avail_n;} else {printf("%d %d %d\n", avail_c, avail_m, (MAXC + avail_c - 1) / avail_c);}}'
}

# get # of simulation tasks from a config file
get_sim_tasks_each_file () {
    NUM_SCHE=0
    NUM_NODES=0
    NUM_TYPE=0
    while read get_sim_tasks_each_file_tmp_a; do
        A=$( echo $get_sim_tasks_each_file_tmp_a | grep LIST_TYPES | sed -e 's|LIST_TYPES="\(.*\)"$|\1|' )
        if [ ! "$A" = "" ]; then
            arr=($A)
            NUM_TYPE=${#arr[@]}
            #echo "$(basename $0) [DBG] got type=$NUM_TYPE, A=$A, from line $get_sim_tasks_each_file_tmp_a" 1>&2
        fi
        A=$( echo $get_sim_tasks_each_file_tmp_a | grep LIST_NODE_NUM | sed -e 's|LIST_NODE_NUM="\(.*\)"$|\1|' )
        if [ ! "$A" = "" ]; then
            arr=($A)
            NUM_NODES=${#arr[@]}
            #echo "$(basename $0) [DBG] got node=$NUM_NODES, A=$A, from line $get_sim_tasks_each_file_tmp_a" 1>&2
        fi
        A=$( echo $get_sim_tasks_each_file_tmp_a | grep LIST_SCHEDULERS | sed -e 's|LIST_SCHEDULERS="\(.*\)"$|\1|' )
        if [ ! "$A" = "" ]; then
            arr=($A)
            NUM_SCHE=${#arr[@]}
            #echo "$(basename $0) [DBG] got sch=$NUM_SCHE, A=$A, from line $get_sim_tasks_each_file_tmp_a" 1>&2
        fi
    done
    #echo "type=$NUM_TYPE, sch=$NUM_SCHE, node=$NUM_NODES"
    echo "$(basename $0) [DBG] got type=$NUM_TYPE, sch=$NUM_SCHE, node=$NUM_NODES" 1>&2
    echo $(( $NUM_TYPE * $NUM_SCHE * $NUM_NODES ))
}

# get # of simulation tasks from the config files in folder projconfigs
get_sim_tasks () {
    PARAM_DN_CONF=$1
    shift

    if [ ! -d "${PARAM_DN_CONF}" ]; then
        echo "$(basename $0) [DBG] not exit file $PARAM_DN_CONF" 1>&2
        echo 0
        return
    fi
    TASKS=0
    find "${PARAM_DN_CONF}" -maxdepth 1 -name "config*" \
        | (TASKS=0;
        while read get_sim_tasks_tmp_a; do
            A=$(cat $get_sim_tasks_tmp_a | get_sim_tasks_each_file)
            TASKS=$(( $TASKS + $A ))
            echo "$(basename $0) [DBG] got $A cores for file $a" 1>&2
        done;
        echo $TASKS)
}

#get the # of needed nodes from config-xxx.sh file
NEEDED_CORES=$(get_sim_tasks ../mytest)
NEEDED_MEM_PER_CORE=1

echo "$(basename $0) [DBG] needed cores=$NEEDED_CORES" 1>&2
#debug:
#NEEDED_CORES=3000
#exit 0 # debug

echo "$(basename $0) [DBG] checking cores quota ..." 1>&2
checkqueuecfg > tmp-checkqueuecfg.txt
MAX_CORES=$(cat tmp-checkqueuecfg.txt  | grep "(" | awk 'BEGIN{max=0;}{if ($4 > 0) {a=split($1,b,"-"); if (b[2]) max=b[2]; } }END{print max;}')
if (( $NEEDED_CORES > $MAX_CORES )) ; then
    NEEDED_CORES=$MAX_CORES
fi

echo "$(basename $0) [DBG] checking avail cores ..." 1>&2
# get the free nodes list: (cores, mem, num)
whatsfree | grep -v "PHASE 0" | grep -v "TOTAL NODES" \
    | awk 'BEGIN{cnt=0;}{nodes=$8; cores=$19; mem=$21; if (nodes > 0) print cores " " (0+mem) " " nodes;}END{}' \
    | grep -v "  0" | sort -n -r -k1 -k2 -k3 \
    > tmp-whatsfree.txt

A=$(cat tmp-whatsfree.txt | get_optimized_settings $NEEDED_CORES $NEEDED_MEM_PER_CORE )
if [ "$A" = "" ]; then
    echo "Error in get # of nodes."
    exit 1
fi
REQ=$(echo $A | awk '{print "select=" $3 ":ncpus=" $1 ":mem=" ($2 - 2) "gb";}')
CORES=$(echo $A | awk '{print $1;}')
MEM=$(echo $A | awk '{print ($2-2)*1024;}')

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
if (( ${MR_JOB_MEM} < ${MEM}/${CORES} )) ; then
    MR_JOB_MEM=$(( ${MEM}/${CORES} ))
fi
if (( ${MR_JOB_MEM} > ${MEM} )) ; then
    MR_JOB_MEM=${MEM}
fi

. ./mod-hadooppbs-setenv.sh
if [ -d "${HADOOP_HOME}/conf" ]; then           # Hadoop 1.x
    echo "$(basename $0) [DBG] set hadoop 1.x memory: cores=$CORES, mem=$MEM; mem/cores=$((${MEM}/${CORES})), mem/cores/2=$((${MEM}/${CORES}/2)), 0.75mem/core=$((${MEM}/${CORES}*3/4))" 1>&2
    cd "${HADOOP_HOME}/conf"
    cp mapred-site.xml.template mapred-site.xml
    sed -i \
        -e  "s|512|$(( ${MR_JOB_MEM}     ))|" \
        -e "s|1024|$(( ${MR_JOB_MEM}*4   ))|" \
        -e  "s|384|$(( ${MR_JOB_MEM}*3/4 ))|" \
        -e  "s|768|$(( ${MR_JOB_MEM}*3   ))|" \
        mapred-site.xml
    cd -

elif [ -d "${HADOOP_HOME}/etc/hadoop" ]; then   # Hadoop 2.x

    echo "$(basename $0) [DBG] set hadoop 2.x memory: cores=$CORES, mem=$MEM; mem/cores=$((${MEM}/${CORES})), mem/cores/2=$((${MEM}/${CORES}/2)), 0.75mem/core=$((${MEM}/${CORES}*3/4))" 1>&2
    cd "${HADOOP_HOME}/etc/hadoop"
    cp mapred-site.xml.template mapred-site.xml
    cp   yarn-site.xml.template   yarn-site.xml
    sed -i \
        -e "s|3072|${MEM}|" \
        -e "s|256|$(( ${MEM}/${CORES} ))|" \
        -e "s|24|${CORES}|" \
        yarn-site.xml

    sed -i \
        -e  "s|512|$(( ${MR_JOB_MEM}     ))|" \
        -e "s|1024|$(( ${MR_JOB_MEM}*4   ))|" \
        -e  "s|384|$(( ${MR_JOB_MEM}*3/4 ))|" \
        -e  "s|768|$(( ${MR_JOB_MEM}*3   ))|" \
        mapred-site.xml
    cd -
else
    echo "unknown hadoop version"
    exit 1
fi

echo "$(basename $0) [DBG] needed cores=$NEEDED_CORES" 1>&2

# set cores in config-sys.sh file
sed -i -e "s|HDFF_NUM_CLONE=.*$|HDFF_NUM_CLONE=$CORES|" "${DN_TOP}/config-sys.sh"

# use scratch
sed -i -e "s|HDFF_DN_OUTPUT=.*$|HDFF_DN_OUTPUT=/scratch1/\$USER/mapreduce-ns2docsis-results/|" "${DN_TOP}/config-sys.sh"

#sed -i -e "s|#PBS -l select=1.*$|#PBS -l $REQ|" "mod-hadooppbs-jobmain.sh"
echo qsub -N ns2ds31 -l $REQ "mod-hadooppbs-jobmain.sh"
qsub -N ns2ds31 -l $REQ "mod-hadooppbs-jobmain.sh"

echo "$(basename $0) [DBG] waitting for queueing ..." 1>&2
sleep 8
qstat -anu ${USER}
