
# the maximum bitrate of the channel
# 42880000/7=6125714; use profiles_4k_async to get the 1,1.5,...,7 ratio
#BW_CHANNEL=6125714

# 2158700000: use the highest bitrate 16384QAM(8K FFT sync) as the base bitrate
# 282800000:  use the lowest bitrate QPSK(4K FFT async) as the base bitrate
#BW_CHANNEL=1850300000
BW_CHANNEL=282800000


# if use Profile
USE_PROFILE=1

# add support Profile for each goXXX.sh
patch_profile_run () {
    PARAM_FN=$1
    shift

    echo ""

if [ "${USE_PROFILE}" = "1" ]; then
    echo "patch profile for file ${PARAM_FN} ..."
    sed -i \
        -e 's|^.*ns main.tcl \$rep.*$|cp ../../Common/patchscripts.tcl .; sed -i -e "s/DS3SM_DS_PF/DS3SM_DS_${bm}/" patchscripts.tcl \n ../../../../ns main.tcl \$rep >> /dev/null\n|g' \
        "${PARAM_FN}"
fi
}

# add support Profile for tcl scripts
patch_profile_tcl () {

    echo "patch profile for file main.tcl ..."

if [ "${USE_PROFILE}" = "1" ]; then
    cat main.tcl \
        | tr '\n' '\r' \
        | sed -e "s|set cm_index 1[^\\r]*\\r\\r|source patchscripts.tcl\\n\\nset cm_index 1\\n|g" -e 's|\r|\n|g' \
        > aa
    mv aa main.tcl
    chmod 644 main.tcl
fi
}


# fix the goXXX.sh scripts for 1G network
patch_1g_flows_run () {
    PARAM_FN=$1
    shift

    # setup channel bandwidth
    REPLACE1="BW_CHANNEL=${BW_CHANNEL}\n"
    REPLACE1+='sed -i -e "s/42880000/${BW_CHANNEL}/g" channels.dat'
    REPLACE1+='; sed -i -e "s/1000000000/${BW_CHANNEL}/g" channels.dat'
    if (( ${BW_CHANNEL} > 42880000 )) ; then
        # fix the high speed problem
        REPLACE1+='; sed -i -e "s/\\.00001/0.00000001/g" channels.dat'
        # goruns.dat for 2G channel: set CONCAT_THRESHOLD 50
        REPLACE1+='; sed -i -e "s/set[[:space:]]\\+CONCAT_THRESHOLD[[:space:]]\\+.*\$/set CONCAT_THRESHOLD 150/g" docsis-conf.tcl'
    fi
    #echo "REPLACE1=${REPLACE1}"

    # 1. add config file config-nodes.sh
    # 2-. replace the fix number of flows with the value in the array list_nodes_num
    sed -i \
        -e "s|^#source \(.*\)$|source \$comdir/config-nodes.sh\n|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 88/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[7]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 77/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[6]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 66/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[5]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 55/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[4]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 44/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[3]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 33/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[2]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 22/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[1]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 11/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[0]}/\" \1|g" \
        ${PARAM_FN}
    sed -i \
        -e "s|^#source \(.*\)$|source \$comdir/config-nodes.sh\n|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 16/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[7]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 13/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[6]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 11/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[5]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 9/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[4]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 7/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[3]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 5/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[2]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 3/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[1]}/\" \1|g" \
        -e "s|sed -i 's/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs 1/'\(.*\)|sed -i \"s/set NUM_FTPs\\\\s\[0-9\]\*/set NUM_FTPs \${list_nodes_num[0]}/\" \1|g" \
        ${PARAM_FN}

    # replace multiple lines for loop with while loop
    cat ${PARAM_FN} \
        | tr '\n' '\r' \
        | sed -e "s|for run in 1 2 3 4 5[^\\r]*\\rdo\\r|run=0\\n${REPLACE1}\\nwhile (( \$run < \${#list_nodes_num[*]} )) ; do\\nrun=\$(( \$run + 1 ))\\n|g" \
              -e 's,getall.sh[\n\r[:space:]]\+cp BGSIDstats.out,getall.sh\nfind . -maxdepth 1 -type f -name "CM[TCP|UDP]*.out" | while read a ; do cp $a ./tmp/$(basename $a).$run; done\ncp BGSIDstats.out,' \
              -e 's|\r|\n|g' \
        > aa
    mv aa ${PARAM_FN}
    chmod 755 ${PARAM_FN}
}

# patch the analysis.sh for 1G network
patch_1g_flows_analysis () {
    #PARAM_FN=$1
    #shift
    for i in $(find . -name "analy*.sh") ; do
        # 1. include config for node number
        # 2-3. replace the nubmer of flows range (plot [1:11] and set xrange)
        # 4. reaplce [0,1] (index value or delay value) with [0,2]
        # 5-. replace fix flow number with the values in the array list_nodes_num
        sed -i \
            -e "s|exp=\"EXP1\"$|exp='EXP1'\nsource \"\$(pwd)/../Common\"/config-nodes.sh\n|g" \
            -e 's|plot \[1:11\]|plot \[${list_nodes_num[0]}:${list_nodes_num[$((${#list_nodes_num\[\*\]} - 1))]}\]|g' \
            -e 's|plot \[11:55\]|plot \[${list_nodes_num[0]}:${list_nodes_num[$((${#list_nodes_num\[\*\]} - 1))]}\]|g' \
            -e 's|set xrange \[1:11\]|set xrange \[${list_nodes_num[0]}:${list_nodes_num[$((${#list_nodes_num\[\*\]} - 1))]}\]|g' \
            -e 's|\[0:1\]|\[:1.2\]|g' -e 's|\[0.5:1\]|\[:1.2\]|g' \
            -e 's|awk \(.*\), 1, \(.*\)$|awk -v NFLOW=${list_nodes_num[0]} \1, NFLOW, \2|g' \
            -e 's|awk \(.*\), 3, \(.*\)$|awk -v NFLOW=${list_nodes_num[1]} \1, NFLOW, \2|g' \
            -e 's|awk \(.*\), 5, \(.*\)$|awk -v NFLOW=${list_nodes_num[2]} \1, NFLOW, \2|g' \
            -e 's|awk \(.*\), 7, \(.*\)$|awk -v NFLOW=${list_nodes_num[3]} \1, NFLOW, \2|g' \
            -e 's|awk \(.*\), 9, \(.*\)$|awk -v NFLOW=${list_nodes_num[4]} \1, NFLOW, \2|g' \
            -e 's|awk \(.*\), 11, \(.*\)$|awk -v NFLOW=${list_nodes_num[5]} \1, NFLOW, \2|g' \
            -e 's|awk \(.*\), 13, \(.*\)$|awk -v NFLOW=${list_nodes_num[6]} \1, NFLOW, \2|g' \
            -e 's|awk \(.*\), 16, \(.*\)$|awk -v NFLOW=${list_nodes_num[7]} \1, NFLOW, \2|g' \
            -e 's|awk \(.*\) 1}\(.*\)$|awk -v NFLOW=${list_nodes_num[0]} \1 NFLOW} \2|g' \
            -e 's|awk \(.*\) 3}\(.*\)$|awk -v NFLOW=${list_nodes_num[1]} \1 NFLOW} \2|g' \
            -e 's|awk \(.*\) 5}\(.*\)$|awk -v NFLOW=${list_nodes_num[2]} \1 NFLOW} \2|g' \
            -e 's|awk \(.*\) 7}\(.*\)$|awk -v NFLOW=${list_nodes_num[3]} \1 NFLOW} \2|g' \
            -e 's|awk \(.*\) 9}\(.*\)$|awk -v NFLOW=${list_nodes_num[4]} \1 NFLOW} \2|g' \
            -e 's|awk \(.*\) 11}\(.*\)$|awk -v NFLOW=${list_nodes_num[5]} \1 NFLOW} \2|g' \
            -e 's|awk \(.*\) 13}\(.*\)$|awk -v NFLOW=${list_nodes_num[6]} \1 NFLOW} \2|g' \
            -e 's|awk \(.*\) 16}\(.*\)$|awk -v NFLOW=${list_nodes_num[7]} \1 NFLOW} \2|g' \
            -e 's|for m in "drr"|for m in "pf" "drr"|' \
            ${i}
    done
}

# patch the goXXX.sh scripts
patch_runscript() {
    PARAM_FN=$1
    shift
    sed -i \
        -e "s|^source \$nsdir/ns2env|#source \$nsdir/ns2env|g" \
        -e "s|\([ \t]\{1\}\)ns\(.*\)|\1../../../../ns\2|g" \
        -e "s|ns main.tcl \$rep.*$|ns main.tcl \$rep >> /dev/null|g" \
        "${PARAM_FN}"
    patch_1g_flows_run "${PARAM_FN}"
    patch_profile_run  "${PARAM_FN}"
}

# fix the common tcl scripts
patch_common() {
    mydir=$(pwd)
    rstdir=$mydir/Results
    mkdir -p $rstdir

    patch_profile_tcl

    #sed -i -e 's|set[ \t[:space:]]\+stoptime[ \t[:space:]]\+.*$|set stoptime 2000.5|g' run-conf.tcl # debug test
    sed -i \
        -e 's|set[ \t[:space:]]\+stoptime[ \t[:space:]]\+.*$|set stoptime 100.5|g' \
        -e 's|set[ \t[:space:]]\+TCPUDP_THROUGHPUT_MONITORS_ON[ \t[:space:]]\+.*$|set TCPUDP_THROUGHPUT_MONITORS_ON 1|g' \
        -e 's|set[ \t[:space:]]\+THROUGHPUT_MONITOR_INTERVAL[ \t[:space:]]\+.*$|set THROUGHPUT_MONITOR_INTERVAL 0.5|g' \
        run-conf.tcl

    for i in $(find . -name "analy*.sh") ; do
        sed -i \
            -e "s|set terminal wxt |set terminal x11 |g" \
            -e "s|python procfslog.py|python2 \$mydir/../Common/procfslog.py|g" \
            -e "s|matlabplot |matlabplot1 |g" \
            $i
        grep -Hrn "matlabplot1()" $i
        if [ ! "$?" = "0" ]; then
            cat << EOF >> $i
# new matlabplot
matlabplot1() {
    FN_M=\$1.m
    if [ ! -f "\${FN_M}" ]; then
        FN_M="\$mydir/../Common/\$1.m"
    fi
    if [ ! -f "\${FN_M}" ]; then
        echo "matlab script \$1.m does not exist!"
        return
    fi
    EXEC_MATLAB=matlab
    which \$EXEC_MATLAB
    if [ ! "\$?" = "0" ]; then
        EXEC_MATLAB=octave
    fi
    which \$EXEC_MATLAB
    if [ ! "\$?" = "0" ]; then
        echo "unable find matlab/octave"
        return
    fi
    \$EXEC_MATLAB -nosplash -nodesktop -r \$*
}
EOF
        fi
    done
    patch_1g_flows_analysis

    # create PF test
    cp goDRR.sh goPF.sh
    sed -i -e 's|bm="[^"]\{1,\}"|bm="PF"|g' goPF.sh
}

