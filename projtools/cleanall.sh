#!/bin/bash
#
# check all of folders
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
DN_EXEC=$(dirname $(my_getpath "$0") )
#####################################################################

source ${DN_COMM}/libbash.sh

DN_PARENT="$(my_getpath ".")"

list_folders=(
    "proj-verify-d30"
    "proj-verify-d31"
    "proj-base-prof-high2low"
    "proj-base-prof-low2high"
)

for idx_folder in ${list_folders[*]} ; do
    cd "$idx_folder"
    ../cleanproj.sh
    echo "leave $idx_folder"
    cd ..
done

echo "$(date) DONE: ALL" >> "${FN_LOG}"
