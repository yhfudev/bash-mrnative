#!/bin/sh
#####################################################################
# run hadoop in HPC PBS
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
    DN_EXEC="$(my_getpath "${DN_EXEC}")/"
else
    DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
#####################################################################
rm -f pbs_hadoop_run.stderr
rm -f pbs_hadoop_run.stdout
rm -rf hadoopconfig-*
rm -f /scratch1/$USER/project/myhadoop-example/pbs_hadoop_run.stderr
rm -f /scratch1/$USER/project/myhadoop-example/pbs_hadoop_run.stdout
rm -rf /scratch1/$USER/project/myhadoop-example/hadoopconfig-*

if [ 0 = 1 ]; then
sed -i \
    -e 's|#PBS -l select=1.*$|#PBS -l select=256:ncpus=8:mem=14gb|' \
    "mod-hadooppbs-jobmain.sh"

sed -i \
    -e 's|#PBS -l select=1.*$|#PBS -l select=1:ncpus=24:mem=100gb|' \
    "mod-hadooppbs-jobmain.sh"
fi

qsub \
    -N ns2ds31 \
    -l select=1:ncpus=8:mem=6gb \
    "mod-hadooppbs-jobmain.sh"

qstat -anu ${USER}
