#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief boot hadoop in HPC PBS
##
## To setup the hadoop in HPC PBS environment, you need to install myhadoop,
## and add the patch for the hadoop config files:
##     cd software/bin/hadoop-2.7.1/etc/hadoop
##     patch -p1 < ~/software/src/myhadoop-glennklockwood-git/myhadoop-2.2.0.patch
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
#DN_EXEC=`echo "$0" | ${EXEC_AWK} -F/ '{b=$1; for (i=2; i < NF; i ++) {b=b "/" $(i)}; print b}'`
DN_EXEC=$(dirname $(my_getpath "$0") )
if [ ! "${DN_EXEC}" = "" ]; then
    DN_EXEC="$(my_getpath "${DN_EXEC}")/"
else
    DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
DN_BIN="$(my_getpath "${DN_TOP}/bin/")"
DN_EXEC="$(my_getpath ".")"
DN_LIB="$(my_getpath "${DN_TOP}/lib/")"
#####################################################################
if [ -f "${DN_BIN}/mod-setenv-hadoop.sh" ]; then
.   ${DN_BIN}/mod-setenv-hadoop.sh
else
    mr_trace "Error: not found file ${DN_BIN}/mod-setenv-hadoop.sh"
    exit 1
fi

source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libfs.sh
source ${DN_LIB}/libconfig.sh
source ${DN_LIB}/libhadoop.sh
source ${DN_EXEC}/libapp.sh

#####################################################################
# sum the nodes of same or greater # cores

## @fn convert_avail_settings()
## @brief sum the nodes of same or greater number cores
##
convert_avail_settings() {
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

## @fn get_optimized_settings()
## @brief find the fit settings
## @param max_cores the # of task
## @param mem_per_core the required memory for each task, GB
##
get_optimized_settings() {
    local PARAM_MAXCORES=$1
    shift
    local PARAM_MEM_PER_CORE=$1
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

## @fn get_sim_tasks()
## @brief get # of simulation tasks from the config files in folder specified by argument
## @param dn_conf the config directory
##
get_sim_tasks() {
    local PARAM_DN_CONF=$1
    shift

    if [ ! -d "${PARAM_DN_CONF}" ]; then
        mr_trace "not exist file $PARAM_DN_CONF"
        echo 0
        return
    fi
    TASKS=0
    find_file "${PARAM_DN_CONF}" -maxdepth 1 -name "config*" \
        | (TASKS=0;
        while read get_sim_tasks_tmp_a; do
            A=$(libapp_get_tasks_number_from_config "$get_sim_tasks_tmp_a")
            TASKS=$(( $TASKS + $A ))
            mr_trace "get_sim_tasks got $A cores for file $get_sim_tasks_tmp_a"
        done;
        echo $TASKS)
}

## @fn create_mrsystem_config_pbs()
## @brief create mrsystem config file for PBS
## @param nodes the number of nodes
## @param cores the number of cores of the cpu/gpu for each node
## @param fn_config the config file name
##
create_mrsystem_config_pbs() {
    local PARAM_NODES=$1
    shift
    local PARAM_CORES=$1
    shift
    local PARAM_FN_CONFIG=$1
    shift

    HDFF_USER=${USER}
    sed -i -e "s|^HDFF_USER=.*$|HDFF_USER=${HDFF_USER}|" "${PARAM_FN_CONFIG}"

    HDFF_DN_BASE="file:///scratch2/$USER/output-${HDFF_PROJ_ID}/"
    sed -i -e "s|^HDFF_DN_BASE=.*$|HDFF_DN_BASE=${HDFF_DN_BASE}|" "${PARAM_FN_CONFIG}"

    # set cores in mrsystem.conf file
    sed -i -e "s|^HDFF_NUM_CLONE=.*$|HDFF_NUM_CLONE=${PARAM_CORES}|" "${PARAM_FN_CONFIG}"
    sed -i -e "s|^HDFF_TOTAL_NODES=.*$|HDFF_TOTAL_NODES=${PARAM_NODES}|" "${PARAM_FN_CONFIG}"

    # output dir
    #HDFF_DN_OUTPUT="hdfs:///user/${USER}/output-${HDFF_PROJ_ID}/"
    #HDFF_DN_OUTPUT="file://$HOME/output-${HDFF_PROJ_ID}/"
    #HDFF_DN_OUTPUT="file:///scratch1/$USER/output-${HDFF_PROJ_ID}/"
    HDFF_DN_OUTPUT="${HDFF_DN_BASE}"
    sed -i -e "s|^HDFF_DN_OUTPUT=.*$|HDFF_DN_OUTPUT=${HDFF_DN_OUTPUT}|" "${PARAM_FN_CONFIG}"

    # scratch(temp) dir
    #HDFF_DN_SCRATCH="/tmp/${USER}/working-${HDFF_PROJ_ID}/"
    #HDFF_DN_SCRATCH="/run/shm/${USER}/working-${HDFF_PROJ_ID}/"
    #HDFF_DN_SCRATCH="/dev/shm/${USER}/working-${HDFF_PROJ_ID}/"
    #HDFF_DN_SCRATCH="/local_scratch/\$USER/working-${HDFF_PROJ_ID}/"
    HDFF_DN_SCRATCH="/dev/shm/${USER}/working-${HDFF_PROJ_ID}/"
    sed -i -e "s|^HDFF_DN_SCRATCH=.*$|HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}|" "${PARAM_FN_CONFIG}"

    # the directory for save the un-tar binary files
    HDFF_DN_BIN=""
    sed -i -e "s|^HDFF_DN_BIN=.*$|HDFF_DN_BIN=${HDFF_DN_BIN}|" "${PARAM_FN_CONFIG}"

    # tar the binary and save it to HDFS for the node extract it later
    # the tar file for application exec
    HDFF_PATHTO_TAR_APP=""
    sed -i -e "s|^HDFF_PATHTO_TAR_APP=.*$|HDFF_PATHTO_TAR_APP=${HDFF_PATHTO_TAR_APP}|" "${PARAM_FN_CONFIG}"

    # the HDFS path to this project
    HDFF_PATHTO_TAR_MRNATIVE=""
    sed -i -e "s|^HDFF_PATHTO_TAR_MRNATIVE=.*$|HDFF_PATHTO_TAR_MRNATIVE=${HDFF_PATHTO_TAR_MRNATIVE}|" "${PARAM_FN_CONFIG}"
}

#####################################################################
mr_trace "DN_TOP=${DN_TOP}; DN_BIN=${DN_BIN}; DN_LIB=${DN_LIB}; DN_EXEC=${DN_EXEC};"

# read basic config from mrsystem.conf
# such as HDFF_PROJ_ID, HDFF_NUM_CLONE etc
read_config_file "${DN_TOP}/mrsystem.conf"

read_config_file "${DN_EXEC}/mrsystem-working.conf"
libapp_prepare_app_binary

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

#config
MH_SCRATCH_DIR=/dev/shm/$USER/$MH_JOBID
grep MH_SCRATCH_DIR "myhadoop.conf"
if [ $? = 0 ]; then
    sed -i -e "s|^MH_SCRATCH_DIR=.*$|MH_SCRATCH_DIR=${MH_SCRATCH_DIR}|" "myhadoop.conf"
else
    echo "MH_SCRATCH_DIR=${MH_SCRATCH_DIR}" >> "myhadoop.conf"
fi

export HADOOP_CONF_DIR=${MH_WORKDIR}/hadoopconfigs-$MH_JOBID
grep HADOOP_CONF_DIR "myhadoop.conf"
if [ $? = 0 ]; then
    sed -i -e "s|^HADOOP_CONF_DIR=.*$|HADOOP_CONF_DIR=${HADOOP_CONF_DIR}|" "myhadoop.conf"
else
    echo "HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> "myhadoop.conf"
fi

#####################################################################
#get the # of needed nodes from config-xxx.sh file
NEEDED_CORES=$(get_sim_tasks ${DN_EXEC}/input)
# the memory in GB for each core
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

# set the generated config file
FN_CONFIG_WORKING="${DN_EXEC}/mrsystem-working.conf"
rm_f_dir "${FN_CONFIG_WORKING}"
copy_file "${DN_TOP}/mrsystem.conf" "${FN_CONFIG_WORKING}"
FN_CONF_SYS="${FN_CONFIG_WORKING}"
create_mrsystem_config_pbs "$NODES" "$CORES" "${FN_CONFIG_WORKING}"

#####################################################################
hadoop_set_memory "${HADOOP_HOME}" "${MEM}"

mr_trace "needed cores=$NEEDED_CORES"

#ARG_OTHER="-o pbs_hadoop_run.stdout -e pbs_hadoop_run.stderr"
if [ ! -x "$(which qsub)" ]; then
    mr_trace "Error: not found 'qsub'!"
    exit 1
fi

if [ -f "${DN_BIN}/mod-hadooppbs-jobmain.sh" ]; then
    $MYEXEC qsub -N mrnativetask -l $REQ ${ARG_OTHER} "${DN_BIN}/mod-hadooppbs-jobmain.sh"
else
    mr_trace "Error: not found file ${DN_BIN}/mod-hadooppbs-jobmain.sh"
    exit 1
fi

mr_trace "waitting for queueing ..."
sleep 3
qstat -anu ${USER}


mr_trace "you may access the web page: http://firstnode:8088"

