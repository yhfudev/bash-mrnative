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


ARG_CMD=$1
shift
ARG_PREFIX=$1
shift
ARG_TYPE=$1
shift
ARG_FLOW_TYPE=$1
shift
ARG_SCHE=$1
shift
ARG_NUM=$1
shift

DN_TEST=$(simulation_directory "${ARG_PREFIX}" "${ARG_TYPE}" "${ARG_SCHE}" "${ARG_NUM}")
case "${ARG_CMD}" in
"tpflow")
    TTT="$(sed 's/[\"\`_]/ /g' <<<${ARG_SCHE})"
    TITLE="Throughput of ${ARG_NUM} $TTT ${ARG_TYPE} flows"
    case "${ARG_FLOW_TYPE}" in
    "tcp")
        plot_eachflow_throughput "${DN_TOP}/results/${DN_TEST}" "${DN_TOP}/figures/${DN_TEST}" "${TITLE}" "CMTCPDS*.out"
        ;;
    "udp")
        plot_eachflow_throughput "${DN_TOP}/results/${DN_TEST}" "${DN_TOP}/figures/${DN_TEST}" "${TITLE}" "CMUDPDS*.out"
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
    source ${FN_CONFIG_PROJ2}

    FN_TP="tmp-avgtp-stats-udp-${PARAM_PREFIX}-${PARAM_TYPE}.dat"
    case "${ARG_FLOW_TYPE}" in
    "tcp")
        generate_throughput_stats_file "${PARAM_PREFIX}" "${PARAM_TYPE}" "tcp" "DSFTPTCPstats*.out" "CMTCPDS*.out" "${FN_TP}"
        ;;
    "udp")
        generate_throughput_stats_file "${PARAM_PREFIX}" "${PARAM_TYPE}" "udp" "DSUDPstats*.out"    "CMUDPDS*.out" "${FN_TP}"
        ;;
    esac
    gplot_draw_statfig "${FN_TP}"  6 "Aggregate Throughput"  "Throughput (bps)" "fig-aggtp-${PARAM_PREFIX}-${PARAM_TYPE}"
    gplot_draw_statfig "${FN_TP}"  7 "Average Throughput"    "Throughput (bps)" "fig-avgtp-${PARAM_PREFIX}-${PARAM_TYPE}"
    gplot_draw_statfig "${FN_TP}" 10 "Jain's Fairness Index" "JFI"              "fig-jfi-${PARAM_PREFIX}-${PARAM_TYPE}"
    gplot_draw_statfig "${FN_TP}" 11 "CFI"                   "CFI"              "fig-cfi-${PARAM_PREFIX}-${PARAM_TYPE}"
    ;;

"pktstat")
    plot_pktdelay_queue "${DN_TOP}/results/${DN_TEST}" "${DN_TOP}/figures/${DN_TEST}" "${DN_TEST}"
    ;;
"pkttrans")
    plot_pktdelay_trans "${DN_TOP}/results/${DN_TEST}" "${DN_TOP}/figures/${DN_TEST}" "${DN_TEST}"
    ;;
*)
    echo "Error: unknown command: ${ARG_CMD}" 1>&2
    ;;
esac
