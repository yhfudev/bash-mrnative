#!/bin/bash
#
# clean the current proj directory
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
  cd "${DN}" > /dev/null 2>&1
  DN=$(pwd)
  cd - > /dev/null 2>&1
  echo "${DN}/${FN}"
}
DN_EXEC=$(dirname $(my_getpath "$0") )
#####################################################################

EXEC_NS2="$(my_getpath "${DN_EXEC}/../../ns")"

DN_COMM="$(my_getpath "${DN_EXEC}/common")"
DN_TOP="${DN_EXEC}"
source ${DN_COMM}/libbash.sh
source ${DN_COMM}/libshrt.sh

DN_PARENT="$(my_getpath ".")"
FN_LOG_ERROR="${DN_PARENT}/testfailed.txt"

source ${DN_PARENT}/config.sh

check_global_config

#echo "HDFF_NUM_CLONE=$HDFF_NUM_CLONE"; exit 1 # debug

#####################################################################

checkone_folder () {
    # the prefix of the test
    PARAM_PREFIX=$1
    shift
    # the test type, "udp", "tcp", "has", "udp+has", "tcp+has"
    PARAM_TYPE=$1
    shift
    # the scheduler, such as "PF", "DRR"
    PARAM_SCHE=$1
    shift
    # the number of flows
    PARAM_NUM=$1
    shift
    # output file save the failed directories
    PARAM_FN_LOG_ERROR=$1
    shift

    [ "${PARAM_PREFIX}" = "" ] && (echo "Error in prefix: ${PARAM_PREFIX}" && exit 1)
    [ "${PARAM_TYPE}" = "" ] && (echo "Error in type: ${PARAM_TYPE}" && exit 1)
    [ "${PARAM_SCHE}" = "" ] && (echo "Error in scheduler: ${PARAM_SCHE}" && exit 1)
    [ "${PARAM_NUM}" = "" ] && (echo "Error in number: ${PARAM_NUM}"; exit 1)

    #DN_TEST="${PARAM_PREFIX}_${PARAM_TYPE}_${PARAM_SCHE}_${PARAM_NUM}"
    DN_TEST=$(simulation_directory "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}")

    FLG_ERR=1
    if [ -d "${DN_TEST}/" ]; then
        FLG_ERR=0
        FLG_NONE=1
        cd       "${DN_TEST}/"
        find . -maxdepth 1 -type f -name "tmp-*" | xargs -n 10 rm -f
        cd - > /dev/null
    fi

    if [ "${FLG_ERR}" = "1" ]; then
        #echo "save ${PARAM_FN_LOG_ERROR}: ${DN_TEST}" >> "/dev/stderr"
        echo "${DN_TEST}" >> "${PARAM_FN_LOG_ERROR}"
    fi
}

# check if current config.sh is finished
check_failed_folders () {
    PARAM_FN_ASSIGN=$1
    shift
    # output file save the failed directories
    PARAM_FN_LOG_ERROR=$1
    shift

    for idx_num in ${list_nodes_num[*]} ; do
        for idx_type in ${list_types[*]} ; do
            for idx_sche in ${list_schedules[*]} ; do
                if [ ! "${PARAM_FN_ASSIGN}" = "" ]; then
                    # if the assigment file exit, then check if current test is in the list in the file
                    DN_TEST=$(simulation_directory "${PREFIX}" "$idx_type" "$idx_sche" "$idx_num")
                    grep "${DN_TEST}" "${PARAM_FN_ASSIGN}"
                    if [ ! "$?" = "0" ] ; then
                        echo "not found ${DN_TEST} in file: ${PARAM_FN_ASSIGN}, skiping ..."
                        continue
                    fi
                fi
                #prepare_one_simulation "${PREFIX}" "${list_types[$idx_type]}" "${list_schedules[$idx_sche]}" "${list_nodes_num[$idx_num]}" &
                checkone_folder "${PREFIX}" "$idx_type" "$idx_sche" "$idx_num" "${PARAM_FN_LOG_ERROR}"
            done
        done
    done
}

FN_ASSIGN=$1

echo ""
echo ""
echo "$MSG_TITLE"
echo "=========="
echo "$MSG_DESCRIPTION"
echo "----------"
echo "Checking ..."

echo "" > "${FN_LOG_ERROR}"

find . -maxdepth 1 -type f -name "tmp-*" | xargs -n 10 rm -f
find . -maxdepth 1 -type f -name "fig-*" | xargs -n 10 rm -f
find . -maxdepth 1 -type f -name "testfailed.txt" | xargs -n 10 rm -f

check_failed_folders "${FN_ASSIGN}" "${FN_LOG_ERROR}"

echo "you may check the file for the list of possible failed test: ${FN_LOG_ERROR}"
echo "$(date) DONE: ALL"
