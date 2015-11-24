#!/usr/bin/env bash
#
# Bash lib for hadoop functions
#
# Copyright 2015 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################
# this lib depend on libbash.sh, libfs.sh

#####################################################################
# run map and reduce script
#
# ARG 1: <config line>, such as "e1map.sh,e1red.sh,6,5,cb_end_stage1"
# ARG 2: the stage #
# ARG 3: the callback function for generating single MR script
# ARG 4: the working directory
# ARG 5: the input directory
# ARG 6: the output directory
#
# <config line> format: "<map>,<reduce>,<# of output key>,<# of partition key>,<callback end function>"
#   java streaming argument 'stream.num.map.output.key.fields' is map to '# of output key'
#   java streaming argument 'num.key.fields.for.partition' is map to '# of partition key'
#   stream.num.map.output.key.fields >= num.key.fields.for.partition
#   'callback end function' is called at the end of function
#
# This function will split the input files to several files with prefix 'splitfile-'
# with the paremter HDFF_TOTAL_NODES from global config file. Then all these 'splitfile-' files
# will be used as input of the map task.
#
# The predefined variables should exist before call this function:
#     HDFF_TOTAL_NODES, HDFF_NUM_CLONE, HADOOP_JAR_STREAMING, HDFF_PROJ_ID, DN_EXEC
#
# example:
#run_stage "e1map.sh,,6,5," 1 "workingdir" "${DN_INPUT_HDFS}/0" "${DN_INPUT_HDFS}/1"
run_stage_hadoop () {
    mr_trace "run_stage $@"

    local PARAM_CONFIG_LINE=$1
    shift
    local PARAM_STAGE=$1
    shift
    local PARAM_CB_GEN_MRBIN=$1
    shift
    local PARAM_HDFS_WORKING=$1
    shift
    local PARAM_HDFS_INPUT=$1
    shift
    local PARAM_HDFS_OUTPUT=$1
    shift

    local PARAM_FNMAP=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $1}')
    local PARAM_FNRED=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $2}')
    local PARAM_KEYS_SEP=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $3}')
    local PARAM_KEYS_BLK=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $4}')
    local PARAM_CBEND=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $5}')

    mr_trace "Stage ${PARAM_STAGE} ..."
    #####################################################################
    # use hundreds of files instead of one small file:
    mr_trace "origin HDFF_TOTAL_NODES=${HDFF_TOTAL_NODES}, HDFF_NUM_CLONE=${HDFF_NUM_CLONE}"
    if [ "${HDFF_TOTAL_NODES}" = "" ]; then
        HDFF_TOTAL_NODES=0
    fi
    if (( ${HDFF_TOTAL_NODES} < 1 )) ; then
        HDFF_TOTAL_NODES=1
    fi
    if [ "${HDFF_NUM_CLONE}" = "" ]; then
        HDFF_NUM_CLONE=0
    fi
    if (( ${HDFF_NUM_CLONE} < 4 )) ; then
        HDFF_NUM_CLONE=4
    fi
    mr_trace "adjusted HDFF_TOTAL_NODES=${HDFF_TOTAL_NODES}, HDFF_NUM_CLONE=${HDFF_NUM_CLONE}"

    # use temp dir to store the output of awk since it don't support save to hdfs
    local DN_TMP="/tmp/dir-$(uuidgen)"
    make_dir "${DN_TMP}" > /dev/null

    find_file "${PARAM_HDFS_INPUT}/" -name "splitfile-*.txt" | while read a; do rm_f_dir "${a}"; done
    mr_trace "at the stage ${PARAM_STAGE}, split file ${PARAM_HDFS_INPUT}/*.txt to ${PARAM_HDFS_INPUT}/splitfile-*.txt"
    find_file "${PARAM_HDFS_INPUT}/" -name "*.txt" | while read a; do \
        cat_file "${a}" | awk -v DUP=${HDFF_TOTAL_NODES} -v CLONE=${HDFF_NUM_CLONE} -v DN="${DN_TMP}/" \
            'BEGIN{cnt=0; DUP=int(DUP);}{cnt ++; print $0 >> "" DN "/splitfile-" (cnt % DUP) ".txt"}'; \
    done

    rm_f_dir "${PARAM_HDFS_WORKING}/"
    make_dir "${PARAM_HDFS_WORKING}/"
    mr_trace "copy ${DN_TMP}/splitfile-*.txt to ${PARAM_HDFS_WORKING}"
    copy_file "${DN_TMP}/" "${PARAM_HDFS_WORKING}/" > /dev/null
    rm_f_dir "${DN_TMP}/"

    chmod_file -R 777 "${PARAM_HDFS_WORKING}/"

    local HD_MAP="-mapper /bin/cat"
    local HD_RED="-reducer /bin/cat"
    # combine all of the bash scripts to one file
    local FN_MAP=
    if [ ! "${PARAM_FNMAP}" = "" ]; then
        FN_MAP="/tmp/tmp-e${PARAM_STAGE}map-$(uuidgen).sh"
        mr_trace "generating exec file: ${PARAM_FNMAP}"
        ${PARAM_CB_GEN_MRBIN} "${DN_EXEC}/${PARAM_FNMAP}" "${FN_MAP}"
        RET=$(is_file_or_dir "${FN_MAP}")
        if [ ! "${RET}" = "f" ]; then
            mr_trace "Error: not found exec file: ${FN_MAP}"
            return
        fi
        RET=$(is_local "${FN_MAP}")
        if [ ! "${RET}" = "l" ]; then
            mr_trace "Error: not a local file: ${FN_MAP}"
            return
        fi
        chmod 755 "${FN_MAP}"
        if [ ! -e "${FN_MAP}" ]; then
            mr_trace "Error: not a exec file: ${FN_MAP}"
            return
        fi
        HD_MAP="-file ${FN_MAP} -mapper $(basename ${FN_MAP})"
    fi
    local FN_RED=
    if [ ! "${PARAM_FNRED}" = "" ]; then
        FN_RED="/tmp/tmp-e${PARAM_STAGE}red-$(uuidgen).sh"
        ${PARAM_CB_GEN_MRBIN} "${DN_EXEC}/${PARAM_FNRED}" "${FN_RED}"
        RET=$(is_file_or_dir "${FN_RED}")
        if [ ! "${RET}" = "f" ]; then
            mr_trace "Error: not found exec file: ${FN_RED}"
            return
        fi
        RET=$(is_local "${FN_RED}")
        if [ ! "${RET}" = "l" ]; then
            mr_trace "Error: not a local file: ${FN_RED}"
            return
        fi
        chmod 755 "${FN_RED}"
        if [ ! -e "${FN_RED}" ]; then
            mr_trace "Error: not a exec file: ${FN_RED}"
            return
        fi
        HD_RED="-file ${FN_RED} -reducer $(basename ${FN_RED})"
    fi

    rm_f_dir "${PARAM_HDFS_OUTPUT}"
    #make_dir "${PARAM_HDFS_OUTPUT}"
    #chmod_file -R 777 "${PARAM_HDFS_OUTPUT}"
    mr_trace "hadoop stream: -input ${PARAM_HDFS_WORKING} -output ${PARAM_HDFS_OUTPUT} ${HD_MAP} ${HD_RED}"
    ${EXEC_HADOOP} jar ${HADOOP_JAR_STREAMING} \
        -D mapred.job.name=${HDFF_PROJ_ID}-${PARAM_STAGE} \
        -D mapreduce.task.timeout=0 \
        -D stream.num.map.output.key.fields=${PARAM_KEYS_SEP} \
        -D num.key.fields.for.partition=${PARAM_KEYS_BLK} \
        -input "${PARAM_HDFS_WORKING}" -output "${PARAM_HDFS_OUTPUT}" \
        ${HD_MAP} ${HD_RED} \
        ${NULL}
    if [ ! "$?" = "0" ]; then
        mr_trace "Error in hadoop stage: ${PARAM_STAGE}"
        return
    fi

    chmod_file -R 777 "${PARAM_HDFS_OUTPUT}"

    mr_trace move_file "${PARAM_HDFS_OUTPUT}/part-00000" "${PARAM_HDFS_OUTPUT}/redout.txt"
    move_file "${PARAM_HDFS_OUTPUT}/part-00000" "${PARAM_HDFS_OUTPUT}/redout.txt" > /dev/null

    if [ ! "${PARAM_CBEND}" = "" ]; then
        ${PARAM_CBEND}
    fi
}

#####################################################################
# run map and reduce script
#
# ARG 1: <config line>, such as "e1map.sh,e1red.sh,6,5,cb_end_stage1"
# ARG 2: the stage #
# ARG 3: the callback function for generating single MR script (NOT used in this script)
# ARG 4: the working directory
# ARG 5: the input directory
# ARG 6: the output directory
#
# <config line> format: "<map>,<reduce>,<# of output key>,<# of partition key>,<callback end function>"
#   java streaming argument 'stream.num.map.output.key.fields' is map to '# of output key'
#   java streaming argument 'num.key.fields.for.partition' is map to '# of partition key'
#   stream.num.map.output.key.fields >= num.key.fields.for.partition
#   'callback end function' is called at the end of function
#
# This function will split the input files to several files with prefix 'splitfile-'
# with the paremter HDFF_TOTAL_NODES from global config file. Then all these 'splitfile-' files
# will be used as input of the map task.
#
# The predefined variables should exist before call this function:
#     DN_EXEC
#
# example:
#run_stage "e1map.sh,,6,5," 1 "cb_null" "workingdir" "${DN_INPUT_HDFS}/0" "${DN_INPUT_HDFS}/1"
#run_stage "${DN_EXEC}/e1map.sh,,6,5," 1 "cb_null" "workingdir" "${DN_INPUT_HDFS}/0" "${DN_INPUT_HDFS}/1"
run_stage_sh1 () {
    mr_trace "run_stage $@"

    local PARAM_CONFIG_LINE=$1
    shift
    local PARAM_STAGE=$1
    shift
    local PARAM_CB_GEN_MRBIN=$1
    shift
    local PARAM_HDFS_WORKING=$1
    shift
    local PARAM_HDFS_INPUT=$1
    shift
    local PARAM_HDFS_OUTPUT=$1
    shift

    local PARAM_FNMAP=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $1}')
    local PARAM_FNRED=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $2}')
    local PARAM_KEYS_SEP=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $3}')
    local PARAM_KEYS_BLK=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $4}')
    local PARAM_CBEND=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $5}')

    local HD_MAP="cat"
    local HD_RED="cat"
    if [ ! "${PARAM_FNMAP}" = "" ]; then
        HD_MAP="${DN_EXEC}/${PARAM_FNMAP}"
    fi
    if [ ! "${PARAM_FNRED}" = "" ]; then
        HD_RED="${DN_EXEC}/${PARAM_FNRED}"
    fi

    mr_trace "Stage ${PARAM_STAGE} ..."
    rm_f_dir ${PARAM_HDFS_OUTPUT} > /dev/null
    make_dir ${PARAM_HDFS_OUTPUT} > /dev/null
    mr_trace "bash stream: -input ${PARAM_HDFS_INPUT}/redout.txt -output ${PARAM_HDFS_OUTPUT} ${HD_MAP} ${HD_RED}"
    cat_file ${PARAM_HDFS_INPUT}/redout.txt  | ${HD_MAP} | sort | save_file ${PARAM_HDFS_OUTPUT}/mapout.txt
    TM_MAP_MID=$(date +%s)
    cat_file ${PARAM_HDFS_OUTPUT}/mapout.txt | ${HD_RED} | sort | save_file ${PARAM_HDFS_OUTPUT}/redout.txt

    if [ ! "${PARAM_CBEND}" = "" ]; then
        ${PARAM_CBEND} 1>&2
    fi
    echo "${TM_MAP_MID}"
}