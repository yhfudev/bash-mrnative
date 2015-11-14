#!/bin/bash
# bash library
# plot
#
# Copyright 2013 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################
# return the simulation directory name
simulation_directory () {
    echo "${1}_${2}_${3}_${4}"
}

# please include "libfs.sh" before call this function
# get the environment variable LIST_NODE_NUM,LIST_SCHEDULERS from your config file
generate_throughput_stats_file () {
    # the dir contains all of the trace data in LIST_NODE_NUM,LIST_SCHEDULERS
    local PARAM_DN_BASE=$1
    shift
    # the prefix of the test
    local PARAM_PREFIX=$1
    shift
    # the test type, "udp", "tcp", "has", "udp+has", "tcp+has"
    local PARAM_TYPE=$1
    shift
    # the file type, "udp" or "tcp"
    local PARAM_TYPE_FILE=$1
    shift
    # stats file name template
    local PARAM_FN_STAT=$1
    shift
    # flow throughput file name template
    local PARAM_FN_TPFLOW=$1
    shift
    # the result file
    local PARAM_FN_OUT_TPSTATS=$1
    shift

    # average throughput
    # aggregate throughput
    # TCPstatsXX.out is generated by TCL script, using:
    # $ns at $printtime "dumpFinalTCPStats  1 $flowStartTime $tcp($i)  $tcpsink($i) TCPstats$i.out"
    # the dumpFinalTCPStats is defined in networks.tcl
    # output format: "$label $bytesDel $arrivals $lossno $dropRate $notimeouts $toFreq $meanRTT $thruput 0 0 0"
    #
    rm -f "${PARAM_FN_OUT_TPSTATS}"
    for num in $LIST_NODE_NUM ; do
        for sched in $LIST_SCHEDULERS ; do
            #DN_TEST="${PARAM_PREFIX}_${PARAM_TYPE}_${PARAM_SCHE}_${PARAM_NUM}"
            local DN_TEST=$(simulation_directory "${PARAM_PREFIX}" "${PARAM_TYPE}" "${sched}" "${num}")
            local FN_DAT_STATS="/tmp/tmp-tp-stats-${DN_TEST}-$(uuidgen).data"

            local TP_SUM=0
            local CNT=0
            local RET=0
            local LST=

            RET=$(is_local "${PARAM_DN_BASE}/${DN_TEST}/")
            if [ "$RET" = "e" ]; then
                mr_trace "Warning: skip ${DN_TEST}"
                continue
            fi
            # get the list of the files
            rm -f "${FN_DAT_STATS}"
            LST=$(find_file "${PARAM_DN_BASE}/${DN_TEST}/" -name "${PARAM_FN_STAT}" | sort)
            if [ "${LST}" = "" ]; then
                LST=$(find_file "${PARAM_DN_BASE}/${DN_TEST}/" -name "${PARAM_FN_TPFLOW}" | sort)
                if [ "${LST}" = "" ]; then
                    mr_trace "Error: Not found data file: ${PARAM_FN_TPFLOW}"
                    exit 1
                fi
                FN_AWK_TPAVG=/tmp/tmp-avgtp-stats.awk
                cat << EOF > ${FN_AWK_TPAVG}
# generated by $0
BEGIN{tms=-1; tme=-1; cnt=0; sum=0;}
{
  tm=\$1;
  val=\$2;
  if ((STARTTIME <= tm) && (tm <= STOPTIME)) {
    if (tms < 0) {
      tms = tm;
    }
    tme = tm;
    sum += val;
    cnt ++;
  }
}
END{
  print sum/cnt;
}
EOF
                for i in $LST ; do
                    mr_trace "DEBUG == process flow throughput (stat tcp) $i ..."
                    V=$(cat_file "${i}" | awk -v STARTTIME=${TIME_START} -v STOPTIME=${TIME_STOP} -f ${FN_AWK_TPAVG})
                    echo "${V}" >> "${FN_DAT_STATS}"
                done
            else
                for i in $LST ; do
                    # get the throughput column and save to a temp file
                    # udp: $7 throughput, see tcpudp-util.tcl:dumpFinalUDPStats
                    # tcp: $9 throughput, see tcpudp-util.tcl:dumpFinalTCPStats
                    case ${PARAM_TYPE_FILE} in
                    udp)
                        cat_file "${i}" | awk '{print $7}' >> "${FN_DAT_STATS}"
                        ;;
                    tcp)
                        cat_file "${i}" | awk '{print $9}' >> "${FN_DAT_STATS}"
                        ;;
                    esac
                done
            fi
            local VALS=$(calculate_stats 10000000000 0 < "${FN_DAT_STATS}")
            mr_trace "DEBUG == throughput stats data for ${DN_TEST} (cnt, min, max, sum, mean, stddev, mmr, jfi, cfi)=${VALS}"
            cd "${DN_ORIG8}"
            if [ "${VALS}" = "" ]; then
                mr_trace "Warning: not found throughput stat file for ${DN_TEST}: ${PARAM_FN_STAT}; tpflow=${PARAM_FN_TPFLOW}"
                continue
            fi
            TP_SUM=$(echo ${VALS} | awk '{print $4}' )
            CNT=$(echo ${VALS} | awk '{print $1}')
            TP_AVG=$(echo ${VALS} | awk '{print $5}')
            mr_trace "DEBUG == ${DN_TEST}: sum=${TP_SUM}; avg=${TP_AVG}; cnt=$CNT"
            echo "$num $sched ${VALS}" >> ${PARAM_FN_OUT_TPSTATS}
        done
    done
}


#####################################################################

#plot_eachflow_throughput "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "${HDFF_DN_OUTPUT}/figures/${DN_TEST}" "${DN_TEST}" "title" "DSUDP*.out"

# plot the flows' throughput
plot_eachflow_throughput () {
    # the test dir
    local PARAM_DN_TEST=$1
    shift
    # the dir stores figures
    local PARAM_DN_DEST=$1
    shift
    local PARAM_FN_TEST=$1
    shift
    # the figure title
    local PARAM_TITLE=$1
    shift
    # flow throughput file name template
    local PARAM_FN_TPFLOW=$1
    shift

    local XLABEL="Time (sec)"
    local YLABEL="Throughput (bps)"

    if [ ! -d "${PARAM_DN_TEST}/" ]; then
        mr_trace "Error, not found dir: ${PARAM_DN_TEST}"
        return
    fi
    mr_trace "cd ${PARAM_DN_TEST}"
    local DN_ORIG9=$(pwd)
    cd "${PARAM_DN_TEST}/"

    # GNUPLOT - the arguments for gnuplot plot command
    PLOT_LINE=

    local LST=$(find . -maxdepth 1 -type f -name "${PARAM_FN_TPFLOW}" | awk -F/ '{print $2}' | sort)
    for i in $LST ; do
        mr_trace "process flow throughput $i ..."
        idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
        #mr_trace "DEBUG == idx=$idx"
        if [ ! "${PLOT_LINE}" = "" ]; then PLOT_LINE="${PLOT_LINE},"; fi
        PLOT_LINE="${PLOT_LINE} '${i}' index 0 using 1:2 t 'CM #${idx}' with lp"
    done
    #mr_trace "DEBUG == PLOT_LINE=${PLOT_LINE}"
    FN_TMPGP="tmp-worker_plot_eachflowtp-${PARAM_FN_TEST}.gplot"
    gplot_setheader "${FN_TMPGP}"

    # GNUPLOT - set the labels
    cat << EOF >> "${FN_TMPGP}"
set title "${PARAM_TITLE}"
set xlabel "${XLABEL}"
set ylabel "${YLABEL}"
EOF
    gplot_settail "${FN_TMPGP}" "${PARAM_DN_DEST}/fig-nodetp-${PARAM_FN_TEST}"
    plot_script "${FN_TMPGP}"
    cd "${DN_ORIG9}"
}

#####################################################################

plot_pktdelay_queue () {
    local PARAM_DN_TEST="$1"
    shift
    local PARAM_DN_DEST="$1"
    shift
    local PARAM_DN_NAME="$1"
    shift

    # the packets queue service time distribution
    local FNDAT="/tmp/tmp-pktdelay-queue-${PARAM_DN_NAME}-$(uuidgen).dat.gz"
    local FNGP="/tmp/tmp-pktdelay-queue-${PARAM_DN_NAME}-$(uuidgen).gp"
    if [ ! -f "${FNDAT}" ]; then
        local RET
        RET=$(is_local "${PARAM_DN_TEST}/mediumpacket.out.gz")
        if [ ! "${RET}" = "e" ]; then
            # nodemac.out is always less than mediumpacket.out.gz
            local TMP_FILE="/tmp/nodemac-$(uuidgen).out"
            copy_file "${PARAM_DN_TEST}/nodemac.out" "${TMP_FILE}" > /dev/null 2>&1
            awk 'NR==FNR{map[$1]=$2;next} { if ($6 in map){if (map[$6] == "cmts") { if (($7 > 0) && ($7 in map)) {printf("%.9f\n", $2 - $3); } } } }' \
                "${TMP_FILE}" <(cat_file "${PARAM_DN_TEST}/mediumpacket.out.gz" | gzip -dc) | gzip > "${FNDAT}"
            rm -f "${TMP_FILE}"
        else
            RET=$(is_local "${PARAM_DN_TEST}/mediumpacket.out")
            if [ ! "${RET}" = "e" ]; then
                local TMP_FILE="/tmp/nodemac-$(uuidgen).out"
                copy_file "${PARAM_DN_TEST}/nodemac.out" "${TMP_FILE}" > /dev/null 2>&1
                awk 'NR==FNR{map[$1]=$2;next} { if ($6 in map){if (map[$6] == "cmts") { if (($7 > 0) && ($7 in map)) {printf("%.9f\n", $2 - $3); } } } }' \
                    "${TMP_FILE}" <(cat_file "${PARAM_DN_TEST}/mediumpacket.out") | gzip > "${FNDAT}"
                rm -f "${TMP_FILE}"
            fi
        fi
    fi
    if [ -f "${FNDAT}" ]; then
        plotgen_pdf "Downstream MAC Packets" "Queue Service Time (sec)" "Denseness" "${FNDAT}" "${PARAM_DN_DEST}/fig-pktqueue-${PARAM_DN_NAME}" "${FNGP}"
        plot_script "${FNGP}"
        #rm -f "${FNDAT}"
    else
        mr_trace "Error: unable to find the generated data: ${FNDAT}"
    fi
}

plot_pktdelay_trans () {
    local PARAM_DN_TEST="$1"
    shift
    local PARAM_DN_DEST="$1"
    shift
    local PARAM_DN_NAME="$1"
    shift

    # the packets translation time distribution
    local FNDAT="/tmp/tmp-pktdelay-trans-${PARAM_DN_NAME}-$(uuidgen).dat.gz"
    local FNGP="/tmp/tmp-pktdelay-trans-${PARAM_DN_NAME}-$(uuidgen).gp"
    if [ ! -f "${FNDAT}" ]; then
        local RET
        RET=$(is_local "${PARAM_DN_TEST}/mediumpacket.out.gz")
        if [ ! "${RET}" = "e" ]; then
            # nodemac.out is always less than mediumpacket.out.gz
            local TMP_FILE="/tmp/nodemac-$(uuidgen).out"
            copy_file "${PARAM_DN_TEST}/nodemac.out" "${TMP_FILE}" > /dev/null 2>&1
            awk 'NR==FNR{map[$1]=$2;next} { if ($6 in map){if (map[$6] == "cmts") { if (($7 > 0) && ($7 in map)) {printf("%.9f\n", $1 - $2); } } } }' \
                "${TMP_FILE}" <(cat_file "${PARAM_DN_TEST}/mediumpacket.out.gz" | gzip -dc) | gzip > "${FNDAT}"
            rm -f "${TMP_FILE}" > /dev/null 2>&1
        else
            RET=$(is_local "${PARAM_DN_TEST}/mediumpacket.out")
            if [ ! "${RET}" = "e" ]; then
                local TMP_FILE="/tmp/nodemac-$(uuidgen).out"
                copy_file "${PARAM_DN_TEST}/nodemac.out" "${TMP_FILE}" > /dev/null 2>&1
                awk 'NR==FNR{map[$1]=$2;next} { if ($6 in map){if (map[$6] == "cmts") { if (($7 > 0) && ($7 in map)) {printf("%.9f\n", $1 - $2); } } } }' \
                    "${TMP_FILE}" <(cat_file "${PARAM_DN_TEST}/mediumpacket.out") | gzip > "${FNDAT}"
                rm -f "${TMP_FILE}" > /dev/null 2>&1
            fi
        fi
    fi

    if [ -f "${FNDAT}" ]; then
        plotgen_pdf "Downstream MAC Packets" "Transfer Time (sec)" "Denseness" "${FNDAT}" "${PARAM_DN_DEST}/fig-pkttrans-${PARAM_DN_NAME}" "${FNGP}"
        plot_script "${FNGP}"
        #rm -f "${FNDAT}"
    else
        mr_trace "Error: unable to find the generated data: ${FNDAT}"
    fi
}

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
# the variable HDFF_DN_OUTPUT, HDFF_DN_SCRATCH should be set
plot_ns2_type () {
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

    #mr_trace "received: cmd='${ARG_CMD1}', prefix='${ARG_PREFIX1}', type='${ARG_TYPE1}', flow='${ARG_FLOW_TYPE1}', sche='${ARG_SCHE1}', num='${ARG_NUM1}'"

    ARG_CMD=$( unquote_filename "${ARG_CMD1}" )
    ARG_PREFIX=$( unquote_filename "${ARG_PREFIX1}" )
    ARG_TYPE=$( unquote_filename "${ARG_TYPE1}" )
    ARG_FLOW_TYPE=$( unquote_filename "${ARG_FLOW_TYPE1}" )
    ARG_SCHE=$( unquote_filename "${ARG_SCHE1}" )
    ARG_NUM=$( unquote_filename "${ARG_NUM1}" )

    mr_trace "after processed: cmd='${ARG_CMD}', prefix='${ARG_PREFIX}', type='${ARG_TYPE}', flow='${ARG_FLOW_TYPE}', sche='${ARG_SCHE}', num='${ARG_NUM}'"

    DN_TEST=$(simulation_directory "${ARG_PREFIX}" "${ARG_TYPE}" "${ARG_SCHE}" "${ARG_NUM}")

    make_dir "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}" > /dev/null 2>&1

    #mr_trace "ARG_CMD=${ARG_CMD}"

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
            make_dir "${TMP_SRC}/" > /dev/null 2>&1
            #copy_file "${DN_SRC}/"CMTCPDS*.out "${TMP_SRC}/" > /dev/null 2>&1
            find_file "${DN_SRC}/" -name "CMTCPDS*.out" | while read a; do copy_file "$a" "${TMP_SRC}/" > /dev/null 2>&1; done
            find_file "${DN_SRC}/" -name "CMUDPDS*.out" | while read a; do copy_file "$a" "${TMP_SRC}/" > /dev/null 2>&1; done
            DN_SRC="${TMP_SRC}/"
        fi
        local FLG_USETMP=0
        RET=$(is_local "${DN_DEST}")
        if [ ! "${RET}" = "l" ]; then
            FLG_USETMP=1
        fi
        if [ ! "${HDFF_DN_SCRATCH}" = "" ]; then
            FLG_USETMP=1
        fi
        if [ ! "${FLG_USETMP}" = "0" ]; then
            TMP_DEST="${HDFF_DN_SCRATCH}/file-$(uuidgen)/"
            make_dir "${TMP_DEST}/" > /dev/null 2>&1
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
        cd "${DN_DEST}" > /dev/null 2>&1
        convert_eps2png
        cd "${DN_ORIG5}"
        if [ ! "${TMP_DEST}" = "" ]; then
            mr_trace "copy file back to ${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX} from ${TMP_DEST}"
            copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}" > /dev/null 2>&1
            rm_f_dir "${TMP_DEST}" > /dev/null 2>&1
        fi
        if [ ! "${TMP_SRC}" = "" ]; then
            rm_f_dir "${TMP_SRC}" > /dev/null 2>&1
        fi
        ;;

    "tpstat")
        local FN_CONFIG_PROJ=$ARG_FLOW_TYPE
        local FN_TMP="/tmp/config-$(uuidgen)"
        copy_file "${FN_CONFIG_PROJ}" "${FN_TMP}" > /dev/null 2>&1
        read_config_file "${FN_TMP}"
        rm_f_dir "${FN_TMP}" > /dev/null 2>&1

        local TMP_DEST=""
        local DN_SRC="${HDFF_DN_OUTPUT}/dataconf/"
        local DN_DEST="${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"
        local RET=$(is_local "${DN_DEST}")
        if [ ! "${RET}" = "l" ]; then
            TMP_DEST="${HDFF_DN_SCRATCH}/file-$(uuidgen)/"
            make_dir "${TMP_DEST}/" > /dev/null 2>&1
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
            copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}" > /dev/null 2>&1
            rm_f_dir "${TMP_DEST}" > /dev/null 2>&1
        fi
        ;;

    "pktstat")
        DN_ORIG6=$(pwd)
        local TMP_DEST=""
        local DN_DEST="${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"
        local RET=$(is_local "${DN_DEST}")
        if [ ! "${RET}" = "l" ]; then
            TMP_DEST="${HDFF_DN_SCRATCH}/file-$(uuidgen)/"
            make_dir "${TMP_DEST}/" > /dev/null 2>&1
            DN_DEST="${TMP_DEST}/"
        fi
        plot_pktdelay_queue "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "${DN_DEST}" "${DN_TEST}"
        cd "${DN_DEST}"
        convert_eps2png
        cd "${DN_ORIG6}"
        if [ ! "${TMP_DEST}" = "" ]; then
            copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}" > /dev/null 2>&1
            rm_f_dir "${TMP_DEST}" > /dev/null 2>&1
        fi
        ;;

    "pkttrans")
        DN_ORIG6=$(pwd)
        local TMP_DEST=""
        local DN_DEST="${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"
        local RET=$(is_local "${DN_DEST}")
        if [ ! "${RET}" = "l" ]; then
            TMP_DEST="${HDFF_DN_SCRATCH}/file-$(uuidgen)/"
            make_dir "${TMP_DEST}/" > /dev/null 2>&1
            DN_DEST="${TMP_DEST}/"
        fi
        plot_pktdelay_trans "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "${DN_DEST}" "${DN_TEST}"
        cd "${DN_DEST}"
        convert_eps2png
        cd "${DN_ORIG6}"
        if [ ! "${TMP_DEST}" = "" ]; then
            copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}" > /dev/null 2>&1
            rm_f_dir "${TMP_DEST}" > /dev/null 2>&1
        fi
        ;;
    *)
        mr_trace "Error: unknown command: ${ARG_CMD}"
        ;;
    esac
}
