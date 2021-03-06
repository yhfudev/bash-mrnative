#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief functions for plotting figures
##
##
## @author Yunhui Fu <yhfudev@gmail.com>
## @copyright GPL v3.0 or later
## @version 1
##
#####################################################################

# please make sure the following variables are set:
if [ "${HDFF_DN_SCRATCH}" = "" ]; then
HDFF_DN_SCRATCH="/dev/shm/${USER}/"
fi

EXEC_AWK=$(which gawk)
EXEC_PLOT=$(which gnuplot)

PNGSIZE="1024,768"
PNGSIZE="800,600"

if [ ! -x "${EXEC_AWK}" ]; then
  #echo "Try to install gawk." 1>&2
  #install_package gawk
  mr_trace "Please install gawk."
  exit 1
fi

EXEC_AWK=$(which gawk)
if [ ! -x "${EXEC_AWK}" ]; then
  mr_trace "Error: Not exist awk!"
  exit 1
fi

which gnuplot > /dev/null 2>&1
if [ "$?" = "1" ]; then
  #install_package gnuplot
  mr_trace "Please install gnuplot."
  exit 1
fi
FLG_HAS_GNUPLOT=0
which gnuplot > /dev/null 2>&1
if [ "$?" = "1" ]; then
  mr_trace "Warning: Not exist gnuplot"
  FLG_HAS_GNUPLOT=0
else
  FLG_GNUPLOT_LESS_43=`${EXEC_PLOT} --version | ${EXEC_AWK} '{print $2 < 4.3}'`
  if [ ${FLG_GNUPLOT_LESS_43} = 1 ]; then
    mr_trace "Warning: ${EXEC_PLOT} verion < 4.3, it may not plot CDF correctly."
  fi
  FLG_HAS_GNUPLOT=1
fi

## @fn detect_gawk_from()
## @brief detect the path to gawk
## @param path the path contain gawk
detect_gawk_from() {
    local PARAM_PATH=$1
    shift
    local EXEC_CMD="${PARAM_PATH}"
    if [ -d "${PARAM_PATH}" ]; then
        EXEC_CMD="${PARAM_PATH}/gawk"
    fi
    if [ -x "${EXEC_CMD}" ]; then
        export EXEC_AWK=${EXEC_CMD}
        return 0
    fi
    return 1
}

## @fn detect_gnuplot_from()
## @brief detect the path to gnuplot
## @param path the path contain gnuplot
detect_gnuplot_from() {
    local PARAM_PATH=$1
    shift
    local EXEC_CMD="${PARAM_PATH}"
    if [ -d "${PARAM_PATH}" ]; then
        EXEC_CMD="${PARAM_PATH}/gnuplot"
    fi
    if [ -x "${EXEC_CMD}" ]; then
        export EXEC_PLOT=${EXEC_CMD}
        return 0
    fi
    return 1
}

## @fn test_gawk_switch()
## @brief test if gawk supports key word 'switch'
test_gawk_switch() {
    mr_trace "patch gawk to support 'switch'"
    echo | awk '{a = 1; switch(a) { case 0: break; } }'
    echo "$?"
}

## @fn test_gnuplot_cdf()
## @brief test if gnuplot supports key word 'cumulative'
test_gnuplot_cdf() {
    # output file name prefix
    FN_GPOUT="tmp-testcdf"
    # the data file
    FN_DATA="${FN_GPOUT}.dat"
    GP_INPUT="< gzip -dc ${FN_DATA}.gz"

    if [ ! -f "${FN_DATA}.gz" ]; then
        echo "" > "${FN_DATA}"
        i=0
        while (( $i < 10000 )); do
            echo "$(( $RANDOM % 100 ))" >> "${FN_DATA}"
            i=$(( $i + 1 ))
        done

        gzip "${FN_DATA}"
    fi

    cat << EOF > "${FN_GPOUT}.gp"

myint(x)=(x>0)?int(x+0.5):int(x-0.5)
bin(x,s)=s*myint(x/s)

stats "${GP_INPUT}" u 1:1

npoints=STATS_max_x+1
scale=(npoints/100)
numrec=STATS_records

#set terminal pdf color solid lw 1 size 5.83,4.13 font "cmr12" enh
#set pointsize 1
#set output "${FN_GPOUT}.pdf"
set terminal postscript eps color enhanced
set output "${FN_GPOUT}.eps"

set multiplot # get into multiplot mode
set origin 0.0,0.0
set size 1,1.0
scmax=ceil(STATS_max_x*100)*1./100
set yrange [0:scmax]

set ylabel "CDF"
set y2label "PDF"
set y2tics
set grid x2 y2

set autoscale y
set autoscale y2

plot \
      "${GP_INPUT}" u (bin(\$1,scale)):(1.0/(scale*npoints)) t 'PDF' smooth frequency with boxes axes x2y2 \
    , "${GP_INPUT}" us 1:(1./numrec) smooth cumulative t "CDF" lc 0

EOF

    gnuplot "${FN_GPOUT}.gp"
    RET=$?
    rm -f "${FN_GPOUT}.dat" "${FN_GPOUT}.dat.gz" "${FN_GPOUT}.eps" "${FN_GPOUT}.png" "${FN_GPOUT}.gp"
    echo "$RET"
}

## @fn test_gnuplot_png()
## @brief test if gnuplot supports output png files
test_gnuplot_png() {
    FN_GPOUT="tmp-testpng"

    cat << EOF > "${FN_GPOUT}.gp"
# set terminal png transparent nocrop enhanced size 450,320 font "arial,8" 
set terminal png size ${PNGSIZE}
set output "${FN_GPOUT}.png"

set key bmargin left horizontal Right noreverse enhanced autotitle box lt black linewidth 1.000 dashtype solid
set samples 800, 800
set title "Simple Plots" 
set title  font ",20" norotate
plot [-30:20] sin(x*20)*atan(x)
EOF
    gnuplot "${FN_GPOUT}.gp"
    RET=$?
    rm -f "${FN_GPOUT}.eps" "${FN_GPOUT}.png" "${FN_GPOUT}.gp"
    echo "$RET"
}

RET1=$(test_gnuplot_png 2>/dev/null)
if [ "$RET1" = "0" ]; then
    FLG_GNUPLOT_HASPNG=1
else
    FLG_GNUPLOT_HASPNG=0
fi

RET1=$(test_gnuplot_cdf 2>/dev/null)
if [ "$RET1" = "0" ]; then
    FLG_GNUPLOT_LESS_43=0
else
    FLG_GNUPLOT_LESS_43=1
fi

RET1=$(test_gawk_switch 2>/dev/null)
if [ ! "$RET1" = "0" ]; then
    mr_trace "Warning: gawk don't support switch!"
    #exit 1
fi

#####################################################################

## @fn plot_script()
## @brief plot the script file
## @param FN_TMPGP the gnuplot script file
plot_script() {
    FN_TMPGP="$1"
    shift

    if [ ${FLG_HAS_GNUPLOT} = 1 ]; then
        if [ ${FLG_GNUPLOT_LESS_43} = 1 ]; then
            mr_trace "Warning: ${EXEC_PLOT} verion < 4.3, it may not plot CDF correctly."
        fi
        $MYEXEC "${EXEC_PLOT}" "${FN_TMPGP}"
        if [ ! "$?" = "0" ]; then
            NEWNAME="${FN_TMPGP}$(date +%s)"
            mr_trace "Warning: error in process file ${FN_TMPGP}, changed to ${NEWNAME}."
            $MYEXEC mv "${FN_TMPGP}" "${NEWNAME}"
        fi
    else
        mr_trace "Error: unable to find the gnuplot!"
        exit 1
    fi
}

## @fn calculate_stats()
## @brief calculate the values min,max,sum,mean,stddev,jfi for average throughput of N nodes
## @param IMIN initialized min value
## @param IMAX initialized max value
##
## Example:
## calculate_stats 10000000000 0
## input file/stream: 1 column of data
calculate_stats() {
    PARAM_IMIN=$1
    shift
    PARAM_IMAX=$1
    shift

    cat > tmp-tp-stats.awk << EOF
# generated by $0, $(date)
BEGIN {
    cnt = 0;
    sum = 0;
    sumsq = 0;
    min = IMIN; # init to the argument IMIN
    max = IMAX; # init to the argument IMAX
} {
    val = \$1;
    cnt ++;
    sum += val;
    sumsq += val * val;
    if (max < val) { max = val; }
    if (min > val) { min = val; }
} END {
    if (cnt > 0) {
        jfi = sum * sum / sumsq / cnt;
        mmr = min / max;
        cfi = jfi * 0.75 + mmr * 0.25;
        mean = sum / cnt;
        stddev = sqrt (sumsq / cnt - (sum / cnt)**2);
        # cnt mean stddev mmr jfi cfi
        printf ("%d %8.1f %8.1f %8.1f %8.1f %8.1f %4.2f %4.2f %4.2f", cnt, min, max, sum, mean, stddev, mmr, jfi, cfi);
    } else {
        print "0 0 Nan Nan Nan Nan Nan"
    }
}
EOF
    awk -v IMIN=${PARAM_IMIN} -v IMAX=${PARAM_IMAX} -f tmp-tp-stats.awk
}

#####################################################################

## @fn gplot_setheader()
## @brief set the gnuplot script header
## @param FN_TMPGP the gnuplot script file
gplot_setheader() {
    PARAM_FN_TMPGP=$1
    shift

# GNUPLOT - create the header of gnuplot script
cat << EOF > "${PARAM_FN_TMPGP}"
# generated by $0

set style line 1 pt 2 lc rgb '#8A2BE2' lw 1
set style line 2 lt 2 lc rgb 'red'     lw 1
#set style line 3 pt 1 lc rgb '#006400' lw 1
set style line 3 lt 1 lc rgb '#006400' lw 1
set style line 4 lt 1 lc 9 lw 1
set style line 5 lt 5 lc 5 lw 1

set key default
#set logscale xy
#set log x2
#unset log y2
set ytics nomirror
set tics out
set autoscale y
EOF
}

## @fn gplot_settail()
## @brief set the gnuplot script tail
## @param FN_TMPGP the gnuplot script file
gplot_settail() {
    PARAM_FN_TMPGP=$1
    shift
    PARAM_FN_OUTBASE=$1
    shift

# GNUPLOT - add several output file formats
cat << EOF >> "${PARAM_FN_TMPGP}"
# save to eps
set terminal postscript eps color enhanced
set output "${PARAM_FN_OUTBASE}.eps"

plot ${PLOT_LINE}

unset xrange

#print GPVAL_COMPILE_OPTIONS
#print GPVAL_TERMINALS
##set terminal pdf monochrome solid font 'Helvetica,14' size 16cm,12cm
#set terminal pdf
#set output "${PARAM_FN_OUTBASE}.pdf"

#set terminal postscript eps
#set output "| epstopdf --filter --outfile=${PARAM_FN_OUTBASE}.pdf"

#set terminal postscript enhanced color
#set output "| ps2pdf - ${PARAM_FN_OUTBASE}.pdf"

#replot

EOF

if [ "${FLG_GNUPLOT_HASPNG}" = "1" ]; then
    cat << EOF >> "${PARAM_FN_TMPGP}"
set terminal png size ${PNGSIZE}
set output "${PARAM_FN_OUTBASE}.png"
replot
EOF
fi

}

## @fn gplot_draw_statfig()
## @brief draw stat figure
## @param FN_DATA data file, col 1: #, col2: sched, col3-N: val
## @param COL column to be showed
## @param TITLE figure title
## @param YLABEL y label
## @param FN_OUTFIG figure file name
## @param DN_OUTFIG the dir to store the script file
##
## Example:
## gplot_draw_statfig "file.dat" 3 "Aggregate Throughput" "Throughput (bps)" "fig-aggtp-${PARAM_FLOW_TYPE}"
gplot_draw_statfig() {
    PARAM_FN_DATA=$1
    shift
    PARAM_COL=$1
    shift
    PARAM_TITLE=$1
    shift
    PARAM_YLABEL=$1
    shift
    PARAM_FN_OUTFIG=$1
    shift
    PARAM_DN_OUTFIG=$1
    shift

    # plot figure
    FN_TMPGP="${HDFF_DN_SCRATCH}/tmp-statsfig-$PARAM_FN_OUTFIG.gplot"
    gplot_setheader "${FN_TMPGP}"

    TITLE="${PARAM_TITLE}"
    XLABEL="Nodes"
    YLABEL="${PARAM_YLABEL}"

    # GNUPLOT - the arguments for gnuplot plot command
    PLOT_LINE=

    # GNUPLOT - set the labels
    cat << EOF >> "${FN_TMPGP}"
set logscale x

set title "${TITLE}"
set xlabel "${XLABEL}"
set ylabel "${YLABEL}"
EOF
    for sched in $LIST_SCHEDULERS ; do
        FN="${HDFF_DN_SCRATCH}/tmp-stats-$sched-col-${PARAM_COL}.dat"
        cat ${PARAM_FN_DATA} | grep $sched | awk "{print \$1 \" \" \$${PARAM_COL};}" > "${FN}"
        TTT="$(sed 's/[\"\`_]/ /g' <<<$sched)"
        if [ ! "${PLOT_LINE}" = "" ] ; then PLOT_LINE="${PLOT_LINE},"; fi
        PLOT_LINE="${PLOT_LINE} '${FN}' index 0 using 1:2 t '$TTT' with lp"
    done
    gplot_settail "${FN_TMPGP}" "${PARAM_DN_OUTFIG}/${PARAM_FN_OUTFIG}"

    mr_trace "ploting ${PARAM_FN_OUTFIG} ..."
    plot_script "${FN_TMPGP}"
}

#####################################################################
# Some useful sub-functions for plotting PDF/CDF figures.

## @fn plotgen_pdf_head()
## @brief generate gnuplot script file header for PDF figures
## @param FN_TMPGP the gnuplot script file
plotgen_pdf_head() {
    FN_TMPGP="$1"
    shift

    cat >> "${FN_TMPGP}" << EOF
bin(x,scale) = scale*int(x/scale)
EOF
}

## @fn plotgen_pdf_pdf()
## @brief generate gnuplot script file contents for PDF figures
## @param NUMREC number of records
## @param INTERVAL the interval of x axis
## @param MAXVALUE the max value of the data
## @param FN_FULL the file name of the data file
## @param FN_TMPGP the gnuplot script file
plotgen_pdf_pdf() {
    PARAM_NUMREC=$1
    shift
    PARAM_INTERVAL=$1
    shift
    PARAM_MAXVALUE=$1
    shift
    PARAM_FN_FULL="$1"
    shift
    FN_TMPGP="$1"
    shift

    FN="${PARAM_FN_FULL}"
    case "${PARAM_FN_FULL}" in
    *.gz)
        FN="< gzip -dc ${PARAM_FN_FULL}"
        ;;
    esac

    cat >> "${FN_TMPGP}" << EOF
scale=(${PARAM_MAXVALUE}/100) #${PARAM_INTERVAL}
set xrange [0:${PARAM_MAXVALUE}]
set boxwidth (${PARAM_MAXVALUE}/100) #${PARAM_INTERVAL}

#plot [-0.1/${PARAM_INTERVAL}:1.1/${PARAM_INTERVAL}][-0.3:1.1] "${PARAM_FN_FULL}" u (bin(\$1,${PARAM_INTERVAL})):(1./(${PARAM_NUMREC}*${PARAM_INTERVAL})) t 'PDF' smooth frequency with boxes
plot "${FN}" u (bin(\$1,scale)):(1./(scale*(${PARAM_NUMREC}))) t 'PDF' smooth frequency with boxes
unset xrange
EOF
}

## @fn plotgen_pdf_cdf()
## @brief generate gnuplot script file contents for CDF figures
## @param NUMREC number of records
## @param INTERVAL the interval of x axis
## @param MAXVALUE the max value of the data
## @param FN_FULL the file name of the data file
## @param FN_TMPGP the gnuplot script file
plotgen_pdf_cdf() {
    #mr_trace "DEBUG: ==== args: $@"
    PARAM_NUMREC=$1
    shift
    PARAM_INTERVAL=$1
    shift
    PARAM_MAXVALUE=$1
    shift
    PARAM_FN_FULL="$1"
    shift
    FN_TMPGP="$1"
    shift

    FN="${PARAM_FN_FULL}"
    case "${PARAM_FN_FULL}" in
    *.gz)
        FN="< gzip -dc ${PARAM_FN_FULL}"
        ;;
    esac

    cat >> "${FN_TMPGP}" << EOF
set boxwidth (${PARAM_MAXVALUE}/100)
#set xrange [0:${PARAM_MAXVALUE}]

scale=(${PARAM_MAXVALUE}/100)

#plot [-0.1*${PARAM_MAXVALUE}:1.1*${PARAM_MAXVALUE}][-0.3:1.1] \
#     "${FN}" u 1:(1./${PARAM_NUMREC}.) t 'CDF' smooth cumulative
#    #  "${FN}" u (bin(\$1,scale)):(1.0/(scale*(${PARAM_NUMREC}))) t 'PDF' smooth frequency with boxes axes x2y2 \
#    #, "${PARAM_FN_FULL}" u 1:(0.12*rand(0)-.2) t '' with dot

#set rmargin 9
set y2label "PDF"
set y2tics
set grid x2 y2

set autoscale y
set autoscale y2

# keep x and x2 sync:
set xrange [] writeback
set x2range [] writeback
set autoscale xfixmin
set autoscale xfixmax

plot [:][0:1.1] \
      "${GP_INPUT}" u (bin(\$1,scale)):(1.0/(scale*${PARAM_MAXVALUE})) t 'PDF' smooth frequency with boxes axes x2y2 \
    , "${GP_INPUT}" us 1:(1./${PARAM_NUMREC}.) smooth cumulative t "CDF" lc 0

EOF

}

#####################################################################

## @fn plotgen_pdf_with_minmax()
## @brief 输出gnuplot脚本文件，用于绘制 概率密度函数(PDF, Probability Density Function) 和 累积分布函数(CDF, Cumulative Distribution Function)
##
## @param TITLE the plot figure title
## @param XLABEL the plot figure x label
## @param YLABEL the plot figure y label
## @param FN_FULL the file name of the data file
## @param FN_OUT_BASE the output figure file basename
## @param FN_OUT_GNUPLOT the output gnuplot file name
## @param NUMREC number of records
## @param INTERVAL the interval of x axis
## @param MAXVALUE the max value of the data
##
## 使用输入数据文件的第一列数据
## 算法见 Gnuplot in Action 13 章 (http://www.manning.com/janert/SampleCh13.pdf)
plotgen_pdf_with_minmax() {
    # the plot figure title
    PARAM_TITLE="$1"
    shift
    # the plot figure x label
    PARAM_XLABEL="$1"
    shift
    # the plot figure y label
    PARAM_YLABEL="$1"
    shift
    # the data file full path name
    PARAM_FN_FULL="$1"
    shift
    # the output figure file basename
    PARAM_FN_OUT_BASE="$1"
    shift
    # the output gnuplot file name
    PARAM_FN_OUT_GNUPLOT="$1"
    shift
    # the number of records in the data file
    PARAM_NUMREC="$1"
    shift
    PARAM_INTERVAL="$1"
    shift
    # the max value of the records
    PARAM_MAXVALUE="$1"
    shift

    # save the parameters for the temp data file (last 3 args): PARAM_NUMREC, PARAM_INTERVAL, PARAM_MAXVALUE
    echo "${PARAM_NUMREC} ${PARAM_INTERVAL} ${PARAM_MAXVALUE}" > "${PARAM_FN_FULL}.plotpdfinfo"

    # get rid of "trace"
    #FN_BASE=`echo "${PARAM_FN_FULL}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}'`

    if [ "${PARAM_FN_OUT_GNUPLOT}" = "" ]; then
        FN_TMPGP="${HDFF_DN_SCRATCH}/op-tmp1.gp"
    else
        FN_TMPGP="${PARAM_FN_OUT_GNUPLOT}"
    fi

    GPLOT_INFO="Generated by $0 `date '+%Y-%m-%d %H:%M:%S'`"
    rm -f "${FN_TMPGP}"
    cat > "${FN_TMPGP}" << EOF
# ${GPLOT_INFO}

set grid nopolar
set grid xtics nomxtics ytics nomytics noztics nomztics \
 nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics
set grid layerdefault   linetype 0 linewidth 1.000,  linetype 0 linewidth 1.000
set ytics border in scale 1,0.5 mirror norotate  offset character 0, 0, 0

#set lmargin 9
#set rmargin 2
#set key left top
set key right center
#set logscale xy

set xlabel "${PARAM_XLABEL}"
set ylabel "${PARAM_YLABEL}"
set title "${PARAM_TITLE}"
EOF

    plotgen_pdf_head "${FN_TMPGP}"

    cat >> "${FN_TMPGP}" << EOF
# save to eps
set terminal postscript eps color enhanced
set output "${PARAM_FN_OUT_BASE}-pdf.eps"

EOF

    plotgen_pdf_pdf ${PARAM_NUMREC} ${PARAM_INTERVAL} ${PARAM_MAXVALUE} "${PARAM_FN_FULL}" "${FN_TMPGP}"

    if [ "${FLG_GNUPLOT_HASPNG}" = "1" ]; then
        cat >> "${FN_TMPGP}" << EOF
# save to png
#set terminal png transparent size 1024,768
set terminal png size ${PNGSIZE}
set output "${PARAM_FN_OUT_BASE}-pdf.png"
replot
EOF
    fi

    if [ ${FLG_GNUPLOT_LESS_43} = 1 ]; then
        mr_trace "Unable to plot CDF file: ${PARAM_FN_OUT_BASE}"
    else
        cat >> "${FN_TMPGP}" << EOF
# save to eps
set terminal postscript eps color enhanced
set output "${PARAM_FN_OUT_BASE}-cdf.eps"

EOF

        plotgen_pdf_cdf ${PARAM_NUMREC} ${PARAM_INTERVAL} ${PARAM_MAXVALUE} "${PARAM_FN_FULL}" "${FN_TMPGP}"

        if [ "${FLG_GNUPLOT_HASPNG}" = "1" ]; then
            cat >> "${FN_TMPGP}" << EOF
# save to png
#set terminal png transparent size 1024,768
set terminal png size ${PNGSIZE}
set output "${PARAM_FN_OUT_BASE}-cdf.png"
replot
EOF
        fi

    fi
}

_get_interval_gz () {
    PARAM_FN_INTERVALS="$1"
    shift

    #PARAM_FN_INTERVALS_2="${PARAM_FN_INTERVALS}"
    #case "${PARAM_FN_INTERVALS}" in
    #*.gz)
        #PARAM_FN_INTERVALS_2="<(gzip -dc ${PARAM_FN_INTERVALS})"
        #;;
    #esac

    case "${PARAM_FN_INTERVALS}" in
    *.gz)
        gzip -dc ${PARAM_FN_INTERVALS} | ${EXEC_AWK} 'BEGIN{total=0} NR==1{mininte=$1; maxinte=$1} {new=$1; total+=$1} {if (new>0) {if (mininte>new) {mininte=new}; if (maxinte<new) {maxinte=new}}} END {print mininte " " maxinte " " total/NR " " NR " " total }'
        ;;
    *)
        ${EXEC_AWK} 'BEGIN{total=0} NR==1{mininte=$1; maxinte=$1} {new=$1; total+=$1} {if (new>0) {if (mininte>new) {mininte=new}; if (maxinte<new) {maxinte=new}}} END {print mininte " " maxinte " " total/NR " " NR " " total }' ${PARAM_FN_INTERVALS}
        ;;
    esac
}

#####################################################################
## @fn plotgen_pdf()
## @brief plot CDF/PDF after calculating the min/max value of the intervals
##
## @param TITLE the plot figure title
## @param XLABEL the plot figure x label
## @param YLABEL the plot figure y label
## @param FN_INTERVALS the interval data file
## @param FN_BASE the output figure file basename
## @param FN_OUT_GNUPLOT the output gnuplot file name
plotgen_pdf() {
    PARAM_TITLE="$1"
    shift
    PARAM_XLABEL="$1"
    shift
    PARAM_YLABEL="$1"
    shift
    PARAM_FN_INTERVALS="$1"
    shift
    PARAM_FN_BASE="$1"
    shift
    # the output gnuplot file name
    PARAM_FN_OUT_GNUPLOT="$1"
    shift

    #mr_trace "DEBUG: ==== interval file: ${PARAM_FN_INTERVALS}"
    # get the min interval
    # extend the box width by x3
    MIN_INTERVAL=$( _get_interval_gz "${PARAM_FN_INTERVALS}" )

    #mr_trace "DEBUG: ==== ${PARAM_TITLE}: min/max/avg = ${MIN_INTERVAL}; fn=${PARAM_FN_INTERVALS}"

    # get the max interval
    MAX_INTERVAL=`echo "${MIN_INTERVAL}" | ${EXEC_AWK} '{print $2}'`

    # get the average intervals
    #INTERVAL=`${EXEC_AWK} 'BEGIN{total=0} {total+=$1} END {print total/NR/20}' ${PARAM_FN_INTERVALS_2}`
    INTERVAL=`echo "${MIN_INTERVAL}" | ${EXEC_AWK} '{print $3}'`

    # get the number of records
    #NUM_REC=`${EXEC_AWK} 'END {print NR}' ${PARAM_FN_INTERVALS_2}`
    NUM_REC=`echo "${MIN_INTERVAL}" | ${EXEC_AWK} '{print $4}'`
    if [ "${NUM_REC}" = "" ]; then
        mr_trace "Error: unable to get the num of record"
        return
    fi
    if [ "${NUM_REC}" = "0" ]; then
        mr_trace "Error: Num of record = 0"
        return
    fi
    TOTAL=`echo "${MIN_INTERVAL}" | ${EXEC_AWK} '{print $5}'`

    MIN_INTERVAL=`echo "${MIN_INTERVAL}" | ${EXEC_AWK} '{print $1}'`
    #mr_trace "DEBUG: ==== maxinterval=${MAX_INTERVAL}; mininterval=${MIN_INTERVAL}; avg interval=${INTERVAL}; "

if [ 0 = 1 ]; then
    MAX_INTERVAL_BAK=${MAX_INTERVAL}

    # get W1, the range of 90% data; the width to be used in plotting is 2*W1
    N=$(echo | ${EXEC_AWK} -v A=${MAX_INTERVAL} -v B=${INTERVAL} '{print int(A*150/B + 1)}')
    MAX_INTERVAL=$( ${EXEC_AWK} -v N=${N} -v MAX=${MAX_INTERVAL} 'BEGIN{W=MAX/N} {i=int(($1+0.5)/W); a[i]=a[i]+1;} END {wl=MAX*0.9; sum=0; for (i = 0; i < N; i ++) {sum=sum+a[i]; if (sum > wl) {break}} print W*i*2 }' ${PARAM_FN_INTERVALS_2} )
    #mr_trace "DEBUG: ==== 0 MAX_INTERVAL=${MAX_INTERVAL}"
    #mr_trace "DEBUG: ==== 0 MIN_INTERVAL=${MIN_INTERVAL}"

    # TCP LAN ACK should be in 0.3 second
    if [ "`echo | ${EXEC_AWK} -v A=${MAX_INTERVAL} '{if (A < 0.035) {print 1} else {print 0}}'`" = "1" ]; then
        MAX_INTERVAL=0.035
        MIN_INTERVAL=`echo | ${EXEC_AWK} -v A=${MAX_INTERVAL} '{print A/150}'`
        #mr_trace "DEBUG: ==== 1 MIN_INTERVAL=${MIN_INTERVAL}"
    fi

    # 如果调整后的 MAX_INTERVAL 大于最大值，则调整成最大值，同时相应设置MIN_INTERVAL
    if [ "`echo | ${EXEC_AWK} -v A=${MAX_INTERVAL} -v B=${MAX_INTERVAL_BAK} '{if (A > B) {print 1} else {print 0}}'`" = "1" ]; then
        #mr_trace "DEBUG: ==== 2 MAX_INTERVAL change from ${MAX_INTERVAL} to ${MAX_INTERVAL_BAK}"
        MAX_INTERVAL=${MAX_INTERVAL_BAK}
        #mr_trace "DEBUG: ==== 2 adjusted MAX_INTERVAL=${MAX_INTERVAL}"
        MIN_INTERVAL=`echo | ${EXEC_AWK} -v A=${MAX_INTERVAL} '{print A/150}'`
        #mr_trace "DEBUG: ==== 2 adjusted MIN_INTERVAL=${MIN_INTERVAL}"
    fi

    # 如果调整后的 MAX_INTERVAL 大于平均值的3倍，则设置成平均值的3倍，同时相应设置MIN_INTERVAL
    if [ "`echo | ${EXEC_AWK} -v A=${MAX_INTERVAL} -v B=${INTERVAL} '{if (A > B*5) {print 1} else {print 0}}'`" = "1" ]; then
        MAX_INTERVAL=`echo | ${EXEC_AWK} -v A=${INTERVAL} '{print A*3}'`
        #mr_trace "DEBUG: ==== 3 MAX_INTERVAL= ${MAX_INTERVAL}"

        MIN_INTERVAL=`echo | ${EXEC_AWK} -v A=${MAX_INTERVAL} '{print A/150}'`
        #mr_trace "DEBUG: ==== 3 MIN_INTERVAL= ${MIN_INTERVAL}"
    fi

    # check the values
    if [ "${MAX_INTERVAL}" = "" ]; then
       mr_trace "Error: unable to get MAX_INTERVAL"
       exit 1
    fi
    if [ "${MIN_INTERVAL}" = "" ]; then
       mr_trace "Error: unable to get MIN_INTERVAL"
       exit 1
    fi
    if [ "`echo | ${EXEC_AWK} -v A=${MAX_INTERVAL} -v B=${MIN_INTERVAL} '{if (A < B*5) {print 1} else {print 0}}'`" = "1" ]; then
       mr_trace "Error: MAX MIN INTERVAL"
       exit 1
    fi
fi

    V=$(echo | awk -v A=${MIN_INTERVAL} -v B=${INTERVAL} '{print (199.0*A + 1.0*B) / 200.0;}')
    mr_trace "INFO: Number of Record=${NUM_REC}, Interval=${INTERVAL}, min_interval=${MIN_INTERVAL}, max_interval=${MAX_INTERVAL}, use interval $V"

    plotgen_pdf_with_minmax "${PARAM_TITLE}" "${PARAM_XLABEL}" "${PARAM_YLABEL}" "${PARAM_FN_INTERVALS}" "${PARAM_FN_BASE}" "${PARAM_FN_OUT_GNUPLOT}" "${NUM_REC}" "${V}" "${MAX_INTERVAL}"
}
