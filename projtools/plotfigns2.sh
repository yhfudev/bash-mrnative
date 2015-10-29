#!/bin/bash
#####################################################################
# plot figures
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

DN_LIB="$(my_getpath "${DN_TOP}/lib")"

source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libshrt.sh
source ${DN_LIB}/libfs.sh
source ${DN_LIB}/libplot.sh
source ${DN_LIB}/libconfig.sh
source ${DN_EXEC}/libns2config.sh
source ${DN_EXEC}/libns2figures.sh
source ${DN_EXEC}/libapp.sh

cat_file "${DN_TOP}/config-sys.sh" | read_config_file

#####################################################################
convert_eps2png () {
    for FN_FULL in $(find . -maxdepth 1 -type f -name "*.eps" | awk -F/ '{print $2}' | sort) ; do
        FN_BASE=$(echo "${FN_FULL}" | gawk -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
        if [ ! -f "${FN_BASE}.png" ]; then
            mr_trace "eps 2 png: ${FN_FULL}  -->  ${FN_BASE}.png"
            convert -density 300 "${FN_FULL}" "${FN_BASE}.png"
        fi
    done
}

#####################################################################
ARG_CMD1=$1
shift
ARG_PREFIX1=$1
shift
ARG_TYPE1=$1
shift
ARG_FLOW_TYPE1=$1
shift
ARG_SCHE1=$1
shift
ARG_NUM1=$1
shift

mr_trace "received: cmd='${ARG_CMD1}', prefix='${ARG_PREFIX1}', type='${ARG_TYPE1}', flow='${ARG_FLOW_TYPE1}', sche='${ARG_SCHE1}', num='${ARG_NUM1}'"

ARG_CMD=$( unquote_filename "${ARG_CMD1}" )
ARG_PREFIX=$( unquote_filename "${ARG_PREFIX1}" )
ARG_TYPE=$( unquote_filename "${ARG_TYPE1}" )
ARG_FLOW_TYPE=$( unquote_filename "${ARG_FLOW_TYPE1}" )
ARG_SCHE=$( unquote_filename "${ARG_SCHE1}" )
ARG_NUM=$( unquote_filename "${ARG_NUM1}" )

mr_trace "after processed: cmd='${ARG_CMD}', prefix='${ARG_PREFIX}', type='${ARG_TYPE}', flow='${ARG_FLOW_TYPE}', sche='${ARG_SCHE}', num='${ARG_NUM}'"

DN_TEST=$(simulation_directory "${ARG_PREFIX}" "${ARG_TYPE}" "${ARG_SCHE}" "${ARG_NUM}")

make_dir "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"

mr_trace "ARG_CMD=${ARG_CMD}"

case "${ARG_CMD}" in
"bitflow")
    local NSCHE="$(sed 's/[\"\`_]/ /g' <<<${ARG_SCHE})"
    local TITLE="Throughput of ${ARG_NUM} $NSCHE ${ARG_TYPE} flows"
    local TMP_SRC=""
    local TMP_DEST=""
    local DN_SRC="${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}"
    local DN_DEST="${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"

    local DN_ORIG5=$(pwd)
    local RET=$(is_local "${DN_SRC}")
    if [ ! "${RET}" = "l" ]; then
        TMP_SRC="${HDFF_DN_SCRATCH}/file-$(uuidgen)/"
        make_dir "${TMP_SRC}/"
        copy_file "${DN_SRC}/CMTCPDS*.out" "${TMP_SRC}/"
        copy_file "${DN_SRC}/CMUDPDS*.out" "${TMP_SRC}/"
        DN_SRC="${TMP_SRC}/"
    fi
    RET=$(is_local "${DN_DEST}")
    if [ ! "${RET}" = "l" ]; then
        TMP_DEST="${HDFF_DN_SCRATCH}/file-$(uuidgen)/"
        make_dir "${TMP_DEST}/"
        DN_DEST="${TMP_DEST}/"
    fi
    case "${ARG_FLOW_TYPE}" in
    "tcp")
        plot_eachflow_throughput "${DN_SRC}" "${DN_DEST}" "${DN_TEST}" "${TITLE}" "CMTCPDS*.out"
        ;;
    "udp")
        plot_eachflow_throughput "${DN_SRC}" "${DN_DEST}" "${DN_TEST}" "${TITLE}" "CMUDPDS*.out"
        ;;
    *)
        mr_trace "Error: Unknown flow type: ${ARG_FLOW_TYPE}"
        exit 1
        ;;
    esac
    cd "${DN_DEST}"
    convert_eps2png
    cd "${DN_ORIG5}"
    if [ ! "${TMP_DEST}" = "" ]; then
        copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"
        rm_f_dir "${TMP_DEST}"
    fi
    if [ ! "${TMP_SRC}" = "" ]; then
        rm_f_dir "${TMP_SRC}"
    fi
    ;;

"tpstat")
    local FN_CONFIG_PROJ=$ARG_FLOW_TYPE
    cat_file "${FN_CONFIG_PROJ}" | read_config_file

    local TMP_DEST=""
    local DN_SRC="${HDFF_DN_OUTPUT}/dataconf/"
    local DN_DEST="${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"
    local RET=$(is_local "${DN_DEST}")
    if [ ! "${RET}" = "l" ]; then
        TMP_DEST="${HDFF_DN_SCRATCH}/file-$(uuidgen)/"
        make_dir "${TMP_DEST}/"
        DN_DEST="${TMP_DEST}/"
    fi

    local DN_ORIG5=$(pwd)
    FN_TP="${HDFF_DN_SCRATCH}/tmp-avgtp-stats-udp-${ARG_PREFIX}-${ARG_TYPE}-$(uuidgen).dat"
    generate_throughput_stats_file "${DN_SRC}" "${ARG_PREFIX}" "${ARG_TYPE}" "${ARG_FLOW_TYPE}" "notfound.out"    "CM??PDS*.out" "${FN_TP}"

    gplot_draw_statfig "${FN_TP}"  6 "Aggregate Throughput"  "Throughput (bps)" "fig-aggtp-${ARG_PREFIX}-${ARG_TYPE}" "${DN_DEST}"
    gplot_draw_statfig "${FN_TP}"  7 "Average Throughput"    "Throughput (bps)" "fig-avgtp-${ARG_PREFIX}-${ARG_TYPE}" "${DN_DEST}"
    gplot_draw_statfig "${FN_TP}" 10 "Jain's Fairness Index" "JFI"              "fig-jfi-${ARG_PREFIX}-${ARG_TYPE}" "${DN_DEST}"
    gplot_draw_statfig "${FN_TP}" 11 "CFI"                   "CFI"              "fig-cfi-${ARG_PREFIX}-${ARG_TYPE}" "${DN_DEST}"
    #rm -f "${FN_TP}"
    cd "${DN_ORIG5}"
    cd "${DN_DEST}"
    convert_eps2png
    cd "${DN_ORIG5}"
    if [ ! "${TMP_DEST}" = "" ]; then
        copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"
        rm_f_dir "${TMP_DEST}"
    fi
    ;;

"pktstat")
    DN_ORIG6=$(pwd)
    local TMP_DEST=""
    local DN_DEST="${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"
    local RET=$(is_local "${DN_DEST}")
    if [ ! "${RET}" = "l" ]; then
        TMP_DEST="${HDFF_DN_SCRATCH}/file-$(uuidgen)/"
        make_dir "${TMP_DEST}/"
        DN_DEST="${TMP_DEST}/"
    fi
    plot_pktdelay_queue "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "${DN_DEST}" "${DN_TEST}"
    cd "${DN_DEST}"
    convert_eps2png
    cd "${DN_ORIG6}"
    if [ ! "${TMP_DEST}" = "" ]; then
        copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"
        rm_f_dir "${TMP_DEST}"
    fi
    ;;

"pkttrans")
    DN_ORIG6=$(pwd)
    local TMP_DEST=""
    local DN_DEST="${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"
    local RET=$(is_local "${DN_DEST}")
    if [ ! "${RET}" = "l" ]; then
        TMP_DEST="${HDFF_DN_SCRATCH}/file-$(uuidgen)/"
        make_dir "${TMP_DEST}/"
        DN_DEST="${TMP_DEST}/"
    fi
    plot_pktdelay_trans "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "${DN_DEST}" "${DN_TEST}"
    cd "${DN_DEST}"
    convert_eps2png
    cd "${DN_ORIG6}"
    if [ ! "${TMP_DEST}" = "" ]; then
        copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"
        rm_f_dir "${TMP_DEST}"
    fi
    ;;
*)
    mr_trace "Error: unknown command: ${ARG_CMD}"
    ;;
esac
