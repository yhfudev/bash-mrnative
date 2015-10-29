#!/bin/bash
#####################################################################
# bash library
# the copy interfaces for various file systems, file://, hdfs:// etc.
#   cat_file
#   copy_file
#   move_file
#   is_file_or_dir
#   is_local
#   find_file
#   make_dir
#   rm_f_dir
#
# Copyright 2015 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################
mr_trace () {
    echo "$(date +"%Y-%m-%d %H:%M:%S,%N" | cut -c1-23) [self=${BASHPID},$(basename $0)] $@" 1>&2
}

is_local() {
    local PARAM_FN_INPUT=$1
    shift
    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && echo "r" && return
    [[ "${PARAM_FN_INPUT}" =~ ^sftp:// ]] && echo "r" && return
    [[ "${PARAM_FN_INPUT}" =~ ^file:// ]] && echo "l" && return
    echo "l"
}

#TODO:
#tail_file() {
#}

# save file from stdin
save_file() {
    local PARAM_FN_SAVE=$1
    shift
    [[ "${PARAM_FN_SAVE}" =~ ^hdfs:// ]] && hadoop fs -put - "${PARAM_FN_SAVE#hdfs://}" && return
    cat >> "${PARAM_FN_SAVE#file://}"
}

is_file_or_dir() {
    local PARAM_FN_INPUT=$1
    shift

    if [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] ; then
        local RET=$(hadoop fs -ls "${PARAM_FN_INPUT#hdfs://}" 2>&1 | awk 'BEGIN{f="n";}{if (match($0, "No such file or directory")) {f="e";} if (match($0, "Found")) {f="d";} if (f != "d") { if (/^-.*/) f="f"; } }END{print f;}')
        if [ "$RET" = "n" ]; then
            echo "d"
        else
            echo $RET
        fi
        return
    fi
    if [[ "${PARAM_FN_INPUT}" =~ ^file:// ]]; then
        PARAM_FN_INPUT="${PARAM_FN_INPUT#file://}"
    fi
    if [ -d "${PARAM_FN_INPUT}" ]; then
        echo "d"
        return
    fi
    if [ -f "${PARAM_FN_INPUT}" ]; then
        echo "f"
        return
    fi
    echo "e"
}

cat_file() {
    local PARAM_FN_INPUT=$1
    shift

    mr_trace "cat_file: input=${PARAM_FN_INPUT}"

    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && hadoop fs -cat "${PARAM_FN_INPUT#hdfs://}" && return
    [[ "${PARAM_FN_INPUT}" =~ ^http:// ]] && wget -qO /dev/null "${PARAM_FN_INPUT}" && return
    # curl sftp://username@hostname/path/to/file.txt
    # scp remotehost:/path/to/remote/file /dev/stdout
    #[[ "${PARAM_FN_INPUT}" =~ ^sftp:// ]] && curl "${PARAM_FN_INPUT}" && return
    #[[ "${PARAM_FN_INPUT}" =~ ^sftp:// ]] && scp "${PARAM_FN_INPUT#sftp://}" /dev/stdout && return

    mr_trace "cat_file: cat ${PARAM_FN_INPUT#file://}"
    cat "${PARAM_FN_INPUT#file://}"
}



myexec_ignore () {
    echo "[DBG] (skip) 6 $*" 1>&2
    local A=
    while [ ! "$1" = "" ]; do
        A="$A \"$1\""
        shift
    done
    echo "[DBG] (skip) 5 $A" 1>&2
}

# only support -name and -iname
find_file() {
    local PARAM_DN_SEARCH=$1
    shift

    local A=
    while [ ! "$1" = "" ]; do
        A="$A \"$1\""
        shift
    done

    [[ "${PARAM_DN_SEARCH}" =~ ^hdfs:// ]] && eval "hadoop fs -find \"${PARAM_DN_SEARCH#hdfs://}\" $A" | awk '{print "hdfs://" $0;}' && return
    # -maxdepth 1 -type f
    mr_trace "find_file: find ${PARAM_DN_SEARCH#file://} $A"
    #find "${PARAM_DN_SEARCH#file://}" $A
    A="find \"${PARAM_DN_SEARCH#file://}\" $A"
    eval $A
}

make_dir() {
    local PARAM_FN_INPUT=$1
    shift

    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && hadoop fs -mkdir -p "${PARAM_FN_INPUT#hdfs://}" && return
    mkdir -p "${PARAM_FN_INPUT#file://}"
}

rm_f_dir() {
    local PARAM_FN_INPUT=$1
    shift
    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && hadoop fs -rm -f -r "${PARAM_FN_INPUT#hdfs://}" && return
    rm -rf "${PARAM_FN_INPUT#file://}"
}

move_file() {
    local PARAM_FN_SRC=$1
    shift
    local PARAM_FN_DEST=$1
    shift

    if [[ "${PARAM_FN_SRC}" =~ ^hdfs:// ]]; then
        local IS_OK=0
        if [[ "${PARAM_FN_DEST}" =~ ^hdfs:// ]]; then
            hadoop fs -mv "${PARAM_FN_SRC#hdfs://}" "${PARAM_FN_DEST#hdfs://}"
            if [ "$?" = "0" ]; then
                IS_OK=1
            fi
        else
            local RET=$(is_local "${PARAM_FN_DEST}")
            if [ "${RET}" = "l" ]; then
                hadoop fs -get "${PARAM_FN_SRC#hdfs://}" "${PARAM_FN_DEST#file://}"
                if [ "$?" = "0" ]; then
                    IS_OK=1
                fi
            else
                local FNTMP1="/tmp/file-$(uuidgen)"
                hadoop fs -get "${PARAM_FN_SRC#hdfs://}" "${FNTMP1}"
                if [ "$?" = "0" ]; then
                    local RET=$(is_file_or_dir "${PARAM_FN_DEST}")
                    if [ "${RET}" = "d" ]; then
                        RET=$(move_file "${FNTMP1}" "${PARAM_FN_DEST}/$(basename ${PARAM_FN_SRC})")
                    else
                        RET=$(move_file "${FNTMP1}" "${PARAM_FN_DEST}")
                    fi
                    if [ "${RET}" = "0" ]; then
                        IS_OK=1
                    fi
                fi
            fi
            if [ "${IS_OK}" = "1" ]; then
                hadoop fs -rm -f -r "${PARAM_FN_SRC#hdfs://}"
            fi
        fi
        if [ "${IS_OK}" = "1" ]; then
            echo "0"
        else
            echo "1"
        fi
        return
    fi
    if [[ "${PARAM_FN_SRC}" =~ ^file:// ]]; then
        PARAM_FN_SRC="${PARAM_FN_SRC#file://}"
    fi
    if [[ "${PARAM_FN_DEST}" =~ ^hdfs:// ]]; then
        hadoop fs -put "${PARAM_FN_SRC}" "${PARAM_FN_DEST#hdfs://}"
        if [ "$?" = "0" ]; then
            rm -rf "${PARAM_FN_SRC}"
            echo "0"
        else
            echo "1"
        fi
        return
    fi
    if [[ "${PARAM_FN_DEST}" =~ ^file:// ]]; then
        PARAM_FN_DEST="${PARAM_FN_DEST#file://}"
    fi
    mv "${PARAM_FN_SRC}" "${PARAM_FN_DEST}"
    if [ "$?" = "0" ]; then
        echo "0"
    else
        echo "1"
    fi
}

copy_file() {
    local PARAM_FN_SRC=$1
    shift
    local PARAM_FN_DEST=$1
    shift

    if [[ "${PARAM_FN_SRC}" =~ ^hdfs:// ]]; then
        local IS_OK=0
        if [[ "${PARAM_FN_DEST}" =~ ^hdfs:// ]]; then
            hadoop fs -cp "${PARAM_FN_SRC#hdfs://}" "${PARAM_FN_DEST#hdfs://}"
            if [ "$?" = "0" ]; then
                IS_OK=1
            fi
        else
            local RET=$(is_local "${PARAM_FN_DEST}")
            if [ "${RET}" = "l" ]; then
                hadoop fs -get "${PARAM_FN_SRC#hdfs://}" "${PARAM_FN_DEST#file://}"
                if [ "$?" = "0" ]; then
                    IS_OK=1
                fi
            else
                local FNTMP1="/tmp/file-$(uuidgen)"
                hadoop fs -get "${PARAM_FN_SRC#hdfs://}" "${FNTMP1}"
                if [ "$?" = "0" ]; then
                    local RET=$(is_file_or_dir "${PARAM_FN_DEST}")
                    if [ "${RET}" = "d" ]; then
                        RET=$(move_file "${FNTMP1}" "${PARAM_FN_DEST}/$(basename ${PARAM_FN_SRC})")
                    else
                        RET=$(move_file "${FNTMP1}" "${PARAM_FN_DEST}")
                    fi
                    if [ "${RET}" = "0" ]; then
                        IS_OK=1
                    fi
                fi
            fi
        fi
        if [ "${IS_OK}" = "1" ]; then
            echo "0"
        else
            echo "1"
        fi
        return
    fi
    if [[ "${PARAM_FN_SRC}" =~ ^file:// ]]; then
        PARAM_FN_SRC="${PARAM_FN_SRC#file://}"
    fi
    if [[ "${PARAM_FN_DEST}" =~ ^hdfs:// ]]; then
        hadoop fs -put "${PARAM_FN_SRC}" "${PARAM_FN_DEST#hdfs://}"
        if [ "$?" = "0" ]; then
            echo "0"
        else
            echo "1"
        fi
        return
    fi
    if [[ "${PARAM_FN_DEST}" =~ ^file:// ]]; then
        PARAM_FN_DEST="${PARAM_FN_DEST#file://}"
    fi
    mr_trace "copy_file: cp -r ${PARAM_FN_SRC} ${PARAM_FN_DEST}"
    case ${PARAM_FN_SRC} in
    */)
        mr_trace "copy_file all: cp -r ${PARAM_FN_SRC}* ${PARAM_FN_DEST}"
        cp -r "${PARAM_FN_SRC}"* "${PARAM_FN_DEST}"
        ;;
    *)
        mr_trace "copy_file dir: cp -r ${PARAM_FN_SRC} ${PARAM_FN_DEST}"
        cp -r "${PARAM_FN_SRC}" "${PARAM_FN_DEST}"
        ;;
    esac
    if [ "$?" = "0" ]; then
        echo "0"
    else
        echo "1"
    fi
}

test_cases() {
    DEST="hdfs://a.gz"
    SRC="a.gz"
    SRC2="file://b.gz"
    SRC3="file://."

    # test is_file_or_dir()
    rm_f_dir "${SRC}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${SRC}")
    if [ ! "$RET" = "e" ]; then
        mr_trace "Error in is_file_or_dir ${SRC}, ret=$RET"
        exit 1
    else
        mr_trace "pass is_file_or_dir ${SRC}, ret=$RET"
    fi

    make_dir "${SRC}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${SRC}")
    if [ ! "$RET" = "d" ]; then
        mr_trace "Error in is_file_or_dir ${SRC}, ret=$RET"
        exit 1
    else
        mr_trace "pass make_dir, is_file_or_dir ${SRC}, ret=$RET"
    fi
    rm_f_dir "${SRC}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${SRC}")
    if [ ! "$RET" = "e" ]; then
        mr_trace "Error in rm_f_dir, is_file_or_dir ${SRC}, ret=$RET"
        exit 1
    else
        mr_trace "pass rm_f_dir, is_file_or_dir ${SRC}, ret=$RET"
    fi

    rm_f_dir "${DEST}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${DEST}")
    if [ ! "$RET" = "e" ]; then
        mr_trace "Error in is_file_or_dir ${DEST}, ret=$RET"
        exit 1
    else
        mr_trace "pass is_file_or_dir ${DEST}, ret=$RET"
    fi

    make_dir "${DEST}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${DEST}")
    if [ ! "$RET" = "d" ]; then
        mr_trace "Error in is_file_or_dir ${DEST}, ret=$RET"
        exit 1
    else
        mr_trace "pass make_dir, is_file_or_dir ${DEST}, ret=$RET"
    fi
    rm_f_dir "${DEST}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${DEST}")
    if [ ! "$RET" = "e" ]; then
        mr_trace "Error in rm_f_dir, is_file_or_dir ${DEST}, ret=$RET"
        exit 1
    else
        mr_trace "pass rm_f_dir, is_file_or_dir ${DEST}, ret=$RET"
    fi

    echo "abd" | gzip > "${SRC#file://}"
    RET=$(is_file_or_dir "${SRC}")
    if [ ! "$RET" = "f" ]; then
        mr_trace "Error in is_file_or_dir ${SRC}, ret=$RET"
        exit 1
    else
        mr_trace "pass is_file_or_dir ${SRC}, ret=$RET"
    fi

    rm_f_dir "${DEST}" >/dev/null 2>&1
    hadoop fs -mkdir -p "${DEST#hdfs://}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${DEST}")
    if [ ! "$RET" = "d" ]; then
        mr_trace "Error in is_file_or_dir ${DEST}, ret=$RET"
        exit 1
    else
        mr_trace "pass is_file_or_dir ${DEST}, ret=$RET"
    fi
    hadoop fs -rm -r -f "${DEST#hdfs://}" >/dev/null 2>&1

    # test copy_file()
    hadoop fs -rm -r -f "${DEST#hdfs://}" >/dev/null 2>&1
    copy_file "${SRC}" "${DEST}"
    RET=$(is_file_or_dir "${DEST}")
    if [ ! "$RET" = "f" ]; then
        mr_trace "Error in copy_file and is_file_or_dir ${DEST}, ret=$RET"
        exit 1
    else
        mr_trace "pass copy_file and is_file_or_dir ${DEST}, ret=$RET"
    fi

    rm -f "${SRC2#file://}"
    copy_file "${DEST}" "${SRC2}"
    RET=$(is_file_or_dir "${SRC2}")
    if [ ! "$RET" = "f" ]; then
        mr_trace "Error in copy_file and is_file_or_dir ${SRC2}, ret=$RET"
        exit 1
    else
        mr_trace "pass copy_file and is_file_or_dir ${SRC2}, ret=$RET"
    fi

    # test copy to dir
    rm -f "${DEST#hdfs://}"
    copy_file "${DEST}" "${SRC3}"
    RET=$(is_file_or_dir "${SRC3}")
    if [ ! "$RET" = "d" ]; then
        mr_trace "Error in copy_file and is_file_or_dir ${SRC3}, ret=$RET"
        exit 1
    else
        RET=$(is_file_or_dir "${SRC3#file://}/${DEST#hdfs://}")
        if [ ! "$RET" = "f" ]; then
            mr_trace "Error in copy_file and is_file_or_dir ${SRC3}, ret=$RET"
            exit 1
        else
            mr_trace "pass copy_file and is_file_or_dir ${SRC3}, ret=$RET"
        fi
    fi

    # test move_file()
    rm -f "${SRC2#file://}"
    move_file "${DEST}" "${SRC2}"
    RET=$(is_file_or_dir "${SRC2}")
    if [ ! "$RET" = "f" ]; then
        mr_trace "Error in move_file and is_file_or_dir ${SRC2}, ret=$RET"
        exit 1
    else
        RET=$(is_file_or_dir "${DEST}")
        if [ ! "$RET" = "e" ]; then
            mr_trace "Error in move_file and is_file_or_dir ${DEST}, ret=$RET"
            exit 1
        else
            mr_trace "pass copy_file and is_file_or_dir ${SRC2}, ret=$RET"
        fi
    fi

    hadoop fs -rm -f "${DEST#hdfs://}" >/dev/null 2>&1
    hadoop fs -rm -r -f "${DEST#hdfs://}" >/dev/null 2>&1
    move_file "${SRC2}" "${DEST}"
    RET=$(is_file_or_dir "${DEST}")
    if [ ! "$RET" = "f" ]; then
        mr_trace "Error in move_file and is_file_or_dir ${DEST}, ret=$RET"
        exit 1
    else
        RET=$(is_file_or_dir "${SRC2}")
        if [ ! "$RET" = "e" ]; then
            mr_trace "Error in move_file and is_file_or_dir ${SRC2}, ret=$RET"
            exit 1
        else
            mr_trace "pass copy_file and is_file_or_dir ${DEST}, ret=$RET"
        fi
    fi
}
#test_cases

test_func() {
    PARAM_A=$1
    shift
    PARAM_B=$1
    shift
    PARAM_C=$1
    shift
    while read a; do
        echo "($PARAM_A, $PARAM_B, $PARAM_C) $a"
    done
}

test_main1() {
case $1 in
*.gz)
    cat_file $1 | zcat | test_func "this" "is" "pramater"
    ;;
*)
    cat_file $1 | test_func "this" "is" "pramater"
    ;;
esac
}
