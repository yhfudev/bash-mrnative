#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief boot hadoop in LAN hosts
##
## To setup the hadoop in LAN environment, you need to install myhadoop,
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
source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libfs.sh
source ${DN_LIB}/libconfig.sh
source ${DN_LIB}/libhadoop.sh
source ${DN_EXEC}/libapp.sh

#####################################################################
# read basic config from mrsystem.conf
# such as HDFF_PROJ_ID, HDFF_NUM_CLONE etc
read_config_file "${DN_TOP}/mrsystem.conf"


mr_trace "DN_TOP=${DN_TOP}; DN_BIN=${DN_BIN}; DN_LIB=${DN_LIB}; DN_EXEC=${DN_EXEC};"

#####################################################################
# sum the nodes of same or greater # cores

## @fn create_mrsystem_config_lan()
## @brief create mrsystem config file for LAN hosts
## @param nodes the number of nodes
## @param cores the number of cores of the cpu/gpu for each node
## @param fn_config the config file name
##
create_mrsystem_config_lan() {
    local PARAM_NODES=$1
    shift
    local PARAM_CORES=$1
    shift
    local PARAM_FN_CONFIG=$1
    shift

    HDFF_USER=${USER}
    sed -i -e "s|^HDFF_USER=.*$|HDFF_USER=${HDFF_USER}|" "${PARAM_FN_CONFIG}"

    HDFF_DN_BASE="file:///dev/shm/$USER/output-${HDFF_PROJ_ID}/"
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
    HDFF_DN_SCRATCH="/dev/shm/${HDFF_USER}/working-${HDFF_PROJ_ID}/"
    sed -i -e "s|^HDFF_DN_SCRATCH=.*$|HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}|" "${PARAM_FN_CONFIG}"

    # the directory for save the un-tar binary files
    HDFF_DN_BIN="/dev/shm/${HDFF_USER}/working-${HDFF_PROJ_ID}/bin"
    sed -i -e "s|^HDFF_DN_BIN=.*$|HDFF_DN_BIN=${HDFF_DN_BIN}|" "${PARAM_FN_CONFIG}"

    # tar the binary and save it to HDFS for the node extract it later
    # the tar file for application exec
    HDFF_PATHTO_TAR_APP="${HDFF_DN_BASE}/${HDFF_FN_TAR_APP}"
    sed -i -e "s|^HDFF_PATHTO_TAR_APP=.*$|HDFF_PATHTO_TAR_APP=${HDFF_PATHTO_TAR_APP}|" "${PARAM_FN_CONFIG}"

    # the HDFS path to this project
    HDFF_PATHTO_TAR_MRNATIVE="${HDFF_DN_BASE}/${HDFF_FN_TAR_MRNATIVE}"
    sed -i -e "s|^HDFF_PATHTO_TAR_MRNATIVE=.*$|HDFF_PATHTO_TAR_MRNATIVE=${HDFF_PATHTO_TAR_MRNATIVE}|" "${PARAM_FN_CONFIG}"
}


print_list_nodes() {
    local PARAM_LIST_NODES=$1
    shift

    IFS=':'; array_nodes=($PARAM_LIST_NODES)
    for i in "${!array_nodes[@]}"; do
        echo "${array_nodes[i]}"
    done
}

#####################################################################
MH_WORKDIR=$PWD
MH_JOBID=$$

#config
MH_LIST_NODES=localhost
grep MH_LIST_NODES "myhadoop.conf"
if [ ! $? = 0 ]; then
    echo "MH_LIST_NODES=${MH_LIST_NODES}" >> "myhadoop.conf"
fi

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

read_config_file "myhadoop.conf"
IFS=':'; array_nodes=($MH_LIST_NODES)
NODES=${#array_nodes[*]}

mr_trace "got MH_LIST_NODES=$MH_LIST_NODES"


#####################################################################
# get CORES
ONE_HOST=$(print_list_nodes "${MH_LIST_NODES}" | tail -n 1)
CORES=$(ssh ${ONE_HOST} "cat /proc/cpuinfo" | grep "core id" | sort | uniq | wc -l)
MEM=$(ssh ${ONE_HOST} "cat /proc/meminfo" | grep MemTotal | awk '{print int($2 / 1000);}')

mr_trace "Single Host, CORES=${CORES}; MEM=${MEM}MB;"

# set the generated config file
FN_CONFIG_WORKING="${DN_EXEC}/mrsystem-working.conf"
rm_f_dir "${FN_CONFIG_WORKING}"
copy_file "${DN_TOP}/mrsystem.conf" "${FN_CONFIG_WORKING}"
FN_CONF_SYS="${FN_CONFIG_WORKING}"

mr_trace "create_mrsystem_config_lan $NODES $CORES ${FN_CONFIG_WORKING}"
create_mrsystem_config_lan "$NODES" "$CORES" "${FN_CONFIG_WORKING}"


if [ -f "${DN_BIN}/mod-setenv-hadoop.sh" ]; then
.   ${DN_BIN}/mod-setenv-hadoop.sh
else
    mr_trace "Error: not found file ${DN_BIN}/mod-setenv-hadoop.sh"
    exit 1
fi

#####################################################################
mr_trace hadoop_set_memory "${HADOOP_HOME}" "${MEM}"
hadoop_set_memory "${HADOOP_HOME}" "${MEM}"

# start hadoop

if [ -f "${DN_BIN}/mod-hadooppbs-jobmain.sh" ]; then
    "${DN_BIN}/mod-hadooppbs-jobmain.sh" &
else
    mr_trace "Error: not found file ${DN_BIN}/mod-hadooppbs-jobmain.sh"
    exit 1
fi


