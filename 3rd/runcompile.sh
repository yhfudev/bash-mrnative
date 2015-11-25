#!/bin/bash

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
    export DN_EXEC="$(my_getpath "${DN_EXEC}")/"
else
    export DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
DN_EXEC="$(my_getpath "${DN_TOP}/projtools/")"

DN_COMPILE="${DN_TOP}/buildfromsrc"

compile_source () {
    PARAM_MAKEFILE="$1"
    shift
    PARAM_TARGET="$1"
    shift

    if [ ! "$(which module)" = "" ]; then
        module purge && module load mpc cmake/2.8.7 gcc/4.4 1>&2 # for PBS's gcc
    fi
    mkdir -p "${DN_COMPILE}" 1>&2
    cd "${DN_COMPILE}" 1>&2
    cp "${DN_TOP}/3rd/${PARAM_MAKEFILE}" Makefile 1>&2
    sed -i "s|^PREFIX=.*$|PREFIX=${DN_TOP}/3rdbin/|g" Makefile 1>&2
    sed -i "s|^DN_PATCH=.*$|DN_PATCH=${DN_TOP}/3rd|g" Makefile 1>&2
    #sed -i "s|^USE_GPU=.*$|USE_GPU=1|g" Makefile 1>&2
    cat "${DN_TOP}/3rd/${PARAM_MAKEFILE}" | grep ^include | awk '{print $2; }' | while read a ; do cp "${DN_TOP}/3rd/$a" .; done

    mkdir -p sources
    make get-sources 1>&2
    make ${PARAM_TARGET} 1>&2
}

compile_source Makefile.gnuplot all
compile_source Makefile.ffmpeg all
compile_source Makefile.ns2 all
