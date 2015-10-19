#!/bin/bash
# bash library
# plot
#
# Copyright 2013 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################

# return the simulation directory name
simulation_directory () {
    # the prefix of the test
    PARAM_PREFIX=$1
    shift
    # the test type, "udp", "tcp", "has", "udp+has", "tcp+has"
    PARAM_TYPE=$1
    shift
    # the scheduler, such as "PF", "DRR"
    PARAM_SCHE=$1
    shift
    # the number of flows
    PARAM_NUM=$1
    shift
    DN_TEST="${PARAM_PREFIX}_${PARAM_TYPE}_${PARAM_SCHE}_${PARAM_NUM}"
    echo "${DN_TEST}"
}

generate_throughput_stats_file () {
    # the prefix of the test
    PARAM_PREFIX=$1
    shift
    # the test type, "udp", "tcp", "has", "udp+has", "tcp+has"
    PARAM_TYPE=$1
    shift
    # the file type, "udp" or "tcp"
    PARAM_TYPE_FILE=$1
    shift
    # stats file name template
    PARAM_FN_STAT=$1
    shift
    # flow throughput file name template
    PARAM_FN_TPFLOW=$1
    shift
    # the result file
    PARAM_FN_OUT_TPSTATS=$1
    shift

    # average throughput
    # aggregate throughput
    # TCPstatsXX.out is generated by TCL script, using:
    # $ns at $printtime "dumpFinalTCPStats  1 $flowStartTime $tcp($i)  $tcpsink($i) TCPstats$i.out"
    # the dumpFinalTCPStats is defined in networks.tcl
    # output format: "$label $bytesDel $arrivals $lossno $dropRate $notimeouts $toFreq $meanRTT $thruput 0 0 0"
    #
    #FN_TMP=tmp-$(uuidgen).txt
    rm -f "${PARAM_FN_OUT_TPSTATS}"
    for num in ${list_nodes_num[*]} ; do
        for sched in ${list_schedules[*]} ; do
            #DN_TEST="${PARAM_PREFIX}_${PARAM_TYPE}_${PARAM_SCHE}_${PARAM_NUM}"
            DN_TEST=$(simulation_directory "${PARAM_PREFIX}" "${PARAM_TYPE}" "${sched}" "${num}")

            TP_SUM=0
            CNT=0
            if [ ! -d "${DN_TEST}/" ]; then
                echo "Warning: skip ${DN_TEST}" 1>&2
                continue
            fi
            cd "${DN_TEST}/"
            # get the list of the files
            FN_DAT_STATS="tmp-tp-stats-${DN_TEST}.data"
            rm -f "${FN_DAT_STATS}"
            LST=$(find . -maxdepth 1 -type f -name "${PARAM_FN_STAT}" | awk -F/ '{print $2}' | sort)
            if [ "${LST}" = "" ]; then
                LST=$(find . -maxdepth 1 -type f -name "${PARAM_FN_TPFLOW}" | awk -F/ '{print $2}' | sort)
                if [ "${LST}" = "" ]; then
                    echo "Error: Not found data file: ${PARAM_FN_TPFLOW}" 1>&2
                    exit 1
                fi
                FN_AWK_TPAVG=tmp-avgtp-stats.awk
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
                    echo "DEBUG == process flow throughput (stat tcp) $i ..." 1>&2
                    V=$(cat "${i}" | awk -v STARTTIME=${TIME_START} -v STOPTIME=${TIME_STOP} -f ${FN_AWK_TPAVG})
                    echo "${V}" >> "${FN_DAT_STATS}"
                done
            else
                for i in $LST ; do
                    # get the throughput column and save to a temp file
                    # udp: $7 throughput, see tcpudp-util.tcl:dumpFinalUDPStats
                    # tcp: $9 throughput, see tcpudp-util.tcl:dumpFinalTCPStats
                    case ${PARAM_TYPE_FILE} in
                    udp)
                        cat "${i}" | awk '{print $7}' >> "${FN_DAT_STATS}"
                        ;;
                    tcp)
                        cat "${i}" | awk '{print $9}' >> "${FN_DAT_STATS}"
                        ;;
                    esac
                done
            fi
            VALS=$(calculate_stats 10000000000 0 < "${FN_DAT_STATS}")
            echo "DEBUG == throughput stats data for ${DN_TEST} (cnt, min, max, sum, mean, stddev, mmr, jfi, cfi)=${VALS}" 1>&2
            cd - > /dev/null
            if [ "${VALS}" = "" ]; then
                echo "Warning: not found throughput stat file for ${DN_TEST}: ${PARAM_FN_STAT}; tpflow=${PARAM_FN_TPFLOW}" 1>&2
                continue
            fi
            TP_SUM=$(echo ${VALS} | awk '{print $4}' )
            CNT=$(echo ${VALS} | awk '{print $1}')
            TP_AVG=$(echo ${VALS} | awk '{print $5}')
            echo "DEBUG == ${DN_TEST}: sum=${TP_SUM}; avg=${TP_AVG}; cnt=$CNT" 1>&2
            echo "$num $sched ${VALS}" >> ${PARAM_FN_OUT_TPSTATS}
        done
    done
}


#####################################################################

#plot_eachflow_throughput "${DN_TOP}/results/${DN_TEST}" "${DN_TOP}/figures/${DN_TEST}" "${DN_TEST}" "title" "DSUDP*.out"

# plot the flows' throughput
plot_eachflow_throughput () {
    # the test dir
    PARAM_DN_TEST=$1
    shift
    # the dir stores figures
    PARAM_DN_DEST=$1
    shift
    PARAM_FN_TEST=$1
    shift
    # the figure title
    PARAM_TITLE=$1
    shift
    # flow throughput file name template
    PARAM_FN_TPFLOW=$1
    shift

    XLABEL="Time (sec)"
    YLABEL="Throughput (bps)"

    if [ ! -d "${PARAM_DN_TEST}/" ]; then
        echo "Error, not found dir: ${PARAM_DN_TEST}" 1>&2
        return
    fi
echo "[DBG] cd ${PARAM_DN_TEST}" 1>&2
    cd "${PARAM_DN_TEST}/"

    # GNUPLOT - the arguments for gnuplot plot command
    PLOT_LINE=

    LST=$(find . -maxdepth 1 -type f -name "${PARAM_FN_TPFLOW}" | awk -F/ '{print $2}' | sort)
    for i in $LST ; do
        echo "process flow throughput $i ..." 1>&2
        idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
        echo "DEBUG == idx=$idx" 1>&2
        if [ ! "${PLOT_LINE}" = "" ]; then PLOT_LINE="${PLOT_LINE},"; fi
        PLOT_LINE="${PLOT_LINE} '${i}' index 0 using 1:2 t 'CM #${idx}' with lp"
    done
    echo "DEBUG == PLOT_LINE=${PLOT_LINE}" 1>&2
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
    cd - > /dev/null
}

#####################################################################

plot_pktdelay_queue () {
    PARAM_DN_TEST="$1"
    shift
    PARAM_DN_DEST="$1"
    shift
    PARAM_DN_NAME="$1"
    shift

    cd "${PARAM_DN_TEST}"
    # the packets queue service time distribution
    FNDAT="tmp-pktdelay-queue-${PARAM_DN_NAME}.dat.gz"
    FNGP="tmp-pktdelay-queue-${PARAM_DN_NAME}.gp"
    if [ ! -f "${FNDAT}" ]; then
        if [ -f "mediumpacket.out.gz" ]; then
            awk 'NR==FNR{map[$1]=$2;next} { if ($6 in map){if (map[$6] == "cmts") { if (($7 > 0) && ($7 in map)) {printf("%.9f\n", $2 - $3); } } } }' nodemac.out <(gzip -dc mediumpacket.out.gz) | gzip > "${FNDAT}"
        else
            awk 'NR==FNR{map[$1]=$2;next} { if ($6 in map){if (map[$6] == "cmts") { if (($7 > 0) && ($7 in map)) {printf("%.9f\n", $2 - $3); } } } }' nodemac.out mediumpacket.out | gzip > "${FNDAT}"
        fi
    fi
    plotgen_pdf "Downstream MAC Packets" "Queue Service Time (sec)" "Denseness" "${FNDAT}" "${PARAM_DN_DEST}/fig-pktqueue-${PARAM_DN_NAME}" "${FNGP}"
    plot_script "${FNGP}"
    #rm -f "${FNDAT}"
    cd - > /dev/null
}

plot_pktdelay_trans () {
    PARAM_DN_TEST="$1"
    shift
    PARAM_DN_DEST="$1"
    shift
    PARAM_DN_NAME="$1"
    shift

    cd "${PARAM_DN_TEST}"
    # the packets translation time distribution
    FNDAT="tmp-pktdelay-trans-${PARAM_DN_NAME}.dat.gz"
    FNGP="tmp-pktdelay-trans-${PARAM_DN_NAME}.gp"
    if [ ! -f "${FNDAT}" ]; then
        if [ -f "mediumpacket.out.gz" ]; then
            awk 'NR==FNR{map[$1]=$2;next} { if ($6 in map){if (map[$6] == "cmts") { if (($7 > 0) && ($7 in map)) {printf("%.9f\n", $1 - $2); } } } }' nodemac.out <(gzip -dc mediumpacket.out.gz) | gzip > "${FNDAT}"
        else
            awk 'NR==FNR{map[$1]=$2;next} { if ($6 in map){if (map[$6] == "cmts") { if (($7 > 0) && ($7 in map)) {printf("%.9f\n", $1 - $2); } } } }' nodemac.out mediumpacket.out | gzip > "${FNDAT}"
        fi
    fi

    plotgen_pdf "Downstream MAC Packets" "Transfer Time (sec)" "Denseness" "${FNDAT}" "${PARAM_DN_DEST}/fig-pkttrans-${PARAM_DN_NAME}" "${FNGP}"
    plot_script "${FNGP}"
    #rm -f "${FNDAT}"
    cd - > /dev/null
}
