#!/bin/bash
#
# the app related functions
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
  if [ "${FN}" = "" ]; then
    echo "${DN}"
  else
    echo "${DN}/${FN}"
  fi
}
DN_EXEC=$(dirname $(my_getpath "$0") )
if [ ! "${DN_EXEC}" = "" ]; then
    DN_EXEC="$(my_getpath "${DN_EXEC}")/"
else
    DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
#DN_EXEC="$(my_getpath "${DN_TOP}/bin/")"
#####################################################################

EXEC_NS2="$(my_getpath "${DN_EXEC}/../../ns")"

DN_COMM="$(my_getpath "${DN_EXEC}/common")"
DN_LIB="$(my_getpath "${DN_TOP}/lib")"

source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libshrt.sh
source ${DN_LIB}/libns2figures.sh
source ${DN_EXEC}/libapp.sh

FN_CONFIG_PROJ=$1
if [ ! -f "${FN_CONFIG_PROJ}" ]; then
    echo "Error: not found file: $FN_CONFIG_PROJ" 1>&2
    exit 1
fi
FN_CONFIG_PROJ2="$(my_getpath "${FN_CONFIG_PROJ}")"
source ${FN_CONFIG_PROJ2}

check_global_config

#####################################################################

for idx_num in ${list_nodes_num[*]} ; do
    for idx_type in ${list_types[*]} ; do
        for idx_sche in ${list_schedules[*]} ; do
            #prepare_one_tcl_scripts "${PREFIX}" "${list_types[$idx_type]}" "${list_schedules[$idx_sche]}" "${list_nodes_num[$idx_num]}"
            prepare_one_tcl_scripts "${PREFIX}" "$idx_type" "$idx_sche" "$idx_num" "${DN_EXEC}" "${DN_COMM}" "${DN_TOP}/results"
            echo "sim \"${FN_CONFIG_PROJ2}\" ${PREFIX} $idx_type $idx_sche $idx_num"
        done
    done
done

echo "$(date) DONE: ALL" >> "${FN_LOG}"
