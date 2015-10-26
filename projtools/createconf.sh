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

#source "${DN_TOP}/config-sys.sh"
read_config_file "${DN_TOP}/config-sys.sh"
DN_RESULTS="$(my_getpath "${HDFF_DN_OUTPUT}")"

check_global_config

#####################################################################
MR_COMMAND=$1
shift
FN_CONFIG_PROJ=$1
shift
if [ ! -f "${FN_CONFIG_PROJ}" ]; then
    mr_trace "Error: not found file: $FN_CONFIG_PROJ"
    exit 1
fi
FN_CONFIG_PROJ2="$(my_getpath "${FN_CONFIG_PROJ}")"
#source ${FN_CONFIG_PROJ2}
read_config_file "${FN_CONFIG_PROJ2}"

#####################################################################
DN_TMP_CREATECONF="$(my_getpath "${DN_SCRATCH}/tmp-createconf")"
rm -rf "${DN_TMP_CREATECONF}"
mkdir -p "${DN_TMP_CREATECONF}"
for idx_num in $LIST_NODE_NUM ; do
    for idx_type in $LIST_TYPES ; do
        for idx_sche in $LIST_SCHEDULERS ; do
            prepare_one_tcl_scripts "${PREFIX}" "$idx_type" "$idx_sche" "$idx_num" "${DN_EXEC}" "${DN_COMM}" "${DN_TMP_CREATECONF}"
            echo -e "${MR_COMMAND}\t\"${FN_CONFIG_PROJ2}\"\t\"${PREFIX}\"\t\"${idx_type}\"\t\"${idx_sche}\"\t${idx_num}"
        done
    done
done
mkdir -p "${DN_RESULTS}/dataconf/"

#DN_ORIG15=$(pwd)
#cd "${DN_TMP_CREATECONF}"
#tar -cf - * | tar -C "${DN_RESULTS}/dataconf/" -xf -
#cd "${DN_ORIG15}"

mr_trace "create conf: rsync from temp to result dir: ${DN_TMP_CREATECONF}/ --> ${DN_RESULTS}/dataconf/"
rsync -av --log-file "${DN_RESULTS}/rsync-log-createconf-copyback-1.log" "${DN_TMP_CREATECONF}/" "${DN_RESULTS}/dataconf/" 1>&2
rsync -av --log-file "${DN_RESULTS}/rsync-log-createconf-copyback-2.log" "${DN_TMP_CREATECONF}/" "${DN_RESULTS}/dataconf/" 1>&2
if [ ! "$?" = "0" ]; then
    mr_trace "Error: copy temp dir: ${DN_TMP_CREATECONF}/ to ${DN_RESULTS}/dataconf/"
    exit 1
fi

#rm -rf "${DN_TMP_CREATECONF}"

mr_trace "DONE create config files"
