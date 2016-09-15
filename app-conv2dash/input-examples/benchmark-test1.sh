#!/bin/bash
# sed -i 's|/home/yhfu/00study-clemson/201401/dash-adap-algorithm/|/home/yfu/project/|g' *.txt
#####################################################################
#DN_EXEC=`echo "$0" | ${EXEC_AWK} -F/ '{b=$1; for (i=2; i < NF; i ++) {b=b "/" $(i)}; print b}'`
DN_EXEC=$(dirname $(readlink -f "$0") )
if [ ! "${DN_EXEC}" = "" ]; then
    DN_EXEC="$(readlink -f "./")/"
else
    DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(readlink -f "${DN_EXEC}/../")"

echo "[DBG] $0 DN_EXEC=${DN_EXEC}; DN_TOP=${DN_TOP}" 1>&2

#####################################################################
DN_EXAMPLES="${DN_TOP}/examples"

FN_RESULT="${DN_EXAMPLES}/testresult.txt"
echo "---------------" >> "${FN_RESULT}"
date >> "${FN_RESULT}"

test_sh1_hadoop () {
    PARAM_TSTID="$1"
    shift

    TSTID="${PARAM_TSTID}.sh1"
    START=$(date +%s)
    ${DN_TOP}/bin/run-sh1.sh
    END=$(date +%s)
    TMCOST=$(echo | awk -v A=$START -v B=$END '{print B-A;}' )
    echo "Test ${TSTID}: ${TMCOST}" >> "${FN_RESULT}"
    mv "${DN_TOP}/data/output" "${DN_TOP}/data/output-${TSTID}"

    TSTID="${PARAM_TSTID}.hadoop"
    START=$(date +%s)
    ${DN_TOP}/bin/run-hadoop.sh
    END=$(date +%s)
    TMCOST=$(echo | awk -v A=$START -v B=$END '{print B-A;}' )
    echo "Test ${TSTID}: ${TMCOST}" >> "${FN_RESULT}"
    mv "${DN_TOP}/data/output" "${DN_TOP}/data/output-${TSTID}"
}

# 1. test 1
# 1.1 mp4
echo "--- to mp4" >> "${FN_RESULT}"
cp "${DN_EXAMPLES}/transcode-test1-mp4.conf" "${DN_TOP}/etc/transcode.conf"

# 1.1.1 pic
rm -f "${DN_TOP}/data/input/"*
cp "${DN_EXAMPLES}/input-test1-pic.txt"      "${DN_TOP}/data/input/"
test_sh1_hadoop "1.1.1.pic2mp4"

# 1.1.2 mkv
rm -f "${DN_TOP}/data/input/"*
cp "${DN_EXAMPLES}/input-test1-mkv.txt"      "${DN_TOP}/data/input/"
test_sh1_hadoop "1.1.2.mkv2mp4"

# 1.1.3 pic+mkv
rm -f "${DN_TOP}/data/input/"*
cp "${DN_EXAMPLES}/input-test1-mkvpic.txt"    "${DN_TOP}/data/input/"
test_sh1_hadoop "1.1.3.picmkv2mp4"


# 1.2 webm
echo "--- to webm" >> "${FN_RESULT}"
cp "${DN_EXAMPLES}/transcode-test1-webm.conf" "${DN_TOP}/etc/transcode.conf"

# 1.2.1 pic
rm -f "${DN_TOP}/data/input/"*
cp "${DN_EXAMPLES}/input-test1-pic.txt"      "${DN_TOP}/data/input/"
test_sh1_hadoop "1.2.1.pic2mp4"

# 1.2.2 mkv
rm -f "${DN_TOP}/data/input/"*
cp "${DN_EXAMPLES}/input-test1-mkv.txt"      "${DN_TOP}/data/input/"
test_sh1_hadoop "1.2.2.mkv2mp4"

# 1.2.3 pic+mkv
rm -f "${DN_TOP}/data/input/"*
cp "${DN_EXAMPLES}/input-test1-mkvpic.txt"    "${DN_TOP}/data/input/"
test_sh1_hadoop "1.2.3.picmkv2mp4"

echo "===============" >> "${FN_RESULT}"

cat "${FN_RESULT}"

