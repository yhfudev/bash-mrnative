#!/bin/bash
#
# plot figure in all of folders
#
# Copyright 2015 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################
my_getpath () {
    local PARAM_DN="$1"
    shift
    #readlink -f
    local DN="${PARAM_DN}"
    local FN=
    if [ ! -d "${DN}" ]; then
        FN=$(basename "${DN}")
        DN=$(dirname "${DN}")
    fi
    local DNORIG=$(pwd)
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
DN_BIN="$(my_getpath "${DN_TOP}/bin/")"
DN_EXEC="$(my_getpath ".")"
#####################################################################

HDFF_FUNCTION="plot" ${DN_BIN}/run-sh1.sh "$1"
