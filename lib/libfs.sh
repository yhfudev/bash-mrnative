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
#mr_trace () {
    #echo "$(date +"%Y-%m-%d %H:%M:%S,%N" | cut -c1-23) [self=${BASHPID},$(basename $0)] $@" 1>&2
#}

get_hdfs_url() {
    PORT=$(hdfs getconf -confKey fs.default.name | awk -F: '{print $3}')
    if [ ! "$PORT" = "" ]; then
        netstat -na | grep LISTEN | grep $PORT | awk '{print $4}'
    fi
}
HDFS_URL="hdfs://$(get_hdfs_url)/"

is_local() {
    local PARAM_FN_INPUT=$1
    shift
    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && echo "r" && return
    [[ "${PARAM_FN_INPUT}" =~ ^sftp:// ]] && echo "r" && return
    [[ "${PARAM_FN_INPUT}" =~ ^file:// ]] && echo "l" && return
    echo "l"
}

# show the tail of a text file
tail_file() {
    local PARAM_FN_INPUT=$1
    shift
    #[[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && hadoop fs -cat "${PARAM_FN_INPUT}" | awk 'BEGIN{str="";}{str=$0;}END{print str;}' && return
    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && hadoop fs -tail "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}" && return
    tail "${PARAM_FN_INPUT#file://}" $@
}

# save file from stdin
save_file() {
    local PARAM_FN_SAVE=$1
    shift
    [[ "${PARAM_FN_SAVE}" =~ ^hdfs:// ]] && hadoop fs -appendToFile - "${HDFS_URL}${PARAM_FN_SAVE#hdfs://}" && return
    cat - >> "${PARAM_FN_SAVE#file://}"
}

is_file_or_dir() {
    local PARAM_FN_INPUT=$1
    shift

    if [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] ; then
        E=$(which hadoop)
        if [ ! -x "${E}" ]; then
            mr_trace "not found hadoop in is_file_or_dir(), PATH=$PATH"
            echo "e"
            return
        fi
        mr_trace "check hdfs '${PARAM_FN_INPUT}' ..."
        local RET=$(hadoop fs -ls "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}" 2>&1 | awk 'BEGIN{f="n";}{if (match($0, "No such file or directory")) {f="e";} if (match($0, "Found")) {f="d";} if (f != "d") { if (/^-.*/) f="f"; } }END{print f;}')
        hadoop fs -ls "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}" 1>&2
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

chmod_file() {
    local OPT=
    local OTHERS=
    local MODE=
    while [ ! "$1" = "" ] ; do
        case $1 in
        -*)
            OPT="$OPT $1"
            ;;
        *)
            if [ "$MODE" = "" ] ; then
                MODE=$1
            else
                mr_trace "chown_file $OPT $MODE ${1}"
                if [[ "${1}" =~ ^hdfs:// ]] ; then
                    hadoop fs -chmod $OPT $MODE "${HDFS_URL}${1#hdfs://}"
                else
                    chmod $OPT $MODE "${1#file://}"
                fi
            fi
            ;;
        esac
        shift
    done
}

cat_file() {
    local PARAM_FN_INPUT=$1
    shift

    mr_trace "cat_file: input=${PARAM_FN_INPUT}"

    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && hadoop fs -cat "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}" && return
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

    if [[ "${PARAM_DN_SEARCH}" =~ ^hdfs:// ]] ; then
        eval "hadoop fs -find \"${HDFS_URL}${PARAM_DN_SEARCH#hdfs://}\" $A" | while read a; do echo "hdfs://${a#${HDFS_URL}}"; done
        return
    fi
    # -maxdepth 1 -type f
    mr_trace "find_file: find ${PARAM_DN_SEARCH#file://} $A"
    #find "${PARAM_DN_SEARCH#file://}" $A
    A="find \"${PARAM_DN_SEARCH#file://}\" $A"
    eval $A
}

make_dir() {
    local PARAM_FN_INPUT=$1
    shift

    if [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]]; then
        hadoop fs -mkdir -p "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}"
        echo $?
        return
    fi
    mkdir -p "${PARAM_FN_INPUT#file://}"
    echo $?
}

rm_f_dir() {
    local PARAM_FN_INPUT=$1
    shift

    mr_trace "del dir: ${PARAM_FN_INPUT} ..."
    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && hadoop fs -rm -f -r "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}" && return
    rm -rf "${PARAM_FN_INPUT#file://}"
}

# using rsync style of directory name:
#   if the path end with '/' then move the contents of that directory,
#   if the path end without '/' then move the directory.
move_file() {
    local PARAM_FN_SRC=$1
    shift
    local PARAM_FN_DEST=$1
    shift

    if [[ "${PARAM_FN_SRC}" =~ ^hdfs:// ]]; then
        local IS_OK=0
        if [[ "${PARAM_FN_DEST}" =~ ^hdfs:// ]]; then
            case ${PARAM_FN_SRC} in
            */)
                make_dir "${PARAM_FN_DEST}"
                hadoop fs -mv "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
                ;;
            *)
                hadoop fs -mv "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
                ;;
            esac
            if [ "$?" = "0" ]; then
                IS_OK=1
            fi
        else
            local RET=$(is_local "${PARAM_FN_DEST}")
            if [ "${RET}" = "l" ]; then
                case ${PARAM_FN_SRC} in
                */)
                    make_dir "${PARAM_FN_DEST#file://}"
                    hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${PARAM_FN_DEST#file://}"
                    ;;
                *)
                    hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${PARAM_FN_DEST#file://}"
                    ;;
                esac
                if [ "$?" = "0" ]; then
                    IS_OK=1
                fi
            else
                local FNTMP1="/tmp/file-$(uuidgen)"
                case ${PARAM_FN_SRC} in
                */)
                    make_dir "${FNTMP1}"
                    hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${FNTMP1}"
                    ;;
                *)
                    hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${FNTMP1}"
                    ;;
                esac
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
                hadoop fs -rm -f -r "${HDFS_URL}${PARAM_FN_SRC#hdfs://}"
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
        case ${PARAM_FN_SRC} in
        */)
            make_dir "${PARAM_FN_DEST}"
            hadoop fs -put -f "${PARAM_FN_SRC}*" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
            ;;
        *)
            hadoop fs -put -f "${PARAM_FN_SRC}" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
            ;;
        esac
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
    case ${PARAM_FN_SRC} in
    */)
        make_dir "${PARAM_FN_DEST}"
        mv "${PARAM_FN_SRC}*" "${PARAM_FN_DEST}"
        ;;
    *)
        mv "${PARAM_FN_SRC}" "${PARAM_FN_DEST}"
        ;;
    esac
    if [ "$?" = "0" ]; then
        echo "0"
    else
        echo "1"
    fi
}

# using rsync style of directory name:
#   if the path end with '/' then copy the contents of that directory,
#   if the path end without '/' then copy the directory.
copy_file() {
    local PARAM_FN_SRC=$1
    shift
    local PARAM_FN_DEST=$1
    shift

    local RET=0
    if [[ "${PARAM_FN_SRC}" =~ ^hdfs:// ]]; then
        local IS_OK=0
        if [[ "${PARAM_FN_DEST}" =~ ^hdfs:// ]]; then
            case ${PARAM_FN_SRC} in
            */)
                make_dir "${PARAM_FN_DEST}" >/dev/null 2>&1
                mr_trace hadoop fs -cp "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
                hadoop fs -cp "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
                ;;
            *)
                mr_trace hadoop fs -cp "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
                hadoop fs -cp "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
                ;;
            esac
            if [ "$?" = "0" ]; then
                IS_OK=1
            fi
        else
            local RET=$(is_local "${PARAM_FN_DEST}")
            if [ "${RET}" = "l" ]; then
                case ${PARAM_FN_SRC} in
                */)
                    make_dir "${PARAM_FN_DEST#file://}" >/dev/null 2>&1
                    hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${PARAM_FN_DEST#file://}"
                    ;;
                *)
                    hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${PARAM_FN_DEST#file://}"
                    ;;
                esac
                if [ "$?" = "0" ]; then
                    IS_OK=1
                fi
            else
                local FNTMP1="/tmp/file-$(uuidgen)"
                case ${PARAM_FN_SRC} in
                */)
                    make_dir "${FNTMP1}" >/dev/null 2>&1
                    hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${FNTMP1}"
                    ;;
                *)
                    hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${FNTMP1}"
                    ;;
                esac
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
        case ${PARAM_FN_SRC} in
        */)
            mr_trace "copy_file all: hdfs -put -f ${PARAM_FN_SRC#file://}* ${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
            hadoop fs -put -f "${PARAM_FN_SRC#file://}"* "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
            ;;
        *)
            mr_trace "copy_file dir: hdfs -put -f ${PARAM_FN_SRC#file://} ${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
            hadoop fs -put -f "${PARAM_FN_SRC#file://}" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
            ;;
        esac
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

# extract_file <compressed file> <destination dir>
extract_file () {
    local ARG_FN=$1
    shift
    local ARG_DN=$1
    shift

    local DN_TMP=
    local DN_DEST="${ARG_DN}"

    local RET=$(is_file_or_dir "${ARG_FN}")
    if [ ! "${RET}" = "f" ]; then
        mr_trace "Error: '${ARG_FN}' is not a file! ret=${RET}"
        return 1
    fi
    RET=$(is_local "${ARG_DN}")
    if [ ! "${RET}" = "l" ]; then
        mr_trace "use a temp dir"
        DN_TMP="/tmp/dir-$(uuidgen)"
        DN_DEST="${DN_TMP}"
    fi
    make_dir "${DN_DEST}" >/dev/null 2>&1
    DN_CUR=`pwd`
    FN_BASE=`echo "${FN_CUR}" | awk -F. '{name=$1; for (i=2; i < NF; i ++) name=name "." $i } END {print name}'`
    FLG_USE_SRCTMP=0
    case "${FN_CUR}" in
    *.rar)
        FLG_USE_SRCTMP=1
        ;;
    *.zip)
        FLG_USE_SRCTMP=1
        ;;
    *.deb)
        FLG_USE_SRCTMP=1
        ;;
    esac
    local FN_TMP=
    local FN_SRC="${ARG_FN}"
    if [ "${FLG_USE_SRCTMP}" = "1" ]; then
        RET=$(is_local "${ARG_FN}")
        if [ ! "${RET}" = "l" ]; then
            mr_trace "use a temp file"
            FN_TMP="/tmp/file-$(uuidgen)"
            FN_SRC="${FN_TMP}"
            copy_file "${ARG_FN}" "${FN_SRC}"
        fi
    fi
    case "${ARG_FN}" in
    *.tar.Z)
        mr_trace "extract (tar) ${DN_DIC}/${FN_CUR} ..."
        #compress -dc file.tar.Z | tar xvf -
        cat_file "${ARG_FN}" | tar -xvZ -C "${DN_DEST}"
        ;;
    *.tar.gz)
        mr_trace "extract (tar) ${DN_DIC}/${FN_CUR} ..."
        cat_file "${ARG_FN}" | tar -xvz -C "${DN_DEST}"
        ;;
    *.tar.bz2)
        mr_trace "extract (tar) ${DN_DIC}/${FN_CUR} ..."
        cat_file "${ARG_FN}" | tar -xvj -C "${DN_DEST}"
        ;;
    *.cpio.gz)
        mr_trace "extract (cpio) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        cat_file "${ARG_FN}" | gzip -dc | cpio -div
        cd "${DN_CUR}"
        ;;
    *.gz)
        mr_trace "extract (gunzip) ${DN_DIC}/${FN_CUR} ..."
        cat_file "${ARG_FN}" | gunzip -d -c | save_file "${DN_DIC}/${FN_BASE}"
        ;;
    *.bz2)
        echo "extract (bunzip2) ${DN_DIC}/${FN_CUR} ..."
        cat_file "${ARG_FN}" | bunzip2 -d -c | save_file "${DN_DIC}/${FN_BASE}"
        ;;
    *.rpm)
        echo "extract (rpm) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        cat_file "${ARG_FN}" | rpm2cpio - | cpio -div
        cd "${DN_CUR}"
        ;;
    *.rar)
        mr_trace "extract (unrar) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        unrar x -o+ "${FN_SRC}"
        cd "${DN_CUR}"
        ;;
    *.zip)
        echo "extract (unzip) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        unzip "${FN_SRC}"
        cd "${DN_CUR}"
        ;;
    *.deb)
        # ar xv "${FN_CUR}" && tar -xf data.tar.gz
        echo "extract (dpkg) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        dpkg -x "${FN_SRC}" .
        cd "${DN_CUR}"
        ;;
    *.dz)
        echo "extract (dictzip) ${DN_DIC}/${FN_CUR} ..."
        cat_file "${ARG_FN}" | dictzip -d -c | save_file "${FN_BASE}"
        ;;
    *.Z)
        echo "extract (uncompress) ${DN_DIC}/${FN_CUR} ..."
        cat_file "${ARG_FN}" | gunzip -d -c | save_file "${FN_BASE}"
        ;;
    *.a)
        echo "extract (tar) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        cat_file "${ARG_FN}" | tar -xv -C "${DN_DEST}"
        ;;
    *.tgz)
        echo "extract (tar) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        cat_file "${ARG_FN}" | tar -xz -C "${DN_DEST}"
        cd "${DN_CUR}"
        ;;
    *.tbz)
        echo "extract (tar) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        cat_file "${ARG_FN}" | tar -xj -C "${DN_DEST}"
        cd "${DN_CUR}"
        ;;
    *.cgz)
        echo "extract (cpio) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        cat_file "${ARG_FN}" | gzip -dc | cpio -div
        cd "${DN_CUR}"
        ;;
    *.cpio)
        echo "extract (cpio) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        cat_file "${ARG_FN}" | cpio -div
        cd "${DN_CUR}"
        ;;
    *)
        #echo "skip ${DN_DIC}/${FN_CUR} ..."
        ;;
    esac

    if [ ! "${DN_TMP}" = "" ]; then
        copy_file "${DN_TMP}/" "${ARG_DN}" >/dev/null 2>&1
        rm -r -f "${DN_TMP}"
    fi
    if [ ! "${FN_TMP}" = "" ]; then
        rm -f "${FN_TMP}"
    fi
    return 0;
}

test_cases() {
    DEST="hdfs:///a.gz"
    SRC="a.gz"
    SRC2="file://b.gz"
    SRC3="file://./"

    # test is_file_or_dir()
    rm_f_dir "${SRC}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${SRC}")
    if [ ! "$RET" = "e" ]; then
        mr_trace "Error in rmdir,is_file_or_dir ${SRC}, ret=$RET"
        exit 1
    else
        mr_trace "pass rmdir,is_file_or_dir ${SRC}, ret=$RET"
    fi

    make_dir "${SRC}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${SRC}")
    if [ ! "$RET" = "d" ]; then
        mr_trace "Error in make_dir, is_file_or_dir ${SRC}, ret=$RET"
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
        mr_trace "Error in rmdir,is_file_or_dir ${DEST}, ret=$RET"
        exit 1
    else
        mr_trace "pass rmdir,is_file_or_dir ${DEST}, ret=$RET"
    fi

    make_dir "${DEST}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${DEST}")
    if [ ! "$RET" = "d" ]; then
        mr_trace "Error in mkdir,is_file_or_dir ${DEST}, ret=$RET"
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
    hadoop fs -mkdir -p "${DEST}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${DEST}")
    if [ ! "$RET" = "d" ]; then
        mr_trace "Error in is_file_or_dir ${DEST}, ret=$RET"
        exit 1
    else
        mr_trace "pass is_file_or_dir ${DEST}, ret=$RET"
    fi
    hadoop fs -rm -r -f "${DEST}" >/dev/null 2>&1

    # test copy_file()
    hadoop fs -rm -r -f "${DEST}" >/dev/null 2>&1
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

    hadoop fs -rm -f "${DEST}" >/dev/null 2>&1
    hadoop fs -rm -r -f "${DEST}" >/dev/null 2>&1
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

# debug
if [ 0 = 1 ]; then
test_cases
fi

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

