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

DN_LIB="$(my_getpath "${DN_TOP}/lib/")"
source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libfs.sh
source ${DN_LIB}/libconfig.sh

#####################################################################
# read basic config from mrsystem.conf
# such as HDFF_PROJ_ID, HDFF_NUM_CLONE etc
read_config_file "${DN_TOP}/mrsystem.conf"

#####################################################################

PROGNAME=$(basename "$0")

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
generate_script_4hadoop () {
    local PARAM_ORIG="$1"
    shift
    local PARAM_OUTPUT="$1"
    shift

    local DN_FILE9=$(dirname "${PARAM_ORIG}")
    local DN_EXEOUT9=$(dirname "${PARAM_OUTPUT}")

    local RET=
    RET=$(is_file_or_dir "${DN_EXEOUT9}")
    if [ ! "${RET}" = "d" ]; then
        make_dir "${DN_EXEOUT9}"
        RET=$(is_file_or_dir "${DN_EXEOUT9}")
        if [ ! "${RET}" = "d" ]; then mr_trace "Error in mkdir $DN_EXEOUT9"; fi
    fi

    rm_f_dir "${PARAM_OUTPUT}"
    echo '#!/bin/bash'                      | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC_4HADOOP=${DN_EXEC}"       | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP_4HADOOP=${DN_TOP}"         | save_file "${PARAM_OUTPUT}"
    echo "FN_CONF_SYS_4HADOOP=${FN_CONF_SYS}" | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC=${DN_EXEC}"               | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP=${DN_TOP}"                 | save_file "${PARAM_OUTPUT}"
    echo "FN_CONF_SYS=${FN_CONF_SYS}"       | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_FILE9}/mod-setenv-hadoop.sh" | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libbash.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libshrt.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libfs.sh"       | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libplot.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libconfig.sh"   | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_FILE9}/libns2figures.sh" | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_FILE9}/libapp.sh"        | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC_4HADOOP=${DN_EXEC}"       | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP_4HADOOP=${DN_TOP}"         | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC=${DN_EXEC}"               | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP=${DN_TOP}"                 | save_file "${PARAM_OUTPUT}"
    cat_file "${PARAM_ORIG}"    \
        | grep -v "libbash.sh"  \
        | grep -v "libshrt.sh"  \
        | grep -v "libfs.sh"    \
        | grep -v "libplot.sh"  \
        | grep -v "libconfig.sh"    \
        | grep -v "libns2figures.sh" \
        | grep -v "libapp.sh"   \
        | sed -e "s|EXEC_NS2=.*$|EXEC_NS2=$(which ns)|" \
        | save_file "${PARAM_OUTPUT}"
}

#####################################################################

mapred_main () {

# start time
TM_START=$(date +%s)

# generate config lines
#DN_INPUT="${PROJ_HOME}/data/input/"
DN_INPUT=${HDFF_DN_OUTPUT}/${HDFF_PROJ_ID}/mapred-data/0/
DN_PREFIX=${HDFF_DN_OUTPUT}/${HDFF_PROJ_ID}/mapred-data/
DN_CONFIG=${DN_PREFIX}/config

chmod_file -R 777 "${HDFF_DN_OUTPUT}/${HDFF_PROJ_ID}"

if [ 1 = 1 ]; then
    # genrate input file:
    mr_trace "generating input file ..."
    rm_f_dir ${DN_INPUT}
    make_dir ${DN_INPUT}
    rm_f_dir ${DN_CONFIG}
    make_dir ${DN_CONFIG}
    if [ ! "$?" = "0" ]; then mr_trace "Error in mkdir $DN_INPUT" ; fi
    #find ../projconfigs/ -maxdepth 1 -name "config-*" | while read a; do echo -e "config\t\"$(my_getpath ${a})\"" >> ${DN_INPUT}/input.txt; done
    find_file ../mytest/ -name "config-*" | while read a; do copy_file "${a}" "${DN_CONFIG}/"; echo -e "config\t\"${DN_CONFIG}/$(basename ${a})\"" | save_file ${DN_INPUT}/input.txt; done
fi

FN_MAP="/tmp/tmpe1map-$(uuidgen).sh"
#FN_RED="/tmp/tmpe1red-$(uuidgen).sh"
mr_trace "generating exec file: ${FN_MAP}"
generate_script_4hadoop "${DN_EXEC}/e1map.sh" "${FN_MAP}"
#generate_script_4hadoop "${DN_EXEC}/e1red.sh" "${FN_RED}"
RET=$(is_file_or_dir "${FN_MAP}")
if [ ! "${RET}" = "f" ]; then
    mr_trace "Error: not found exec file: ${FN_MAP}"
    return
fi

DN_PREFIX_HDFS="${HDFF_DN_BASE}/mapreduce-working/${HDFF_PROJ_ID}/"
RET=$(is_file_or_dir "${DN_PREFIX_HDFS}")
if [ ! "${RET}" = "d" ]; then
    make_dir "${DN_PREFIX_HDFS}"
fi
RET=$(is_file_or_dir "${DN_PREFIX_HDFS}")
if [ ! "${RET}" = "d" ]; then
    mr_trace "not found user's location: ${DN_PREFIX_HDFS}"
    return
fi

STAGE=0
DN_INPUT_HDFS="${DN_PREFIX_HDFS}/${STAGE}"

STAGE=$(( $STAGE + 1 ))
DN_OUTPUT_HDFS="${DN_PREFIX_HDFS}/${STAGE}"

rm_f_dir "${DN_INPUT_HDFS}"
RET=$(make_dir "${DN_INPUT_HDFS}")
if [ ! "${RET}" = "0" ]; then
    mr_trace "Warning: failed to hadoop mkdir ${DN_INPUT_HDFS}, try again ..."
    hadoop dfsadmin -safemode leave
    hdfs dfsadmin -safemode leave
    RET=$(make_dir "${DN_INPUT_HDFS}")
    if [ ! "${RET}" = "0" ]; then
        mr_trace "Error in hadoop mkdir(ret=${RET}) ${DN_INPUT_HDFS}"
        return
    fi
fi
RET=$(copy_file "${DN_INPUT}/" "${DN_INPUT_HDFS}")
if [ ! "${RET}" = "0" ]; then
    mr_trace "Error in put data: ret=${RET}, in=${DN_INPUT}/, out=${DN_INPUT_HDFS}"
    return
fi
${EXEC_HADOOP} fs -ls "${DN_INPUT_HDFS}"
#${EXEC_HADOOP} fs -cat "${DN_INPUT_HDFS}/test.txt"

${EXEC_HADOOP} fs -ls "${DN_OUTPUT_HDFS}"

#${EXEC_HADOOP} fs -cat "${DN_OUTPUT_HDFS}/part-00000"

if [ 1 = 1 ]; then
mr_trace "Stage ${STAGE} ..."
rm_f_dir "${DN_OUTPUT_HDFS}"
${EXEC_HADOOP} jar ${HADOOP_JAR_STREAMING} \
    -D mapred.job.name=${HDFF_PROJ_ID}-${STAGE} \
    -D mapreduce.task.timeout=0 \
    -D stream.num.map.output.key.fields=6 \
    -D num.key.fields.for.partition=6 \
    -input "${DN_INPUT_HDFS}" -output "${DN_OUTPUT_HDFS}" \
    -file "${FN_MAP}" -mapper  $(basename "${FN_MAP}") \
    -reducer /bin/cat \
    ${NULL}
if [ ! "$?" = "0" ]; then
    mr_trace "Error in hadoop stage: ${STAGE}"
    return
fi
fi

${EXEC_HADOOP} fs -ls "${DN_OUTPUT_HDFS}"
#${EXEC_HADOOP} fs -cat "${DN_OUTPUT_HDFS}/part-00000"

rm_f_dir "${DN_PREFIX}/${STAGE}/"
make_dir "${DN_PREFIX}/${STAGE}/"
mr_trace move_file "${DN_OUTPUT_HDFS}/part-00000" "${DN_PREFIX}/${STAGE}/redout.txt"
move_file "${DN_OUTPUT_HDFS}/part-00000" "${DN_PREFIX}/${STAGE}/redout.txt"

echo
TM_STAGE1=$(date +%s)

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
DN_TMP=
DN_SPL="${DN_PREFIX}/${STAGE}/"
make_dir "${DN_SPL}"
RET=$(is_local "${DN_SPL}")
if [ ! "${DN_SPL}" = "l" ]; then
    DN_TMP="/tmp/dir-$(uuidgen)"
    DN_SPL="${DN_TMP}"
fi
make_dir "${DN_SPL}"

find_file "${DN_PREFIX}/${STAGE}/" -name "file*.txt" | while read a; do rm_f_dir "${a}"; done
mr_trace "at the end of stage ${STAGE}, split file ${DN_PREFIX}/${STAGE}/redout.txt to ${DN_SPL}/file*.txt"
cat_file "${DN_PREFIX}/${STAGE}/redout.txt" \
    | awk -v DUP=${HDFF_TOTAL_NODES} -v CLONE=${HDFF_NUM_CLONE} -v DN="${DN_SPL}/" 'BEGIN{cnt=0; DUP=int(DUP);}{cnt ++; print $0 >> "" DN "/file" (cnt % DUP) ".txt"}'

${EXEC_HADOOP} fs -rm -f "${DN_OUTPUT_HDFS}/part-00000"
mr_trace "copy ${DN_SPL}/file*.txt to ${DN_OUTPUT_HDFS}"

if [ ! "${DN_TMP}" = "" ]; then
    mr_trace "copy_file ${DN_TMP}/ ${DN_PREFIX}/${STAGE}/"
    copy_file "${DN_TMP}/" "${DN_PREFIX}/${STAGE}/"
    rm_f_dir "${DN_TMP}/"
fi
mr_trace "copy ${DN_PREFIX}/${STAGE}/file*.txt to ${DN_OUTPUT_HDFS}"
find_file "${DN_PREFIX}/${STAGE}/" -name "file*.txt" | while read a; do mr_trace "at the end of stage ${STAGE}, copy_file ${a} ${DN_OUTPUT_HDFS}"; copy_file "${a}" "${DN_OUTPUT_HDFS}"; done

#####################################################################

FN_MAP="/tmp/tmpe2map-$(uuidgen).sh"
FN_RED="/tmp/tmpe2red-$(uuidgen).sh"

mr_trace "generating exec file: ${FN_MAP}"
generate_script_4hadoop "${DN_EXEC}/e2map.sh" "${FN_MAP}"
RET=$(is_file_or_dir "${FN_MAP}")
if [ ! "${RET}" = "f" ]; then
    mr_trace "Error: not found exec file: ${FN_MAP}"
    return
fi

mr_trace "generating exec file: ${FN_RED}"
generate_script_4hadoop "${DN_EXEC}/e2red.sh" "${FN_RED}"
RET=$(is_file_or_dir "${FN_RED}")
if [ ! "${RET}" = "f" ]; then
    mr_trace "Error: not found exec file: ${FN_RED}"
    return
fi


if [ 1 = 1 ]; then
LINES_PRE=0
STAGE2_RUN=0
STAGE2_RUN_MAX=10

while (( $STAGE2_RUN < $STAGE2_RUN_MAX )) ; do
    STAGE=$(( $STAGE + 1 ))

    DN_INPUT_HDFS=${DN_OUTPUT_HDFS}
    DN_OUTPUT_HDFS="${DN_PREFIX_HDFS}/${STAGE}"

    ${EXEC_HADOOP} fs -ls "${DN_INPUT_HDFS}"

    mr_trace "Stage 2 ..."
    rm_f_dir "${DN_OUTPUT_HDFS}"
    #-D mapred.reduce.tasks=1
    #-D mapred.reduce.tasks=0
    #-D N=$(${EXEC_HADOOP} fs -ls ${DN_INPUT_HDFS0} | tail -n +2 | wc -l)
    #-mapper  org.apache.hadoop.mapred.lib.IdentityMapper
    #-mapper /bin/cat
    #-reducer org.apache.hadoop.mapred.lib.IdentityReducer
    ${EXEC_HADOOP} jar ${HADOOP_JAR_STREAMING} \
        -D mapred.job.name=${HDFF_PROJ_ID}-${STAGE} \
        -D mapreduce.task.timeout=0 \
        -D stream.num.map.output.key.fields=4 \
        -D num.key.fields.for.partition=2 \
        -input "${DN_INPUT_HDFS}" -output "${DN_OUTPUT_HDFS}" \
        -file "${FN_MAP}" -mapper  $(basename "${FN_MAP}") \
        -file "${FN_RED}" -reducer $(basename "${FN_RED}") \
        ${NULL}
    if [ ! "$?" = "0" ]; then
        mr_trace "Error in hadoop stage: ${STAGE}"
        return
    fi

    rm_f_dir "${DN_PREFIX}/${STAGE}/"
    make_dir "${DN_PREFIX}/${STAGE}/"
    move_file "${DN_OUTPUT_HDFS}/part-00000" "${DN_PREFIX}/${STAGE}/redout.txt"

    STAGE2_RUN=$(( $STAGE2_RUN + 1 ))
    LINES=$(cat_file "${DN_PREFIX}/${STAGE}/redout.txt" | grep ^error | wc -l)
    if (( $LINES < 1 )) ; then
        mr_trace "finished after ${STAGE2_RUN} tries."
        break
    fi
    if (( $LINES < $LINES_PRE )) ; then
        STAGE2_RUN=0
        mr_trace "got some advantages at stage ${STAGE}."
    fi
    mr_trace "Try to do stage ${STAGE} for the next: ${STAGE2_RUN}."
done
if (( $LINES > 0 )) ; then
    mr_trace "Warning: Stage 2 error after ${STAGE2_RUN} tries."
fi
fi

echo
TM_STAGE2=$(date +%s)

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
DN_TMP=
DN_SPL="${DN_PREFIX}/${STAGE}/"
make_dir "${DN_SPL}"
RET=$(is_local "${DN_SPL}")
if [ ! "${DN_SPL}" = "l" ]; then
    DN_TMP="/tmp/dir-$(uuidgen)"
    DN_SPL="${DN_TMP}"
fi
make_dir "${DN_SPL}"

find_file "${DN_PREFIX}/${STAGE}/" -name "file*.txt" | while read a; do rm_f_dir "${a}"; done
mr_trace "split file ${DN_PREFIX}/${STAGE}/redout.txt to ${DN_SPL}/file*.txt"
cat_file "${DN_PREFIX}/${STAGE}/redout.txt" \
    | awk -v DUP=${HDFF_TOTAL_NODES} -v CLONE=${HDFF_NUM_CLONE} -v DN="${DN_SPL}/" 'BEGIN{cnt=0; DUP=int(DUP*CLONE/2);}{cnt ++; print $0 >> "" DN "/file" (cnt % DUP) ".txt"}'

${EXEC_HADOOP} fs -rm -f "${DN_OUTPUT_HDFS}/part-00000"

if [ ! "${DN_TMP}" = "" ]; then
    mr_trace "copy ${DN_TMP}/* to ${DN_PREFIX}/${STAGE}/"
    copy_file "${DN_TMP}/" "${DN_PREFIX}/${STAGE}/"
    rm_f_dir "${DN_TMP}/"
fi

mr_trace "copy ${DN_PREFIX}/${STAGE}/file*.txt to ${DN_OUTPUT_HDFS}"
find_file "${DN_PREFIX}/${STAGE}/" -name "file*.txt" | while read a; do mr_trace "at the end of stage ${STAGE}, copy_file ${a} ${DN_OUTPUT_HDFS}"; copy_file "${a}" "${DN_OUTPUT_HDFS}"; done

#####################################################################
STAGE=$(( $STAGE + 1 ))

FN_MAP="/tmp/tmpe3map-$(uuidgen).sh"
#FN_RED="/tmp/tmpe3red-$(uuidgen).sh"

mr_trace "generating exec file: ${FN_MAP}"
generate_script_4hadoop "${DN_EXEC}/e3map.sh" "${FN_MAP}"
RET=$(is_file_or_dir "${FN_MAP}")
if [ ! "${RET}" = "f" ]; then
    mr_trace "Error: not found exec file: ${FN_MAP}"
    return
fi

DN_INPUT_HDFS=${DN_OUTPUT_HDFS}
DN_OUTPUT_HDFS="${DN_PREFIX_HDFS}/${STAGE}"

${EXEC_HADOOP} fs -ls "${DN_INPUT_HDFS}"

if [ 1 = 1 ]; then
mr_trace "Stage 3 ..."
rm_f_dir "${DN_OUTPUT_HDFS}"
${EXEC_HADOOP} jar ${HADOOP_JAR_STREAMING} \
    -D mapred.job.name=${HDFF_PROJ_ID}-${STAGE} \
    -D mapreduce.task.timeout=0 \
    -D stream.num.map.output.key.fields=6 \
    -D num.key.fields.for.partition=6 \
    -input "${DN_INPUT_HDFS}" -output "${DN_OUTPUT_HDFS}" \
    -file "${FN_MAP}" -mapper  $(basename "${FN_MAP}") \
    -reducer /bin/cat \
    ${NULL}
if [ ! "$?" = "0" ]; then
    mr_trace "Error in hadoop stage: ${STAGE}"
    return
fi
fi

${EXEC_HADOOP} fs -ls "${DN_OUTPUT_HDFS}"
#${EXEC_HADOOP} fs -cat "${DN_OUTPUT_HDFS}/part-00000"
rm_f_dir "${DN_PREFIX}/${STAGE}/"
make_dir "${DN_PREFIX}/${STAGE}/"
move_file "${DN_OUTPUT_HDFS}/part-00000" "${DN_PREFIX}/${STAGE}/redout.txt"



echo
TM_STAGE3=$(date +%s)

#####################################################################
# end time
TM_END=$(date +%s)
TMCOST=$(echo | awk -v A=${TM_START} -v B=${TM_END} '{print B-A;}' )
TMCOST1=$(echo | awk -v A=${TM_START} -v B=${TM_STAGE1} '{print B-A;}' )
TMCOST2=$(echo | awk -v A=${TM_STAGE1} -v B=${TM_STAGE2} '{print B-A;}' )
TMCOST3=$(echo | awk -v A=${TM_STAGE2} -v B=${TM_STAGE3} '{print B-A;}' )

mr_trace "TM start=$TM_START, end=$TM_END"
mr_trace "stage 1=$TM_STAGE1"
mr_trace "stage 2=$TM_STAGE2"
mr_trace "stage 3=$TM_STAGE3"
echo ""

mr_trace "Cost time: total=${TMCOST},stage1=${TMCOST1},stage2=${TMCOST2},stage3=${TMCOST3}, seconds"

#####################################################################

# if you don't use persistent mode
FN_OUTPUT=part-00000
${EXEC_HADOOP} fs -get "${DN_OUTPUT_HDFS}/${FN_OUTPUT}"

}
