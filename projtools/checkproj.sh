#!/bin/bash
#
# check if the test is finished
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
source ${DN_COMM}/libns2utils.sh

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
        FN_TPFLOW="CMTCPDS*.out"
        LST=$(find . -maxdepth 1 -type f -name "${FN_TPFLOW}" | awk -F/ '{print $2}' | sort)
        for i in $LST ; do
            FLG_NONE=0
            echo "process flow throughput (tcp) $i ..."
            idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
            #echo "curr dir=$(pwd), tail i=$i" >> /dev/stderr
            TM1=$(tail -n 1 "$i" | awk '{print $1}')
            if [ $(echo | awk -v A=$TM1 -v B=$TIME_STOP '{if (A + 5 < B) print 1; else print 0;}') = 1 ] ; then
                FLG_ERR=1
            fi
        done
        FN_TPFLOW="CMUDPDS*.out"
        LST=$(find . -maxdepth 1 -type f -name "${FN_TPFLOW}" | awk -F/ '{print $2}' | sort)
        for i in $LST ; do
            FLG_NONE=0
            echo "process flow throughput (tcp) $i ..."
            idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
            TM1=$(tail -n 1 "$i" | awk '{print $1}')
            if [ $(echo | awk -v A=$TM1 -v B=$TIME_STOP '{if (A + 5 < B) print 1; else print 0;}') = 1 ] ; then
                FLG_ERR=1
            fi
        done
        if [ "$FLG_NONE" = "1" ]; then
            FLG_ERR=1
        fi
        cd - > /dev/null
    fi

    if [ "${FLG_ERR}" = "1" ]; then
        #echo "save ${PARAM_FN_LOG_ERROR}: ${DN_TEST}" >> "/dev/stderr"
        echo "${DN_TEST}" >> "${PARAM_FN_LOG_ERROR}"
    fi
}

convert_eps2png () {
    for FN_FULL in $(find . -maxdepth 1 -type f -name "*.eps" | awk -F/ '{print $2}' | sort) ; do
        FN_BASE=$(echo "${FN_FULL}" | gawk -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
        echo "eps: ${FN_FULL}"
        #echo "png: ${FN_BASE}.png"
        if [ ! -f "${FN_BASE}.png" ]; then
            convert -density 300 "${FN_FULL}" "${FN_BASE}.png"
        fi
    done
}

# check if current config.sh is finished
check_failed_folders () {
    # output file save the failed directories
    PARAM_FN_LOG_ERROR=$1
    shift

    convert_eps2png

    rm -f "${PARAM_FN_LOG_ERROR}"
    for idx_num in ${list_nodes_num[*]} ; do
        for idx_type in ${list_types[*]} ; do
            for idx_sche in ${list_schedules[*]} ; do
                #prepare_one_simulation "${PREFIX}" "${list_types[$idx_type]}" "${list_schedules[$idx_sche]}" "${list_nodes_num[$idx_num]}" &
                checkone_folder "${PREFIX}" "$idx_type" "$idx_sche" "$idx_num" "${PARAM_FN_LOG_ERROR}"
            done
        done
    done
}

echo ""
echo ""
echo "$MSG_TITLE"
echo "=========="
echo "$MSG_DESCRIPTION"
echo "----------"
echo "Checking ..."

echo "" > "${FN_LOG_ERROR}"
check_failed_folders "${FN_LOG_ERROR}"

echo "you may check the file for the list of possible failed test: ${FN_LOG_ERROR}"
echo "$(date) DONE: ALL"
