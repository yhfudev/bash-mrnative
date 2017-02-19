#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief plot functions for NS2
##
## @author Yunhui Fu <yhfudev@gmail.com>
## @copyright GPL v3.0 or later
## @version 1
##

#####################################################################

## @fn simulation_directory()
## @brief simulation directory names
##
## return the simulation directory name
simulation_directory() {
    echo "${1}_${2}_${3}_${4}"
}

## @fn get_num_range_for_profiles()
## @brief calculate the range of one profile group
## @param max the total number of items
## @param lst_blocks block ratio, such as '0.5 0.5', the sum should be 1.0
## @param selet_block select block, which range should be involved; 0 -- all, 1 -- the first block, 2 -- the second block ...
## 
## for example:
##   BLOCKS 0.5 0.5
##   MAX=8
##   SEL=1
## output: 1,4
##   SEL=2
## output: 5,8
get_num_range_for_profiles() {
    # the total # of items
    local PARAM_MAX=$1
    shift
    # block ratio, such as '0.5 0.5', the sum should be 1.0
    local PARAM_LST_BLOCKS=$1
    shift
    # select block, which range should be involved; 0 -- all, 1 -- the first block, 2 -- the second block ...
    local PARAM_SELECT_BLOCK=$1
    shift

    local lst1=(${PARAM_LST_BLOCKS})
    local NUM=${#lst1[*]}
    local RATIO=0.0
    local NEXTNUM=0
    local MAXFLOWS=$PARAM_MAX
    local CURRNUM=1
    local CNT1=0
    while [ $CNT1 -lt $NUM ] ; do
        #mr_trace "DEBUG: PARAM_LST_BLOCKS=$PARAM_LST_BLOCKS, PARAM_SELECT_BLOCK=$PARAM_SELECT_BLOCK"
        #mr_trace "DEBUG: ratio($RATIO) + cur(${lst1[$CNT1]}) = "
        RATIO=$(echo | awk -v V=$RATIO -v I=${lst1[$CNT1]} '{print V + I;}')
        #mr_trace "DEBUG: ratio($RATIO)"
        NEXTNUM=$(echo | awk -v M=$PARAM_MAX -v V=$RATIO '{print int(V * M)}')
        #mr_trace "DEBUG: NEXTNUM($NEXTNUM)"
        CNT1=$(($CNT1 + 1))
        if [ "${CNT1}" = "${PARAM_SELECT_BLOCK}" ]; then
            echo "${CURRNUM},${NEXTNUM}"
            break;
        fi
        CURRNUM=$(($NEXTNUM + 1))
    done
}

## @fn generate_throughput_stats_single_folder()
## @brief generate the stat line for a subdir
## @param dn_base the dir contains all of the trace data in LIST_NODE_NUM,LIST_SCHEDULERS
## @param prefix the prefix of the test
## @param type the test type, "udp", "tcp", "has", "udp+has", "tcp+has"
## @param sched the scheduler, "PF", "DRR", etc.
## @param flows the number of flows
## @param type_file the file type, "udp" or "tcp"
## @param fn_stat stats file name template
## @param fn_tpflow flow throughput file name template
## @param fn_out_tpstats the result file
## @param lst_blocks (Profiles) block ratio, such as '0.5 0.5', the sum should be 1.0
## @param select_block (Profiles) select block, which range should be involved; 0 -- all, 1 -- the first block, 2 -- the second block ...
##
## TIME_START, TIME_STOP should be set,
## the format of output file PARAM_FN_OUT_TPSTATS:
## num, scheduler, cnt, min, max, sum, mean, stddev, mmr, jfi, cfi
generate_throughput_stats_single_folder() {
    # the dir contains all of the trace data in LIST_NODE_NUM,LIST_SCHEDULERS
    local PARAM_DN_BASE=$1
    shift
    # the prefix of the test
    local PARAM_PREFIX=$1
    shift
    # the test type, "udp", "tcp", "has", "udp+has", "tcp+has"
    local PARAM_TYPE=$1
    shift
    # the scheduler, "PF", "DRR", etc.
    local PARAM_SCHED=$1
    shift
    # the # of flows
    local PARAM_FLOWS=$1
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
    # the followings are for Profiles,
    # block ratio, such as '0.5 0.5', the sum should be 1.0
    local PARAM_LST_BLOCKS=$1
    shift
    # select block, which range should be involved; 0 -- all, 1 -- the first block, 2 -- the second block ...
    local PARAM_SELECT_BLOCK=$1
    shift

    #DN_TEST="${PARAM_PREFIX}_${PARAM_TYPE}_${PARAM_SCHE}_${PARAM_NUM}"
    local DN_TEST=$(simulation_directory "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHED}" "${PARAM_FLOWS}")
    local FN_DAT_STATS="/tmp/tmp-tp-stats-${DN_TEST}-$(uuidgen).data"

    local TP_SUM=0
    local CNT=0
    local RET=0
    local LST=

    RET=$(is_local "${PARAM_DN_BASE}/${DN_TEST}/")
    if [ ! "$RET" = "l" ]; then
        mr_trace "Warning: skip remote dir ${DN_TEST}"
        continue
    fi
    if [ ! -d "${PARAM_DN_BASE}/${DN_TEST}/" ]; then
        mr_trace "Warning: not exist dir ${DN_TEST}"
        continue
    fi
    # get the list of the files
    rm_f_dir "${FN_DAT_STATS}"
    LST=$(find_file "${PARAM_DN_BASE}/${DN_TEST}/" -name "${PARAM_FN_STAT}" | sort)
    if [ "${LST}" = "" ]; then
        local FN_TMP_LST=/tmp/tmp-lst-tp-$(uuidgen).dat
        #LST=$(find_file "${PARAM_DN_BASE}/${DN_TEST}/" -name "${PARAM_FN_TPFLOW}" | sort)
        find_file "${PARAM_DN_BASE}/${DN_TEST}/" -name "${PARAM_FN_TPFLOW}" | sort > ${FN_TMP_LST}
        LST=$(cat ${FN_TMP_LST})
        if [ "${LST}" = "" ]; then
            mr_trace "Error: Not found data file: ${PARAM_FN_TPFLOW}"
            exit 1
        fi

        # filter out the flows acording the block config (multiple profiles)
        if [ ! "${PARAM_SELECT_BLOCK}" = "" ]; then
            if [ ! "${PARAM_SELECT_BLOCK}" = "0" ]; then
                mr_trace "process, BLOCK select ${PARAM_SELECT_BLOCK}"
                #exit 1
                local A=$(get_num_range_for_profiles $PARAM_FLOWS "${PARAM_LST_BLOCKS}" ${PARAM_SELECT_BLOCK})
                if [ ! "$A" = "" ]; then
                    mr_trace "sed -n '${A}p' FROM ${FN_TMP_LST}"
                    LST=$(sed -n "${A}p" < ${FN_TMP_LST})
                fi

            else
                mr_trace "BLOCK select 0"
                #exit 1
            fi
        else
            mr_trace "BLOCK config null = ${PARAM_SELECT_BLOCK}"
            #exit 1
        fi
        rm_f_dir "${FN_TMP_LST}"

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
            mr_trace "DEBUG == process flow throughput (stat tcp) cat_file "${i}" TO awk -v STARTTIME=${TIME_START} -v STOPTIME=${TIME_STOP} -f ${FN_AWK_TPAVG} ..."
            V=$(cat_file "${i}" | awk -v STARTTIME=${TIME_START} -v STOPTIME=${TIME_STOP} -f ${FN_AWK_TPAVG})
            echo "${V}" >> "${FN_DAT_STATS}"
        done
    else
        if [ ! "${PARAM_SELECT_BLOCK}" = "" ]; then
            if [ ! "${PARAM_SELECT_BLOCK}" = "0" ]; then
                mr_trace "Error: the stats files contain all of flows, not for single group. Please use flow files to generate it."
                exit 1
            fi
        fi
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
    #TP_SUM=$(echo ${VALS} | awk '{print $4}' )
    #CNT=$(echo ${VALS} | awk '{print $1}')
    #TP_AVG=$(echo ${VALS} | awk '{print $5}')
    #TP_STD=$(echo ${VALS} | awk '{print $6}')
    #TP_JFI=$(echo ${VALS} | awk '{print $8}')
    # num, sched, profile, mean, std, jfi
    #mr_trace "$PARAM_FLOWS & $PARAM_SCHED & ${PARAM_SELECT_BLOCK} & $TP_AVG & $TP_STD & $TP_JFI "
    # num, scheduler, cnt, min, max, sum, mean, stddev, mmr, jfi, cfi
    echo "$PARAM_FLOWS $PARAM_SCHED ${VALS}" >> ${PARAM_FN_OUT_TPSTATS}
}

## @fn generate_throughput_stats_file()
## @brief generate throughput stat files
## @param dn_base the dir contains all of the trace data in LIST_NODE_NUM,LIST_SCHEDULERS
## @param prefix the prefix of the test
## @param type the test type, "udp", "tcp", "has", "udp+has", "tcp+has"
## @param type_file the file type, "udp" or "tcp"
## @param fn_stat stats file name template
## @param fn_tpflow flow throughput file name template
## @param fn_out_tpstats the result file
## @param lst_blocks (Profiles) block ratio, such as '0.5 0.5', the sum should be 1.0
## @param select_block (Profiles) select block, which range should be involved; 0 -- all, 1 -- the first block, 2 -- the second block ...
##
## please include "libfs.sh" before call this function
## get the environment variable LIST_NODE_NUM,LIST_SCHEDULERS from your config file
generate_throughput_stats_file() {
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
    # the followings are for Profiles,
    # block ratio, such as '0.5 0.5', the sum should be 1.0
    local PARAM_LST_BLOCKS=$1
    shift
    # select block, which range should be involved; 0 -- all, 1 -- the first block, 2 -- the second block ...
    local PARAM_SELECT_BLOCK=$1
    shift

    rm_f_dir "${PARAM_FN_OUT_TPSTATS}"
    echo "" >> ${PARAM_FN_OUT_TPSTATS}
    echo "# num, scheduler, cnt, min, max, sum, mean, stddev, mmr, jfi, cfi" >> ${PARAM_FN_OUT_TPSTATS}
    # average throughput
    # aggregate throughput
    # TCPstatsXX.out is generated by TCL script, using:
    # $ns at $printtime "dumpFinalTCPStats  1 $flowStartTime $tcp($i)  $tcpsink($i) TCPstats$i.out"
    # the dumpFinalTCPStats is defined in networks.tcl
    # output format: "$label $bytesDel $arrivals $lossno $dropRate $notimeouts $toFreq $meanRTT $thruput 0 0 0"
    #
    for num in $LIST_NODE_NUM ; do
        for sched0 in $LIST_SCHEDULERS ; do

            # hack the special PF alpha argument
            local FLG_USE_PF=0
            if [ "${sched0}" = "PF" ]; then
                if [ ! "${PF_ALPHAS}" = "" ]; then
                    FLG_USE_PF=1
                fi
            fi
            local LST_SCHE=
            if [ "${FLG_USE_PF}" = "1" ]; then
                CNT=0
                for VAL in $PF_ALPHAS ; do
                    CNT=$(( $CNT + 1 ))
                    LST_SCHE="${LST_SCHE} ${sched0}${CNT}"
                done
            else
                LST_SCHE="${sched0}"
            fi

            for sched in $LST_SCHE ; do
                generate_throughput_stats_single_folder "${PARAM_DN_BASE}" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${sched}" "${num}" "${PARAM_TYPE_FILE}" "${PARAM_FN_STAT}" "${PARAM_FN_TPFLOW}" "${PARAM_FN_OUT_TPSTATS}" "${PARAM_LST_BLOCKS}" "${PARAM_SELECT_BLOCK}"
            done
        done
    done
}


#####################################################################

## @fn plot_eachflow_throughput()
## @brief plot the flows' throughput
## @param dn_test the test dir, should be a local dir
## @param dn_dest the dir stores figures, should be a local dir
## @param fn_test some part of figure file name
## @param title the figure title
## @param fn_tpflow flow throughput file name template
##
## example:
## plot_eachflow_throughput "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "${HDFF_DN_OUTPUT}/figures/${DN_TEST}" "${DN_TEST}" "title" "DSUDP*.out"
plot_eachflow_throughput() {
    # the test dir, should be a local dir
    local PARAM_DN_TEST=$1
    shift
    # the dir stores figures, should be a local dir
    local PARAM_DN_DEST=$1
    shift
    # some part of figure file name
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

    if [ ! -d "${PARAM_DN_TEST#file://}" ]; then
        mr_trace "Error, not found dir: ${PARAM_DN_TEST}"
        return
    fi
    mr_trace "cd ${PARAM_DN_TEST}"
    local DN_ORIG9=$(pwd)
    cd "${PARAM_DN_TEST#file://}/"

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
    gplot_settail "${FN_TMPGP}" "${PARAM_DN_DEST#file://}/fig-nodetp-${PARAM_FN_TEST}"
    plot_script "${FN_TMPGP}"
    cd "${DN_ORIG9}"
}

#####################################################################

## @fn plot_pktdelay_queue()
## @brief plot figures for the packet delay time in the queue
## @param dn_test the dir of test data
## @param dn_dest the dir for the plotted figures
## @param dn_name the data file prefix
##
plot_pktdelay_queue() {
    local PARAM_DN_TEST="$1"
    shift
    local PARAM_DN_DEST="$1"
    shift
    local PARAM_DN_NAME="$1"
    shift

    # the followings are for Profiles,
    # the max flows
    local PARAM_FLOWS=$1
    shift
    # block ratio, such as '0.5 0.5', the sum should be 1.0
    local PARAM_LST_BLOCKS=$1
    shift
    # select block, which range should be involved; 0 -- all, 1 -- the first block, 2 -- the second block ...
    local PARAM_SELECT_BLOCK=$1
    shift

    # the packets queue service time distribution
    local FNDAT="/tmp/tmp-pktdelay-queue-${PARAM_DN_NAME}-$(uuidgen).dat.gz"
    local FNGP="/tmp/tmp-pktdelay-queue-${PARAM_DN_NAME}-$(uuidgen).gp"

    if [ ! -f "${FNDAT}" ]; then
        local TMP_FILE="/tmp/nodemac-$(uuidgen).out"
        copy_file "${PARAM_DN_TEST}/nodemac.out" "${TMP_FILE}" > /dev/null 2>&1

        # filter out the flows acording the block config (multiple profiles)
        if [ ! "${PARAM_SELECT_BLOCK}" = "" ]; then
            if [ ! "${PARAM_SELECT_BLOCK}" = "0" ]; then
                grep    cmts "${PARAM_DN_TEST}/nodemac.out" > "${TMP_FILE}"
                local A=$(get_num_range_for_profiles $PARAM_FLOWS "${PARAM_LST_BLOCKS}" ${PARAM_SELECT_BLOCK})
                if [ ! "$A" = "" ]; then
                    mr_trace "sed -n '${A}p' FROM ${TMP_FILE2}"
                    local TMP_FILE2="/tmp/nodemac-$(uuidgen).out"
                    grep -v cmts "${PARAM_DN_TEST}/nodemac.out" > "${TMP_FILE2}"
                    sed -n "${A}p" < ${TMP_FILE2} >> "${TMP_FILE}"
                fi
            fi
        fi

        local RET
        RET=$(is_local "${PARAM_DN_TEST}/mediumpacket.out.gz")
        if [ ! "${RET}" = "e" ]; then
            # nodemac.out is always less than mediumpacket.out.gz
            awk 'NR==FNR{map[$1]=$2;next} { if ($6 in map){if (map[$6] == "cmts") { if (($7 > 0) && ($7 in map)) {printf("%.9f\n", $2 - $3); } } } }' \
                "${TMP_FILE}" <(cat_file "${PARAM_DN_TEST}/mediumpacket.out.gz" | gzip -dc) | gzip > "${FNDAT}"
            rm_f_dir "${TMP_FILE}"
        else
            RET=$(is_local "${PARAM_DN_TEST}/mediumpacket.out")
            if [ ! "${RET}" = "e" ]; then
                awk 'NR==FNR{map[$1]=$2;next} { if ($6 in map){if (map[$6] == "cmts") { if (($7 > 0) && ($7 in map)) {printf("%.9f\n", $2 - $3); } } } }' \
                    "${TMP_FILE}" <(cat_file "${PARAM_DN_TEST}/mediumpacket.out") | gzip > "${FNDAT}"
                rm_f_dir "${TMP_FILE}"
            fi
        fi
    fi
    # calculate average time
    zcat "${FNDAT}" | awk '{sum += $1; n ++; } END {if (n> 0) print sum/n; }' | save_file ${PARAM_DN_TEST}/pktdelay-queue-${PARAM_SELECT_BLOCK}.dat
    if [ -f "${FNDAT}" ]; then
        plotgen_pdf "Downstream MAC Packets" "Queue Service Time (sec)" "Denseness" "${FNDAT}" "${PARAM_DN_DEST}/fig-pktqueue-${PARAM_DN_NAME}-${PARAM_SELECT_BLOCK}" "${FNGP}"
        plot_script "${FNGP}"
        #rm_f_dir "${FNDAT}"
    else
        mr_trace "Error: unable to find the generated data: ${FNDAT}"
    fi
}

## @fn plot_pktdelay_trans()
## @brief plot figures for the packet translation time
## @param dn_test the dir of test data
## @param dn_dest the dir for the plotted figures
## @param dn_name the data file prefix
##
plot_pktdelay_trans() {
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
            rm_f_dir "${TMP_FILE}" > /dev/null
        else
            RET=$(is_local "${PARAM_DN_TEST}/mediumpacket.out")
            if [ ! "${RET}" = "e" ]; then
                local TMP_FILE="/tmp/nodemac-$(uuidgen).out"
                copy_file "${PARAM_DN_TEST}/nodemac.out" "${TMP_FILE}" > /dev/null 2>&1
                awk 'NR==FNR{map[$1]=$2;next} { if ($6 in map){if (map[$6] == "cmts") { if (($7 > 0) && ($7 in map)) {printf("%.9f\n", $1 - $2); } } } }' \
                    "${TMP_FILE}" <(cat_file "${PARAM_DN_TEST}/mediumpacket.out") | gzip > "${FNDAT}"
                rm_f_dir "${TMP_FILE}" > /dev/null
            fi
        fi
    fi

    if [ -f "${FNDAT}" ]; then
        plotgen_pdf "Downstream MAC Packets" "Transfer Time (sec)" "Denseness" "${FNDAT}" "${PARAM_DN_DEST}/fig-pkttrans-${PARAM_DN_NAME}" "${FNGP}"
        plot_script "${FNGP}"
        #rm_f_dir "${FNDAT}"
    else
        mr_trace "Error: unable to find the generated data: ${FNDAT}"
    fi
}

#####################################################################
convert_eps2png () {
    ls *.eps | gawk -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}' | while read a; do if [ ! -f "$a.jpg" ]; then convert -density 300 $a.eps $a.jpg; fi ; done
}

#####################################################################

## @fn plot_ns2_type()
## @brief plot figures
## @param cmd the command of the plotting: bitflow, tpstat, pktstat, or pkttrans
## @param config_file the config file
## @param prefix the prefix of the flow simulation
## @param type the type of packet, udp or tcp
## @param flow_type the type of flows, udp or tcp
## @param sche scheduler
## @param num number of flows
##
## the variable HDFF_DN_OUTPUT, HDFF_DN_SCRATCH should be set
plot_ns2_type() {
    local ARG_CMD1=$1
    shift
    local ARG_CONFIG_FILE1=$1
    shift
    local ARG_PREFIX1=$1
    shift
    local ARG_TYPE1=$1
    shift
    local ARG_FLOW_TYPE1=$1
    shift
    local ARG_SCHE1=$1
    shift
    local ARG_NUM1=$1
    shift

    #mr_trace "received: cmd='${ARG_CMD1}', prefix='${ARG_PREFIX1}', type='${ARG_TYPE1}', flow='${ARG_FLOW_TYPE1}', sche='${ARG_SCHE1}', num='${ARG_NUM1}'"

    ARG_CMD=$( unquote_filename "${ARG_CMD1}" )
    ARG_CONFIG_FILE=$( unquote_filename "${ARG_CONFIG_FILE1}" )
    ARG_PREFIX=$( unquote_filename "${ARG_PREFIX1}" )
    ARG_TYPE=$( unquote_filename "${ARG_TYPE1}" )
    ARG_FLOW_TYPE=$( unquote_filename "${ARG_FLOW_TYPE1}" )
    ARG_SCHE=$( unquote_filename "${ARG_SCHE1}" )
    ARG_NUM=$( unquote_filename "${ARG_NUM1}" )

    mr_trace "after processed: cmd='${ARG_CMD}', prefix='${ARG_PREFIX}', type='${ARG_TYPE}', flow='${ARG_FLOW_TYPE}', sche='${ARG_SCHE}', num='${ARG_NUM}'"

    DN_TEST=$(simulation_directory "${ARG_PREFIX}" "${ARG_TYPE}" "${ARG_SCHE}" "${ARG_NUM}")

    make_dir "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}" > /dev/null 2>&1

    #mr_trace "ARG_CMD=${ARG_CMD}"

    local FN_TMP_c0="/tmp/config-$(uuidgen)"
    copy_file "${ARG_CONFIG_FILE}" "${FN_TMP_c0}" > /dev/null 2>&1
    read_config_file "${FN_TMP_c0}"
    rm_f_dir "${FN_TMP_c0}" > /dev/null 2>&1

    # for multiple profiles
    local BLKLST=
    local lst2=
    local NUM=0
    case "${ARG_TYPE}" in
    "udp")
        if [ "${INIT_FLOW_PROFILE_UDP}" = "" ]; then
            mr_trace "Error: setting 'UDP' null for tpstat4pfhalf: ${ARG_TYPE}"
            return
        fi
        BLKLST="${INIT_FLOW_PROFILE_UDP}"
        lst2=(${BLKLST})
        NUM=${#lst2[*]}
        ;;
    "tcp")
        if [ "${INIT_FLOW_PROFILE_FTP}" = "" ]; then
            mr_trace "Error: setting 'UDP' null for tpstat4pfhalf: ${ARG_TYPE}"
            return
        fi
        BLKLST="${INIT_FLOW_PROFILE_FTP}"
        lst2=(${BLKLST})
        NUM=${#lst2[*]}
        ;;
    esac

    if [ ${NUM} -gt 1 ]; then
        # multiple profiles
        NUM=$(($NUM + 1))
    fi

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
            plot_eachflow_throughput "${DN_SRC#file://}" "${DN_DEST#file://}" "${DN_TEST}" "${TITLE}" "CMTCPDS*.out"
            ;;
        "udp")
            plot_eachflow_throughput "${DN_SRC#file://}" "${DN_DEST#file://}" "${DN_TEST}" "${TITLE}" "CMUDPDS*.out"
            ;;
        *)
            mr_trace "Error: Unknown flow type: ${ARG_FLOW_TYPE}"
            exit 1
            ;;
        esac
        cd "${DN_DEST#file://}" > /dev/null 2>&1
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

        local TMP_DEST=""
        local DN_SRC="${HDFF_DN_OUTPUT}/dataconf/"
        local DN_DEST="${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}"
        local RET=$(is_local "${DN_DEST}")
        if [ ! "${RET}" = "l" ]; then
            TMP_DEST="${HDFF_DN_SCRATCH}/file-$(uuidgen)/"
            make_dir "${TMP_DEST}/" > /dev/null 2>&1
            DN_DEST="${TMP_DEST}/"
        fi

        if [ ${NUM} -gt 1 ]; then
            # multiple profiles
            local CNT9=0
            while [[ $CNT9 < $NUM ]]; do
                local DN_ORIG5=$(pwd)
                FN_TP="${HDFF_DN_SCRATCH}/tpstat-avg-agg-jfi-${CNT9}-${ARG_PREFIX}-${ARG_TYPE}-$(uuidgen).dat"
                #generate_throughput_stats_single_folder "${DN_SRC#file://}" "${ARG_PREFIX}" "${ARG_TYPE}" "PF" "#" "${ARG_FLOW_TYPE}" "notfound.out"    "CM??PDS*.out" "${FN_TP}" "${BLKLST}" 0
                generate_throughput_stats_file "${DN_SRC#file://}" "${ARG_PREFIX}" "${ARG_TYPE}" "${ARG_FLOW_TYPE}" "notfound.out"    "CM??PDS*.out" "${FN_TP}" "${BLKLST}" ${CNT9}
                copy_file "${FN_TP}" "${DN_SRC}"

                gplot_draw_statfig "${FN_TP}"  6 "Aggregate Throughput"  "Throughput (bps)" "fig-aggtp-${ARG_PREFIX}-${ARG_TYPE}-${CNT9}" "${DN_DEST#file://}"
                gplot_draw_statfig "${FN_TP}"  7 "Average Throughput"    "Throughput (bps)" "fig-avgtp-${ARG_PREFIX}-${ARG_TYPE}-${CNT9}" "${DN_DEST#file://}"
                gplot_draw_statfig "${FN_TP}" 10 "Jain's Fairness Index" "JFI"              "fig-jfi-${ARG_PREFIX}-${ARG_TYPE}-${CNT9}" "${DN_DEST#file://}"
                gplot_draw_statfig "${FN_TP}" 11 "CFI"                   "CFI"              "fig-cfi-${ARG_PREFIX}-${ARG_TYPE}-${CNT9}" "${DN_DEST#file://}"
                #rm_f_dir "${FN_TP}"
                cd "${DN_ORIG5}"
                cd "${DN_DEST#file://}"
                convert_eps2png
                cd "${DN_ORIG5}"
                if [ ! "${TMP_DEST}" = "" ]; then
                    copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}" > /dev/null 2>&1
                    rm_f_dir "${TMP_DEST}" > /dev/null 2>&1
                fi

                CNT9=$(($CNT9 + 1))
            done

        else
            # only one profile

            local DN_ORIG5=$(pwd)
            FN_TP="${HDFF_DN_SCRATCH}/tpstat-avg-agg-jfi-${ARG_PREFIX}-${ARG_TYPE}-$(uuidgen).dat"
            generate_throughput_stats_file "${DN_SRC#file://}" "${ARG_PREFIX}" "${ARG_TYPE}" "${ARG_FLOW_TYPE}" "notfound.out"    "CM??PDS*.out" "${FN_TP}" "" 0
            copy_file "${FN_TP}" "${DN_SRC}"

            gplot_draw_statfig "${FN_TP}"  6 "Aggregate Throughput"  "Throughput (bps)" "fig-aggtp-${ARG_PREFIX}-${ARG_TYPE}" "${DN_DEST#file://}"
            gplot_draw_statfig "${FN_TP}"  7 "Average Throughput"    "Throughput (bps)" "fig-avgtp-${ARG_PREFIX}-${ARG_TYPE}" "${DN_DEST#file://}"
            gplot_draw_statfig "${FN_TP}" 10 "Jain's Fairness Index" "JFI"              "fig-jfi-${ARG_PREFIX}-${ARG_TYPE}" "${DN_DEST#file://}"
            gplot_draw_statfig "${FN_TP}" 11 "CFI"                   "CFI"              "fig-cfi-${ARG_PREFIX}-${ARG_TYPE}" "${DN_DEST#file://}"
            #rm_f_dir "${FN_TP}"
            cd "${DN_ORIG5}"
            cd "${DN_DEST#file://}"
            convert_eps2png
            cd "${DN_ORIG5}"
            if [ ! "${TMP_DEST}" = "" ]; then
                copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}" > /dev/null 2>&1
                rm_f_dir "${TMP_DEST}" > /dev/null 2>&1
            fi
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

        if [ ${NUM} -gt 1 ]; then
            # multiple profiles
            local CNT9=0
            while [[ $CNT9 < $NUM ]]; do

                plot_pktdelay_queue "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "${DN_DEST#file://}" "${DN_TEST}" ${ARG_NUM} "${BLKLST}" ${CNT9}
                cd "${DN_DEST#file://}"
                convert_eps2png
                cd "${DN_ORIG6}"
                if [ ! "${TMP_DEST}" = "" ]; then
                    copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}" > /dev/null 2>&1
                    rm_f_dir "${TMP_DEST}" > /dev/null 2>&1
                fi

                CNT9=$(($CNT9 + 1))
            done

        else
            # only one profile

            plot_pktdelay_queue "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "${DN_DEST#file://}" "${DN_TEST}" ${ARG_NUM} "" 0
            cd "${DN_DEST#file://}"
            convert_eps2png
            cd "${DN_ORIG6}"
            if [ ! "${TMP_DEST}" = "" ]; then
                copy_file "${TMP_DEST}" "${HDFF_DN_OUTPUT}/figures/${ARG_PREFIX}" > /dev/null 2>&1
                rm_f_dir "${TMP_DEST}" > /dev/null 2>&1
            fi

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
        plot_pktdelay_trans "${HDFF_DN_OUTPUT}/dataconf/${DN_TEST}" "${DN_DEST#file://}" "${DN_TEST}"
        cd "${DN_DEST#file://}"
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
