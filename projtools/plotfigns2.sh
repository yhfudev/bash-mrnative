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

DN_LIB="$(my_getpath "${DN_TOP}/lib")"

source ${DN_LIB}/libbash.sh
source ${DN_LIB}/libshrt.sh
source ${DN_LIB}/libplot.sh
source ${DN_LIB}/libns2figures.sh
source ${DN_EXEC}/libapp.sh

#####################################################################
convert_eps2png () {
    for FN_FULL in $(find . -maxdepth 1 -type f -name "*.eps" | awk -F/ '{print $2}' | sort) ; do
        FN_BASE=$(echo "${FN_FULL}" | gawk -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
        if [ ! -f "${FN_BASE}.png" ]; then
            echo "eps 2 png: ${FN_FULL}  -->  ${FN_BASE}.png" 1>&2
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

ARG_CMD=$( unquote_filename "${ARG_CMD1}" )
ARG_PREFIX=$( unquote_filename "${ARG_PREFIX1}" )
ARG_TYPE=$( unquote_filename "${ARG_TYPE1}" )
ARG_FLOW_TYPE=$( unquote_filename "${ARG_FLOW_TYPE1}" )
ARG_SCHE=$( unquote_filename "${ARG_SCHE1}" )
ARG_NUM=$( unquote_filename "${ARG_NUM1}" )

DN_TEST=$(simulation_directory "${ARG_PREFIX}" "${ARG_TYPE}" "${ARG_SCHE}" "${ARG_NUM}")
mkdir -p "${DN_TOP}/figures/${ARG_PREFIX}"

echo "$(basename $0) ARG_CMD=${ARG_CMD}" 1>&2

case "${ARG_CMD}" in
"tpflow")
    TTT="$(sed 's/[\"\`_]/ /g' <<<${ARG_SCHE})"
    TITLE="Throughput of ${ARG_NUM} $TTT ${ARG_TYPE} flows"

    case "${ARG_FLOW_TYPE}" in
    "tcp")
        plot_eachflow_throughput "${DN_TOP}/results/${DN_TEST}" "${DN_TOP}/figures/${ARG_PREFIX}" "${DN_TEST}" "${TITLE}" "CMTCPDS*.out"
        ;;
    "udp")
        plot_eachflow_throughput "${DN_TOP}/results/${DN_TEST}" "${DN_TOP}/figures/${ARG_PREFIX}" "${DN_TEST}" "${TITLE}" "CMUDPDS*.out"
        ;;
    *)
        echo "$(basename $0) Error: Unknown flow type: ${ARG_FLOW_TYPE}" 1>&2
        ;;
    esac
    ;;

"tpstat")
    FN_CONFIG_PROJ=$ARG_FLOW_TYPE
    if [ ! -f "${FN_CONFIG_PROJ}" ]; then
        echo "Error: not found file: $FN_CONFIG_PROJ" 1>&2
        exit 1
    fi
    FN_CONFIG_PROJ2="$(my_getpath "${FN_CONFIG_PROJ}")"
    read_config_file "${FN_CONFIG_PROJ2}"

    cd "${DN_TOP}/results/"
    FN_TP="$(pwd)/tmp-avgtp-stats-udp-${ARG_PREFIX}-${ARG_TYPE}.dat"
    generate_throughput_stats_file "${ARG_PREFIX}" "${ARG_TYPE}" "${ARG_FLOW_TYPE}" "notfound.out"    "CM??PDS*.out" "${FN_TP}"

    gplot_draw_statfig "${FN_TP}"  6 "Aggregate Throughput"  "Throughput (bps)" "fig-aggtp-${ARG_PREFIX}-${ARG_TYPE}" "${DN_TOP}/figures/${ARG_PREFIX}"
    gplot_draw_statfig "${FN_TP}"  7 "Average Throughput"    "Throughput (bps)" "fig-avgtp-${ARG_PREFIX}-${ARG_TYPE}" "${DN_TOP}/figures/${ARG_PREFIX}"
    gplot_draw_statfig "${FN_TP}" 10 "Jain's Fairness Index" "JFI"              "fig-jfi-${ARG_PREFIX}-${ARG_TYPE}" "${DN_TOP}/figures/${ARG_PREFIX}"
    gplot_draw_statfig "${FN_TP}" 11 "CFI"                   "CFI"              "fig-cfi-${ARG_PREFIX}-${ARG_TYPE}" "${DN_TOP}/figures/${ARG_PREFIX}"
    #rm -f "${FN_TP}"
    cd - > /dev/null
    cd "${DN_TOP}/figures/${ARG_PREFIX}"
    convert_eps2png
    cd - > /dev/null
    ;;

"pktstat")
    plot_pktdelay_queue "${DN_TOP}/results/${DN_TEST}" "${DN_TOP}/figures/${ARG_PREFIX}" "${DN_TEST}"
    ;;
"pkttrans")
    plot_pktdelay_trans "${DN_TOP}/results/${DN_TEST}" "${DN_TOP}/figures/${ARG_PREFIX}" "${DN_TEST}"
    cd "${DN_TOP}/figures/${ARG_PREFIX}"
    convert_eps2png
    cd - > /dev/null
    ;;
*)
    echo "Error: unknown command: ${ARG_CMD}" 1>&2
    ;;
esac
