#!/bin/bash
#####################################################################
# The script to run the real hadoop jobs,
# this script is the interface between the Map/Reduce scripts and hadoop
#
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

mr_trace "1 DN_TOP=$DN_TOP; DN_EXEC=${DN_EXEC}"

if [ "${DN_TOP}" = "" ]; then
    #DN_EXEC=`echo "$0" | ${EXEC_AWK} -F/ '{b=$1; for (i=2; i < NF; i ++) {b=b "/" $(i)}; print b}'`
    DN_EXEC=$(dirname $(my_getpath "$0") )
    if [ ! "${DN_EXEC}" = "" ]; then
        export DN_EXEC="$(my_getpath "${DN_EXEC}")/"
    else
        export DN_EXEC="${DN_EXEC}/"
    fi
    DN_TOP="$(my_getpath "${DN_EXEC}/../")"
    DN_EXEC="$(my_getpath "${DN_TOP}/projtools/")"
    FN_CONF_SYS="${DN_TOP}/mrsystem.conf"
fi
#####################################################################

mr_trace "2 DN_TOP=$DN_TOP; DN_EXEC=${DN_EXEC}"

DN_LIB="$(my_getpath "${DN_TOP}/lib/")"
source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libfs.sh
source ${DN_LIB}/libconfig.sh
source ${DN_LIB}/libhadoop.sh
source ${DN_EXEC}/libapp.sh

mr_trace "3 DN_TOP=$DN_TOP;DN_EXEC=${DN_EXEC}"

#####################################################################
# read basic config from mrsystem.conf
# such as HDFF_PROJ_ID, HDFF_NUM_CLONE etc
read_config_file "${DN_TOP}/mrsystem.conf"

mr_trace "4 DN_TOP=$DN_TOP; DN_EXEC=${DN_EXEC}"

#####################################################################

PROGNAME=$(basename "$0")

mr_trace "5 DN_TOP=$DN_TOP; DN_EXEC=${DN_EXEC}"

mr_trace "DN_TOP=${DN_TOP}; DN_EXEC=${DN_EXEC}; PROGNAME=${PROGNAME}; "

#####################################################################
if [ ! -d "${PROJ_HOME}" ]; then
  PROJ_HOME="${DN_TOP}"
fi
mkdir -p "${PROJ_HOME}"
if [ ! "$?" = "0" ]; then mr_trace "Error in mkdir $PROJ_HOME" ; fi
PROJ_HOME="$(my_getpath "${PROJ_HOME}")"

mr_trace "PROJ_HOME=${PROJ_HOME}; EXEC_HADOOP=${EXEC_HADOOP}; HADOOP_JAR_STREAMING=${HADOOP_JAR_STREAMING}; "

source "${PROJ_HOME}/mrsystem.conf"

mr_trace "HDFF_DN_OUTPUT=$HDFF_DN_OUTPUT"

# detect if the DN_EXEC is real directory of the binary code
# this is for PBS/HPC environment
if [ ! "${PROJ_HOME}" = "${DN_TOP}" ]; then
  #if [ ! -x "${DN_EXEC}/mod-share-worker.sh" ]; then
    DN_TOP="${PROJ_HOME}"
    DN_EXEC="${PROJ_HOME}/$(basename $DN_EXEC)"
  #fi
fi

mr_trace "DN_TOP=${DN_TOP}; DN_EXEC=${DN_EXEC}; PROGNAME=${PROGNAME}; "
mr_trace "PROJ_HOME=${PROJ_HOME}"

#####################################################################
# read the config files started with prefix "config-*" in folder "${DN_TOP}/mytest/"
mapred_main () {

    # LIST_MAPREDUCE_WORK should be defined in libapp.sh
    lst_mr_work=(${LIST_MAPREDUCE_WORK})

    DN_BASE_HDFS="hdfs:///tmp/${USER}/working-${HDFF_PROJ_ID}"
    DN_OUTPUT_HDFS="hdfs:///tmp/${USER}/working-${HDFF_PROJ_ID}/results"
    if [[ "${HDFF_DN_BASE}" =~ ^hdfs:// ]]; then
        DN_BASE_HDFS="${HDFF_DN_BASE}"
    fi
    if [[ "${HDFF_DN_OUTPUT}" =~ ^hdfs:// ]]; then
        DN_OUTPUT_HDFS="${HDFF_DN_OUTPUT}"
    fi

    ####################
    # start time
    TM_START=$(date +%s)

    HDFS_DN_WORKING_PREFIX="${DN_BASE_HDFS}/working"

    RET=$(is_file_or_dir "${HDFS_DN_WORKING_PREFIX}")
    if [ ! "${RET}" = "d" ]; then
        make_dir "${HDFS_DN_WORKING_PREFIX}"
    fi
    RET=$(is_file_or_dir "${HDFS_DN_WORKING_PREFIX}")
    if [ ! "${RET}" = "d" ]; then
        mr_trace "not found user's location: ${HDFS_DN_WORKING_PREFIX}"
        return
    fi

    # genrate input file:
    rm_f_dir ${DN_OUTPUT_HDFS}/0/
    make_dir ${DN_OUTPUT_HDFS}/0/

    find_file "${DN_OUTPUT_HDFS}/" -name "config-*" | while read a; do rm_f_dir "${a}" ; done

    chmod_file -R 777 "${HDFS_DN_WORKING_PREFIX}/"
    chmod_file -R 777 "${DN_OUTPUT_HDFS}/"
    chmod_file -R 777 "${DN_BASE_HDFS}/"

    ####################
    mr_trace "generating input file ..."
    #find ../projconfigs/ -maxdepth 1 -name "config-*" | while read a; do echo -e "config\t\"$(my_getpath ${a})\"" >> ${DN_OUTPUT_HDFS}/0/input.txt; done
    find_file ${DN_TOP}/mytest/ -name "config-*" | while read a; do \
        copy_file "${a}" "${DN_OUTPUT_HDFS}/"; \
        echo -e "config\t\"${DN_OUTPUT_HDFS}/$(basename ${a})\"" | save_file ${DN_OUTPUT_HDFS}/0/redout.txt; \
    done

    ####################
    TM_PRE=$(date +%s)
    MSG_TM=

    CNT=0
    while [[ ${CNT} < ${#lst_mr_work[*]} ]] ; do
        run_stage_hadoop ${lst_mr_work[${CNT}]} $(( ${CNT} + 1 )) libapp_generate_script_4hadoop "${HDFS_DN_WORKING_PREFIX}/${CNT}" "${DN_OUTPUT_HDFS}/${CNT}" "${DN_OUTPUT_HDFS}/$(( ${CNT} + 1 ))"
        CNT=$(( ${CNT} + 1 ))
        TM_CUR=$(date +%s)
        MSG_TM="${MSG_TM},stage${CNT}=$(( ${TM_CUR} - ${TM_PRE} ))"
        TM_PRE=${TM_CUR}
    done

    ####################
    # end time
    TM_END=$(date +%s)

    if [[ ! "${HDFF_DN_OUTPUT}" =~ ^hdfs:// ]]; then
        make_dir "${HDFF_DN_OUTPUT}"
        copy_file "${DN_OUTPUT_HDFS}/" "${HDFF_DN_OUTPUT}"
    fi

    mr_trace "TM start=$TM_START, end=$TM_END"
    echo ""
    mr_trace "Cost time: total=$(( ${TM_END} - ${TM_START} )),${MSG_TM} seconds"
}
