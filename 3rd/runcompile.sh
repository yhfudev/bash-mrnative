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
    PARAM_TARGET="$@"
    shift

    module
    if [ "$?" = "0" ]; then
        module purge && module load mpc cmake/2.8.7 gcc/4.4 1>&2 # for PBS's gcc
    fi
    mkdir -p "${DN_COMPILE}" 1>&2
    cd "${DN_COMPILE}" 1>&2
    cp "${DN_EXEC}/${PARAM_MAKEFILE}" Makefile 1>&2
    sed -i "s|^PREFIX=.*$|PREFIX=${DN_EXEC}/${PREFIX}-bin/|g"  Makefile 1>&2
    sed -i "s|^DN_SRC=.*$|DN_SRC=${DN_EXEC}/sources/|g" Makefile 1>&2
    sed -i "s|^DN_PATCH=.*$|DN_PATCH=${DN_EXEC}|g"  Makefile 1>&2
    #sed -i "s|^USE_GPU=.*$|USE_GPU=1|g" Makefile 1>&2
    cat "${DN_EXEC}/${PARAM_MAKEFILE}" | grep ^include | awk '{print $2; }' | while read a ; do cp "${DN_EXEC}/$a" .; done

    mkdir -p ${DN_EXEC}/sources/
    make get-sources 1>&2
    make ${PARAM_TARGET} 1>&2
}

#compile_source Makefile.gnuplot all
#compile_source Makefile.ffmpeg all
#compile_source Makefile.ns2 all

# qsub -I -l select=1:ncpus=8:ngpus=2:mem=10gb,walltime=72:00:00
# qsub -I -l select=1:ncpus=24:ngpus=2:mem=100gb,walltime=72:00:00

module
if [ "$?" = "0" ]; then
    #module purge && module load mpc cmake/2.8.7 gcc/4.4 1>&2 # for PBS's gcc
    module purge && module load gcc/4.4 cuda-toolkit/7.0.28
fi

NUM=$(cat /proc/cpuinfo | grep processor | wc -l | awk '{print $0 / 1 + 1;}')

#make -j ${NUM} dist-gzip-aircrack
make -j ${NUM} dist-gzip-ffmpeg
# make -j ${NUM} dist-gzip
