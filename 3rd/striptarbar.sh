#!/bin/bash

MYROUND=0
MYCNT=0
backup_midfile() {
    local PARAM_FN=$1
    shift
    PREFIX1=$(echo | awk -v MYROUND=$MYROUND -v MYCNT=$MYCNT '{printf("%03d-%03d", MYROUND, MYCNT);}' )
    echo "-- backup ${PARAM_FN} TO ${PREFIX1}-${PARAM_FN}"
    cp "${PARAM_FN}" "${PREFIX1}-${PARAM_FN}"
    MYCNT=$(( $MYCNT + 1 ))
}

generate_lib_list () {
    local PARAM_DN_FIND=$1
    shift
    local PARAM_FN_BIN_LIST=$1
    shift
    local PARAM_FN_OUT_LIST=$1
    shift

    local FN_SYMBOL="tmp-symbols.txt"
    local FN_MID="tmp-mid1.txt"
    local FN_MID2="tmp-mid2.txt"
    local FN_NEW="tmp-new2.txt"

    local FN_DIR="tmp-dirs.txt"
    rm -f $FN_SYMBOL $FN_MID $FN_MID2 $FN_NEW $FN_DIR

    cat "${PARAM_FN_BIN_LIST}" | while read a ; do
        if [ -d "$a" ]; then
            find "${a}/" | while read b; do
                if [ ! -d "${b}" ]; then
                    echo $b >> "${FN_DIR}"
                fi
            done
        else
            echo $a >> "${FN_NEW}"
        fi
    done
    cp "${FN_NEW}" "${PARAM_FN_OUT_LIST}"

    backup_midfile "${FN_NEW}"

    touch "${PARAM_FN_OUT_LIST}"
    rm -f "${FN_SYMBOL}"
    touch "${FN_SYMBOL}"
    while [ 1 = 1 ]; do
        echo "----- Round $MYROUND ----"

        backup_midfile "${FN_SYMBOL}"
        rm -f "${FN_MID}"
        touch "${FN_MID}"
        cat "${FN_NEW}" | while read a; do
            echo "read symbol: $a ..."
            # objdump -x "binary" | grep NEEDED
            readelf -d "${a}" | grep NEEDED | awk -F[ '{print $2}' | awk -F] '{print $1}' | grep -v -x -f "${FN_SYMBOL}" >> "${FN_MID}"
        done
        if [[ `wc -l "${FN_MID}" | awk '{print $1}'` < 1 ]] ; then
            break;
        fi
        backup_midfile "${FN_MID}"
        cat "${FN_MID}" | sort | uniq | grep '[^[:blank:]]' > "${FN_MID2}"
        if [[ `wc -l "${FN_MID2}" | awk '{print $1}'` < 1 ]] ; then
            break;
        fi
        backup_midfile "${FN_MID2}"
        rm -f "${FN_MID}" "${FN_SYMBOL}" "${FN_NEW}"
        touch "${FN_MID}" "${FN_SYMBOL}"
        cat "${FN_MID2}" | while read a ; do
            echo find "${PARAM_DN_FIND}/" -name ${a}
            FN=$(find "${PARAM_DN_FIND}/" -name ${a} | sort | head -n 1)
            if [ "$FN" = "" ]; then
                echo $a >> "${FN_SYMBOL}"
            else
                echo $FN >> "${FN_MID}"
            fi
        done
        if [[ `wc -l "${FN_MID}" | awk '{print $1}'` < 1 ]] ; then
            break;
        fi
        backup_midfile "${FN_MID}"
        cp "${FN_MID}" "${FN_NEW}"
        cat "${PARAM_FN_OUT_LIST}" >> "${FN_MID}"
        cat "${FN_MID}" | sort | uniq | grep '[^[:blank:]]' > "${PARAM_FN_OUT_LIST}"
        backup_midfile "${PARAM_FN_OUT_LIST}"
        cat "${PARAM_FN_OUT_LIST}" | awk -F/ '{print $NF}' | sort | uniq | grep '[^[:blank:]]' >> "${FN_SYMBOL}"
        backup_midfile "${FN_SYMBOL}"

        MYROUND=$(( $MYROUND + 1 ))
    done

    rm -f "${FN_SYMBOL}"
    touch "${FN_SYMBOL}"
    rm -f "${FN_MID}"
    touch "${FN_MID}"
    rm -f "${FN_MID2}"
    touch "${FN_MID2}"
    cat "${PARAM_FN_OUT_LIST}" | while read a ; do
        #echo find "$(dirname $a)/" -name "$(basename $a)*"
        #find "$(dirname $a)/" -name "$(basename $a)*" >> "${FN_LIST}"
        ls ${a}* >> "${FN_MID}"
        readlink ${a} >> "${FN_MID2}"
    done
    cat "${FN_MID2}" | while read a ; do
        FN=$(find "${PARAM_DN_FIND}/" -name $a | sort | head -n 1)
        if [ "$FN" = "" ]; then
            echo $a >> "${FN_SYMBOL}"
        else
            echo $FN >> "${FN_MID}"
        fi
    done
    cat "${FN_DIR}" >> "${FN_MID}"
    cat "${FN_MID}" | sort | uniq | grep '[^[:blank:]]' > "${PARAM_FN_OUT_LIST}"

    rm -f $FN_SYMBOL $FN_MID $FN_MID2 $FN_NEW $FN_DIR
}

create_exec_release() {
    local PARAM_DN_LIB=$1
    shift
    local PARAM_FN_INPUT=$1
    shift
    local PARAM_FN_OUT_TAR=$1
    shift

    local FN_LIST="tmp-${PARAM_FN_INPUT}"
    rm -f "${FN_LIST}" "${PARAM_FN_OUT_TAR}"

    echo "generating file list ${FN_LIST} for ${PARAM_FN_INPUT} ..."
    echo generate_lib_list "${PARAM_DN_LIB}" "${PARAM_FN_INPUT}" "${FN_LIST}"
    generate_lib_list "${PARAM_DN_LIB}" "${PARAM_FN_INPUT}" "${FN_LIST}"

    echo "compress tar file ${PARAM_FN_OUT_TAR} by ${FN_LIST} ..."
    tar -cvzf "${PARAM_FN_OUT_TAR}" -T "${FN_LIST}"
}

FN_INPUT="$1"
DN_LIB="$2"
FN_OUTPUT="$3"

if [ "${FN_OUTPUT}" = "" ]; then
    # test:
    echo "Warning: testing ..."
    FN_INPUT="input.txt"
    DN_LIB="ffmpeg-bin"
    FN_OUTPUT="ffmpeg-bin.tar.gz"

    rm -f "${FN_INPUT}"
    echo "ffmpeg-bin/usr/include" >> "${FN_INPUT}"
    echo "ffmpeg-bin/usr/bin/ffmpeg" >> "${FN_INPUT}"
    echo "ffmpeg-bin/usr/bin/MP4Box" >> "${FN_INPUT}"
    echo "ffmpeg-bin/usr/bin/mediametrics" >> "${FN_INPUT}"
    #echo "ns2-bin/usr/bin/ns" >> "${FN_INPUT}"
    #echo "ns2-bin/usr/bin/gawk" >> "${FN_INPUT}"
    #echo "ns2-bin/usr/bin/gnuplot" >> "${FN_INPUT}"
fi

create_exec_release "${DN_LIB}" "${FN_INPUT}" "${FN_OUTPUT}"

echo "DONE!"
