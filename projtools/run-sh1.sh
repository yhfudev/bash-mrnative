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
#####################################################################
mr_trace () {
    echo "$(date +"%Y-%m-%d %H:%M:%S,%N" | cut -c1-23) [self=${BASHPID},$(basename $0)] $@" 1>&2
}

#####################################################################

# redirect the output to HDFS so we can fetch back later
HDFF_DN_OUTPUT="$(pwd)/mapreduce-results/"
sed -i -e "s|HDFF_DN_OUTPUT=.*$|HDFF_DN_OUTPUT=${HDFF_DN_OUTPUT}|" "${DN_TOP}/config-sys.sh"

# scratch(temp) dir
HDFF_DN_SCRATCH="/tmp/${USER}/"
DN_SHM=$(df | grep shm | tail -n 1 | awk '{print $6}')
if [ ! "$DN_SHM" = "" ]; then
    HDFF_DN_SCRATCH="${DN_SHM}/${USER}/"
fi
sed -i -e "s|^HDFF_DN_SCRATCH=.*$|HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}|" "${DN_TOP}/config-sys.sh"

# the directory for save the un-tar binary files
HDFF_DN_BIN=""
sed -i -e "s|^HDFF_DN_BIN=.*$|HDFF_DN_BIN=${HDFF_DN_BIN}|" "${DN_TOP}/config-sys.sh"

# tar the binary and save it to HDFS for the node extract it later
# the tar file for ns2 exec
HDFF_FN_TAR_APP=""
sed -i -e "s|^HDFF_FN_TAR_APP=.*$|HDFF_FN_TAR_APP=${HDFF_FN_TAR_APP}|" "${DN_TOP}/config-sys.sh"

# the HDFS path to this project
HDFF_FN_TAR_MRNATIVE=""
sed -i -e "s|^HDFF_FN_TAR_MRNATIVE=.*$|HDFF_FN_TAR_MRNATIVE=${HDFF_FN_TAR_MRNATIVE}|" "${DN_TOP}/config-sys.sh"


#mr_trace "DN_EXEC=${DN_EXEC}; DN_TOP=${DN_TOP}"

PROGNAME=$(basename "$0")

source "${DN_TOP}/config-sys.sh"

#####################################################################
DN_INPUT=${HDFF_DN_OUTPUT}/mapred-data/input

DN_PREFIX=${HDFF_DN_OUTPUT}/mapred-data/output

DN_OUTPUT1=${DN_PREFIX}/1
DN_OUTPUT2=${DN_PREFIX}/2
DN_OUTPUT3=${DN_PREFIX}/3

# start time
TM_START=$(date +%s)

# generate config lines
if [ 1 = 1 ]; then
    # genrate input file:
    mkdir -p ${DN_INPUT}
    rm -f ${DN_INPUT}/*.txt
    #find ../projconfigs/ -maxdepth 1 -name "config-*" | while read a; do echo -e "config\t\"$(my_getpath ${a})\"" >> ${DN_INPUT}/input.txt; done
    find ../mytest/ -maxdepth 1 -name "config-*" | while read a; do echo -e "config\t\"$(my_getpath ${a})\"" >> ${DN_INPUT}/input.txt; done
fi

if [ 1 = 1 ]; then
mr_trace "Stage 1 ..."
mkdir -p ${DN_OUTPUT1}
cat ${DN_INPUT}/*.txt        | ${DN_EXEC}/e1map.sh | sort > ${DN_OUTPUT1}/mapout.txt
TM_STAGE1_MAP=$(date +%s)
cat ${DN_OUTPUT1}/mapout.txt | cat                        > ${DN_OUTPUT1}/redout.txt
else
#cat ${DN_INPUT}/*.txt        | ${DN_EXEC}/e1map.sh | sort | tee ${DN_OUTPUT1}/mapout.txt | ${DN_EXEC}/e1red.sh > ${DN_OUTPUT1}/redout.txt
TM_STAGE1_MAP=$(date +%s)
fi
TM_STAGE1=$(date +%s)

if [ 1 = 1 ]; then
mr_trace "[Stage 2 ..."
mkdir -p ${DN_OUTPUT2}
cat ${DN_OUTPUT1}/redout.txt | ${DN_EXEC}/e2map.sh | sort > ${DN_OUTPUT2}/mapout.txt
TM_STAGE2_MAP=$(date +%s)
cat ${DN_OUTPUT2}/mapout.txt | ${DN_EXEC}/e2red.sh        > ${DN_OUTPUT2}/redout.txt
else
#cat ${DN_OUTPUT1}/redout.txt | ${DN_EXEC}/e2map.sh | sort | tee ${DN_OUTPUT2}/mapout.txt | ${DN_EXEC}/e2red.sh > ${DN_OUTPUT2}/redout.txt
TM_STAGE2_MAP=$(date +%s)
fi
TM_STAGE2=$(date +%s)

if [ 1 = 1 ]; then
mr_trace "[Stage 3 ..."
mkdir -p ${DN_OUTPUT3}
cat ${DN_OUTPUT2}/redout.txt | ${DN_EXEC}/e3map.sh | sort > ${DN_OUTPUT3}/mapout.txt
TM_STAGE3_MAP=$(date +%s)
cat ${DN_OUTPUT3}/mapout.txt | cat                        > ${DN_OUTPUT3}/redout.txt
else
#cat ${DN_OUTPUT2}/redout.txt | ${DN_EXEC}/e3map.sh | sort | tee ${DN_OUTPUT3}/mapout.txt | ${DN_EXEC}/e3red.sh > ${DN_OUTPUT3}/redout.txt
TM_STAGE3_MAP=$(date +%s)
fi
TM_STAGE3=$(date +%s)

# end time
TM_END=$(date +%s)
TMCOST=$(echo | awk -v A=${TM_START} -v B=${TM_END} '{print B-A;}' )
TMCOST1=$(echo | awk -v A=${TM_START} -v B=${TM_STAGE1} '{print B-A;}' )
TMCOST2=$(echo | awk -v A=${TM_STAGE1} -v B=${TM_STAGE2} '{print B-A;}' )
TMCOST1_MAP=$(echo | awk -v A=${TM_START} -v B=${TM_STAGE1_MAP} '{print B-A;}' )
TMCOST1_RED=$(echo | awk -v A=${TM_STAGE1_MAP} -v B=${TM_STAGE1} '{print B-A;}' )
TMCOST2_MAP=$(echo | awk -v A=${TM_STAGE1} -v B=${TM_STAGE2_MAP} '{print B-A;}' )
TMCOST2_RED=$(echo | awk -v A=${TM_STAGE2_MAP} -v B=${TM_STAGE2} '{print B-A;}' )
TMCOST3_MAP=$(echo | awk -v A=${TM_STAGE2} -v B=${TM_STAGE3_MAP} '{print B-A;}' )
TMCOST3_RED=$(echo | awk -v A=${TM_STAGE3_MAP} -v B=${TM_STAGE3} '{print B-A;}' )

mr_trace "TM start=$TM_START, end=$TM_END"
mr_trace "stage 1 map=$TM_STAGE1_MAP, reduce=$TM_STAGE1"
mr_trace "stage 2 map=$TM_STAGE2_MAP, reduce=$TM_STAGE2"
mr_trace "stage 3 map=$TM_STAGE3_MAP, reduce=$TM_STAGE3"
echo ""

mr_trace "Done !"
mr_trace "config:"
mr_trace "    HDFF_NUM_CLONE=${HDFF_NUM_CLONE}"
mr_trace "    OPTIONS_FFM_GLOBAL=${OPTIONS_FFM_GLOBAL}"
mr_trace "Cost time: total=${TMCOST} seconds" 1>&2
mr_trace "    stage1=${TMCOST1}(m=${TMCOST1_MAP},r=${TMCOST1_RED}) seconds" 1>&2
mr_trace "    stage2=${TMCOST2}(m=${TMCOST2_MAP},r=${TMCOST2_RED}) seconds" 1>&2
mr_trace "    stage3=${TMCOST3}(m=${TMCOST3_MAP},r=${TMCOST3_RED}) seconds" 1>&2
