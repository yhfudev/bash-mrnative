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
#DN_EXEC="$(my_getpath "${DN_TOP}/bin/")"

#echo "[DBG] $0 DN_EXEC=${DN_EXEC}; DN_TOP=${DN_TOP}" 1>&2

PROGNAME=$(basename "$0")

#####################################################################
DN_INPUT=${DN_TOP}/tmp/input

DN_PREFIX=${DN_TOP}/tmp/output

DN_OUTPUT1=${DN_PREFIX}/1
DN_OUTPUT2=${DN_PREFIX}/2
DN_OUTPUT3=${DN_PREFIX}/3

# start time
TM_START=$(date +%s)

# genrate input file:
mkdir -p ${DN_INPUT}
#find ../projconfigs/ -maxdepth 1 -name "config-*" | xargs -n 1 echo "config" | ./e1map.sh | sort > e1out.txt
#cat e1out.txt | ./e2map.sh | sort | ./e2red.sh > e2out.txt
#find ../projconfigs/ -maxdepth 1 -name "config-*" | xargs -n 1 echo "config" > ${DN_INPUT}/a.txt
find ../mytest/ -maxdepth 1 -name "config-*" | while read a; do echo "config $(my_getpath ${a})" > ${DN_INPUT}/a.txt; done

if [ 1 = 1 ]; then
echo "[${PROGNAME}] Stage 1 ..."
mkdir -p ${DN_OUTPUT1}
cat ${DN_INPUT}/*.txt        | ${DN_EXEC}/e1map.sh | sort > ${DN_OUTPUT1}/mapout.txt
TM_STAGE1_MAP=$(date +%s)
cat ${DN_OUTPUT1}/mapout.txt                              > ${DN_OUTPUT1}/redout.txt
else
#cat ${DN_INPUT}/*.txt        | ${DN_EXEC}/e1map.sh | sort | tee ${DN_OUTPUT1}/mapout.txt | ${DN_EXEC}/e1red.sh > ${DN_OUTPUT1}/redout.txt
TM_STAGE1_MAP=$(date +%s)
fi
TM_STAGE1=$(date +%s)

if [ 1 = 1 ]; then
echo "[${PROGNAME}] Stage 2 ..."
mkdir -p ${DN_OUTPUT2}
cat ${DN_OUTPUT1}/redout.txt | ${DN_EXEC}/e2map.sh | sort > ${DN_OUTPUT2}/mapout.txt
TM_STAGE2_MAP=$(date +%s)
cat ${DN_OUTPUT2}/mapout.txt | ${DN_EXEC}/e2red.sh        > ${DN_OUTPUT2}/redout.txt
else
#cat ${DN_OUTPUT1}/redout.txt | ${DN_EXEC}/e2map.sh | sort | tee ${DN_OUTPUT2}/mapout.txt | ${DN_EXEC}/e2red.sh > ${DN_OUTPUT2}/redout.txt
TM_STAGE2_MAP=$(date +%s)
fi
TM_STAGE2=$(date +%s)

# end time
TM_END=$(date +%s)
TMCOST=$(echo | awk -v A=${TM_START} -v B=${TM_END} '{print B-A;}' )
TMCOST1=$(echo | awk -v A=${TM_START} -v B=${TM_STAGE1} '{print B-A;}' )
TMCOST2=$(echo | awk -v A=${TM_STAGE1} -v B=${TM_STAGE2} '{print B-A;}' )
TMCOST1_MAP=$(echo | awk -v A=${TM_START} -v B=${TM_STAGE1_MAP} '{print B-A;}' )
TMCOST1_RED=$(echo | awk -v A=${TM_STAGE1_MAP} -v B=${TM_STAGE1} '{print B-A;}' )
TMCOST2_MAP=$(echo | awk -v A=${TM_STAGE1} -v B=${TM_STAGE2_MAP} '{print B-A;}' )
TMCOST2_RED=$(echo | awk -v A=${TM_STAGE2_MAP} -v B=${TM_STAGE2} '{print B-A;}' )
echo "[${PROGNAME}] Done !"
echo "[${PROGNAME}] config:"
echo "    HDFF_NUM_CLONE=${HDFF_NUM_CLONE}"
echo "    OPTIONS_FFM_GLOBAL=${OPTIONS_FFM_GLOBAL}"
echo "[${PROGNAME}] Cost time: total=${TMCOST} seconds" 1>&2
echo "    stage1=${TMCOST1}(m=${TMCOST1_MAP},r=${TMCOST1_RED}) seconds" 1>&2
echo "    stage2=${TMCOST2}(m=${TMCOST2_MAP},r=${TMCOST2_RED}) seconds" 1>&2
