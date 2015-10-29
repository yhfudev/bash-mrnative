#!/bin/bash
#####################################################################
# include all of the bash library files
#
#
# Copyright 2015 Yunhui Fu
# License: GPL v3.0 or later
#
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
DN_EXEC="$(my_getpath "${DN_TOP}/projtools/")"

#echo "[DBG] DN_EXEC=${DN_EXEC}; DN_TOP=${DN_TOP}" 1>&2

if [ ! "${DN_EXEC_4HADOOP}" = "" ]; then
  DN_EXEC="${DN_EXEC_4HADOOP}"
  DN_TOP="${DN_TOP_4HADOOP}"
fi

#####################################################################
# include all of the bash libraries
DN_COMM="${DN_EXEC}/common"
DN_LIB="${DN_TOP}/lib"

#if [ -f "${DN_LIB}/libbash.sh" ]; then
#. ${DN_LIB}/libbash.sh
#fi
source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libshrt.sh
source ${DN_LIB}/libfs.sh
source ${DN_LIB}/libplot.sh
source ${DN_LIB}/libconfig.sh
source ${DN_EXEC}/libns2config.sh
source ${DN_EXEC}/libns2figures.sh
source ${DN_EXEC}/libapp.sh
