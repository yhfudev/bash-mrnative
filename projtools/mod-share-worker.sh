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
  cd "${DN}" > /dev/null 2>&1
  DN=$(pwd)
  cd - > /dev/null 2>&1
  echo "${DN}/${FN}"
}
#DN_EXEC=`echo "$0" | ${EXEC_AWK} -F/ '{b=$1; for (i=2; i < NF; i ++) {b=b "/" $(i)}; print b}'`
DN_EXEC=$(dirname $(my_getpath "$0") )
if [ ! "${DN_EXEC}" = "" ]; then
    export DN_EXEC="$(my_getpath "${DN_EXEC}")/"
else
    export DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
DN_EXEC="$(my_getpath "${DN_TOP}/projtools/")"
#####################################################################

PROGNAME=$(basename "$0")

source "${DN_TOP}/config-sys.sh"
DN_RESULTS="$(my_getpath "${HDFF_DN_OUTPUT}")"

echo "DN_TOP=${DN_TOP}; DN_EXEC=${DN_EXEC}; PROGNAME=${PROGNAME}; "

#####################################################################
if [ ! -d "${PROJ_HOME}" ]; then
  PROJ_HOME="${DN_TOP}"
fi
mkdir -p "${PROJ_HOME}"
if [ ! "$?" = "0" ]; then echo "$(basename $0) Error in mkdir $PROJ_HOME" 1>&2 ; fi
PROJ_HOME="$(my_getpath "${PROJ_HOME}")"

echo "PROJ_HOME=${PROJ_HOME}; EXEC_HADOOP=${EXEC_HADOOP}; HDJAR=${HDJAR}; "

# detect if the DN_EXEC is real directory of the binary code
# this is for PBS/HPC environment
if [ ! "${PROJ_HOME}" = "${DN_TOP}" ]; then
  #if [ ! -x "${DN_EXEC}/mod-share-worker.sh" ]; then
    DN_TOP="${PROJ_HOME}"
    DN_EXEC="${PROJ_HOME}/$(basename $DN_EXEC)"
  #fi
fi

echo "DN_TOP=${DN_TOP}; DN_EXEC=${DN_EXEC}; PROGNAME=${PROGNAME}; "
echo "PROJ_HOME=${PROJ_HOME}"

#####################################################################
EXEC_HADOOP="${HADOOP_HOME}/bin/hadoop --config ${HADOOP_CONF_DIR}"

#HDJAR=${HADOOP_HOME}/contrib/streaming/hadoop-streaming-1.2.1.jar
if [ ! -f "${HDJAR}" ]; then
    HDJAR=${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-streaming-2.7.1.jar
fi
if [ ! -f "${HDJAR}" ]; then
    HDJAR=${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-streaming-2.3.0.jar
fi
if [ ! -f "${HDJAR}" ]; then
    HDJAR=/usr/lib/hadoop-0.20-mapreduce/contrib/streaming/hadoop-streaming-2.0.0-mr1-cdh4.4.0.jar
fi
if [ ! -f "${HDJAR}" ]; then
    HDJAR=/usr/lib/hadoop-mapreduce/hadoop-streaming.jar
fi
echo "EXEC_HADOOP=${EXEC_HADOOP}; HDJAR=${HDJAR}; "

#####################################################################
generate_script_4hadoop () {
  PARAM_ORIG="$1"
  shift
  PARAM_OUTPUT="$1"
  shift
  DN_FILE9=$(dirname "${PARAM_ORIG}")
  DN_EXEOUT9=$(dirname "${PARAM_OUTPUT}")
  if [ ! -d "${DN_EXEOUT9}" ]; then
    mkdir -p "${DN_EXEOUT9}"
    if [ ! "$?" = "0" ]; then echo "$(basename $0) Error in mkdir $DN_EXEOUT9" 1>&2 ; fi
  fi

  echo '#!/bin/bash' > "${PARAM_OUTPUT}"
  echo "DN_EXEC_4HADOOP=${DN_EXEC}" >> "${PARAM_OUTPUT}"
  echo "DN_TOP_4HADOOP=${DN_TOP}" >> "${PARAM_OUTPUT}"
  echo "DN_EXEC=${DN_EXEC}" >> "${PARAM_OUTPUT}"
  echo "DN_TOP=${DN_TOP}" >> "${PARAM_OUTPUT}"
  cat "${DN_TOP}/lib/libbash.sh" >> "${PARAM_OUTPUT}"
  cat "${DN_TOP}/lib/libshrt.sh" >> "${PARAM_OUTPUT}"
  cat "${DN_TOP}/lib/libplot.sh" >> "${PARAM_OUTPUT}"
  cat "${DN_TOP}/lib/libns2figures.sh" >> "${PARAM_OUTPUT}"
  cat "${DN_FILE9}/libapp.sh" >> "${PARAM_OUTPUT}"
  echo "DN_EXEC_4HADOOP=${DN_EXEC}" >> "${PARAM_OUTPUT}"
  echo "DN_TOP_4HADOOP=${DN_TOP}" >> "${PARAM_OUTPUT}"
  echo "DN_EXEC=${DN_EXEC}" >> "${PARAM_OUTPUT}"
  echo "DN_TOP=${DN_TOP}" >> "${PARAM_OUTPUT}"
  cat "${PARAM_ORIG}" \
    | grep -v "libbash.sh" \
    | grep -v "libshrt.sh" \
    | grep -v "libplot.sh" \
    | grep -v "libns2figures.sh" \
    | grep -v "libapp.sh" \
    | sed -e "s|EXEC_NS2=.*$|EXEC_NS2=$(which ns)|" \
    >> "${PARAM_OUTPUT}"
}
#####################################################################


mapred_main () {

# start time
TM_START=$(date +%s)

# generate config lines
#DN_INPUT="${PROJ_HOME}/data/input/"
DN_INPUT=${DN_RESULTS}/mapred-data/input
DN_PREFIX=${DN_RESULTS}/mapred-data/output

if [ 1 = 1 ]; then
    # genrate input file:
    mkdir -p ${DN_INPUT}
    if [ ! "$?" = "0" ]; then echo "$(basename $0) Error in mkdir $DN_INPUT" 1>&2 ; fi
    rm -f ${DN_INPUT}/*
    #find ../projconfigs/ -maxdepth 1 -name "config-*" | while read a; do echo -e "config\t\"$(my_getpath ${a})\"" >> ${DN_INPUT}/input.txt; done
    find ../mytest/ -maxdepth 1 -name "config-*" | while read a; do echo -e "config\t\"$(my_getpath ${a})\"" >> ${DN_INPUT}/input.txt; done
fi

#generate_script_4hadoop "${DN_EXEC}/plotfigns2.sh" "${DN_PREFIX}/tmp/plotfigns2.sh"
#generate_script_4hadoop "${DN_EXEC}/createconf.sh" "${DN_PREFIX}/tmp/createconf.sh"

FN_MAP="${DN_PREFIX}/tmp/tmpe1map.sh"
#FN_RED="${DN_PREFIX}/tmp/tmpe1red.sh"
generate_script_4hadoop "${DN_EXEC}/e1map.sh" "${FN_MAP}"
#generate_script_4hadoop "${DN_EXEC}/e1red.sh" "${FN_RED}"

STAGE=1
DN_INPUT_HDFS=/hadoopffmpeg_in${STAGE}
DN_OUTPUT_HDFS=/hadoopffmpeg_out${STAGE}

${EXEC_HADOOP} fs -rm -f -r "${DN_INPUT_HDFS}"
${EXEC_HADOOP} fs -mkdir -p "${DN_INPUT_HDFS}"
if [ ! "$?" = "0" ]; then
    echo "$(basename $0) Error in hadoop mkdir ${DN_INPUT_HDFS}" 1>&2
    return
fi
${EXEC_HADOOP} fs -put "${DN_INPUT}/"* "${DN_INPUT_HDFS}"
if [ ! "$?" = "0" ]; then
    echo "Error in put data: ${DN_INPUT_HDFS}" 1>&2
    return
fi
${EXEC_HADOOP} fs -ls "${DN_INPUT_HDFS}"
#${EXEC_HADOOP} fs -cat "${DN_INPUT_HDFS}/test.txt"

${EXEC_HADOOP} fs -ls "${DN_OUTPUT_HDFS}"

#${EXEC_HADOOP} fs -cat "${DN_OUTPUT_HDFS}/part-00000"

if [ 1 = 1 ]; then
echo "[${PROGNAME}] Stage 1 ..."
${EXEC_HADOOP} fs -rm -f -r "${DN_OUTPUT_HDFS}"
${EXEC_HADOOP} jar ${HDJAR} \
    -D mapreduce.task.timeout=0 \
    -D stream.num.map.output.key.fields=6 \
    -D num.key.fields.for.partition=6 \
    -input "${DN_INPUT_HDFS}" -output "${DN_OUTPUT_HDFS}" \
    -file "${FN_MAP}" -mapper  $(basename "${FN_MAP}") \
    -mapper /bin/cat \
    $(NULL)
fi

${EXEC_HADOOP} fs -ls "${DN_OUTPUT_HDFS}"
#${EXEC_HADOOP} fs -cat "${DN_OUTPUT_HDFS}/part-00000"
mkdir -p "${DN_PREFIX}/${STAGE}/"
if [ ! "$?" = "0" ]; then echo "$(basename $0) Error in mkdir ${DN_PREFIX}/${STAGE}/" 1>&2 ; fi
rm -f "${DN_PREFIX}/${STAGE}/"*
${EXEC_HADOOP} fs -get "${DN_OUTPUT_HDFS}/part-00000" "${DN_PREFIX}/${STAGE}/redout.txt"

echo
TM_STAGE1=$(date +%s)


#####################################################################
# use hundreds of files instead of one small file:
cd "${DN_PREFIX}/${STAGE}/"
rm -f file*.txt
cat "redout.txt" \
    | awk 'BEGIN{cnt=0;}{cnt ++; print $0 > "file" cnt ".txt"}'
cd -

${EXEC_HADOOP} fs -rm -f "${DN_OUTPUT_HDFS}/part-00000"
${EXEC_HADOOP} fs -put "${DN_PREFIX}/${STAGE}/file"* "${DN_OUTPUT_HDFS}"


#####################################################################

FN_MAP="${DN_PREFIX}/tmp/tmpe2map.sh"
FN_RED="${DN_PREFIX}/tmp/tmpe2red.sh"
generate_script_4hadoop "${DN_EXEC}/e2map.sh" "${FN_MAP}"
generate_script_4hadoop "${DN_EXEC}/e2red.sh" "${FN_RED}"

DN_INPUT_HDFS=${DN_OUTPUT_HDFS}

STAGE=2
DN_OUTPUT_HDFS=/hadoopffmpeg_out${STAGE}

${EXEC_HADOOP} fs -ls "${DN_INPUT_HDFS}"

if [ 1 = 1 ]; then
echo "[${PROGNAME}] Stage 2 ..."
${EXEC_HADOOP} fs -rm -f -r "${DN_OUTPUT_HDFS}"
#-D mapred.reduce.tasks=1
#-D mapred.reduce.tasks=0
#-D N=$(${EXEC_HADOOP} fs -ls ${DN_INPUT_HDFS0} | tail -n +2 | wc -l)
#-mapper  org.apache.hadoop.mapred.lib.IdentityMapper
#-mapper /bin/cat
#-reducer org.apache.hadoop.mapred.lib.IdentityReducer
${EXEC_HADOOP} jar ${HDJAR} \
    -D mapreduce.task.timeout=0 \
    -D stream.num.map.output.key.fields=4 \
    -D num.key.fields.for.partition=2 \
    -input "${DN_INPUT_HDFS}" -output "${DN_OUTPUT_HDFS}" \
    -file "${FN_MAP}" -mapper  $(basename "${FN_MAP}") \
    -file "${FN_RED}" -reducer $(basename "${FN_RED}") \
    $(NULL)
fi

${EXEC_HADOOP} fs -ls "${DN_OUTPUT_HDFS}"
mkdir -p "${DN_PREFIX}/${STAGE}/"
if [ ! "$?" = "0" ]; then echo "$(basename $0) Error in mkdir ${DN_PREFIX}/${STAGE}/" 1>&2 ; fi
${EXEC_HADOOP} fs -get "${DN_OUTPUT_HDFS}/part-00000" "${DN_PREFIX}/${STAGE}/redout.txt"

echo
TM_STAGE2=$(date +%s)

#####################################################################
# end time
TM_END=$(date +%s)
TMCOST=$(echo | awk -v A=${TM_START} -v B=${TM_END} '{print B-A;}' )
TMCOST1=$(echo | awk -v A=${TM_START} -v B=${TM_STAGE1} '{print B-A;}' )
TMCOST2=$(echo | awk -v A=${TM_STAGE1} -v B=${TM_STAGE2} '{print B-A;}' )

echo "[${PROGNAME}] TM start=$TM_START, end=$TM_END"
echo "[${PROGNAME}] stage 1=$TM_STAGE1"
echo "[${PROGNAME}] stage 2=$TM_STAGE2"
echo ""

echo "Cost time: total=${TMCOST},stage1=${TMCOST1},stage2=${TMCOST2}, seconds" 1>&2

#####################################################################

# if you don't use persistent mode
FN_OUTPUT=part-00000
${EXEC_HADOOP} fs -get "${DN_OUTPUT_HDFS}/${FN_OUTPUT}"

}

