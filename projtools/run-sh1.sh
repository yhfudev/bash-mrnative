#!/bin/bash
#####################################################################
# run map/reduce job in a single node
#
#
# Copyright 2015 Yunhui Fu
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
#DN_EXEC="$(my_getpath "${DN_TOP}/projtools/")"
DN_LIB="$(my_getpath "${DN_TOP}/lib/")"
#####################################################################
source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libfs.sh
source ${DN_LIB}/libconfig.sh
source ${DN_LIB}/libhadoop.sh
source ${DN_EXEC}/libapp.sh

PROGNAME=$(basename "$0")

# the base dir
ARG_DN_BASE="$1"

#####################################################################
# read basic config from mrsystem.conf
# such as HDFF_PROJ_ID, HDFF_NUM_CLONE etc
read_config_file "${DN_TOP}/mrsystem.conf"

# set the generated config file
FN_CONFIG_WORKING="${DN_EXEC}/mrsystem-working.conf"
rm_f_dir "${FN_CONFIG_WORKING}"
copy_file "${DN_TOP}/mrsystem.conf" "${FN_CONFIG_WORKING}"
FN_CONF_SYS="${FN_CONFIG_WORKING}"

HDFF_USER=${USER}
sed -i -e "s|^HDFF_USER=.*$|HDFF_USER=${HDFF_USER}|" "${FN_CONFIG_WORKING}"

if [ "${ARG_DN_BASE}" = "" ]; then
    HDFF_DN_BASE="$(pwd)/output-${HDFF_PROJ_ID}/"
else
    HDFF_DN_BASE="${ARG_DN_BASE}"
fi
sed -i -e "s|^HDFF_DN_BASE=.*$|HDFF_DN_BASE=${HDFF_DN_BASE}|" "${FN_CONFIG_WORKING}"

# redirect the output to HDFS so we can fetch back later
HDFF_DN_OUTPUT="${HDFF_DN_BASE}"
sed -i -e "s|^HDFF_DN_OUTPUT=.*$|HDFF_DN_OUTPUT=${HDFF_DN_OUTPUT}|" "${FN_CONFIG_WORKING}"

# scratch(temp) dir
HDFF_DN_SCRATCH="/tmp/${HDFF_USER}/working-${HDFF_PROJ_ID}/"
DN_SHM=$(df | grep shm | tail -n 1 | awk '{print $6}')
if [ ! "$DN_SHM" = "" ]; then
    HDFF_DN_SCRATCH="${DN_SHM}/${HDFF_USER}/working-${HDFF_PROJ_ID}/"
fi
sed -i -e "s|^HDFF_DN_SCRATCH=.*$|HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}|" "${FN_CONFIG_WORKING}"

# the directory for save the un-tar binary files
HDFF_DN_BIN=""
sed -i -e "s|^HDFF_DN_BIN=.*$|HDFF_DN_BIN=${HDFF_DN_BIN}|" "${FN_CONFIG_WORKING}"

# tar the binary and save it to HDFS for the node extract it later
# the tar file for application exec
HDFF_PATHTO_TAR_APP=""
sed -i -e "s|^HDFF_PATHTO_TAR_APP=.*$|HDFF_PATHTO_TAR_APP=${HDFF_PATHTO_TAR_APP}|" "${FN_CONFIG_WORKING}"

# the HDFS path to this project
HDFF_PATHTO_TAR_MRNATIVE=""
sed -i -e "s|^HDFF_PATHTO_TAR_MRNATIVE=.*$|HDFF_PATHTO_TAR_MRNATIVE=${HDFF_PATHTO_TAR_MRNATIVE}|" "${FN_CONFIG_WORKING}"

#mr_trace "DN_EXEC=${DN_EXEC}; DN_TOP=${DN_TOP}"

mr_trace "HDFF_DN_BASE=${HDFF_DN_BASE}"
mr_trace "HDFF_DN_OUTPUT=${HDFF_DN_OUTPUT}"
mr_trace "HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"
mr_trace "HDFF_DN_BIN=${HDFF_DN_BIN}"
mr_trace "HDFF_PATHTO_TAR_APP=${HDFF_PATHTO_TAR_APP}"
mr_trace "HDFF_PATHTO_TAR_MRNATIVE=${HDFF_PATHTO_TAR_MRNATIVE}"

check_global_config

#####################################################################
mapred_main_sh1 () {

    #LIST_MAPREDUCE_WORK is defined in libapp.sh
    lst_mr_work=(${LIST_MAPREDUCE_WORK})

    HDFS_DN_WORKING_PREFIX=${HDFF_DN_OUTPUT}/working/
    HDFS_DN_OUTPUT_PREFIX=${HDFF_DN_OUTPUT}/mapred-data/

    chmod_file -R 777 ${HDFS_DN_OUTPUT_PREFIX}/0/

    # start time
    TM_START=$(date +%s)

    ####################
    # genrate input file:
    $MYEXEC mkdir -p ${HDFS_DN_OUTPUT_PREFIX}/0/
    $MYEXEC rm -f ${HDFS_DN_OUTPUT_PREFIX}/0/*.txt
    find_file ${DN_TOP}/mytest/ -name "config-*" | while read a; do \
        echo -e "config\t\"$(my_getpath ${a})\"" | save_file ${HDFS_DN_OUTPUT_PREFIX}/0/redout.txt; \
    done

    ####################
    TM_PRE=$(date +%s)
    MSG_TM=

    CNT=0
    while [[ ${CNT} < ${#lst_mr_work[*]} ]] ; do
        TM_STAGE_MAP=$(run_stage_sh1 ${lst_mr_work[${CNT}]} $(( ${CNT} + 1 )) libapp_generate_script_4hadoop "${HDFS_DN_WORKING_PREFIX}/${CNT}" "${HDFS_DN_OUTPUT_PREFIX}/${CNT}" "${HDFS_DN_OUTPUT_PREFIX}/$(( ${CNT} + 1 ))")
        CNT=$(( ${CNT} + 1 ))
        TM_CUR=$(date +%s)
        MSG_TM="${MSG_TM},stage${CNT}=$(( ${TM_CUR} - ${TM_PRE} ))(m=$(( ${TM_STAGE_MAP} - ${TM_PRE} )),r=$(( ${TM_CUR} - ${TM_STAGE_MAP} )) )"

        TM_PRE=${TM_CUR}
    done

    ####################
    # end time
    TM_END=$(date +%s)

    mr_trace "TM start=$TM_START, end=$TM_END"
    echo ""

    mr_trace "Done !"
    mr_trace "config:"
    mr_trace "    HDFF_NUM_CLONE=${HDFF_NUM_CLONE}"
    mr_trace "    OPTIONS_FFM_GLOBAL=${OPTIONS_FFM_GLOBAL}"
    mr_trace "Cost time: total=$(( ${TM_END} - ${TM_START} ))${MSG_TM} seconds" 1>&2
}

mapred_main_sh1
