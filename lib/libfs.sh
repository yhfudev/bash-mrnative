#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief bash library
##
## the copy interfaces for various file systems, file://, hdfs:// etc.
##   cat_file
##   copy_file
##   move_file
##   is_file_or_dir
##   is_local
##   find_file
##   make_dir
##   rm_f_dir
## @author Yunhui Fu <yhfudev@gmail.com>
## @copyright GPL v3.0 or later
## @version 1
##
#####################################################################

## @fn get_hdfs_url()
## @brief detect HDFS port
##
## the global environment variable HADOOP_CONF_DIR should be used when possible
get_hdfs_url() {
    if [ -d "${HADOOP_CONF_DIR}" ]; then
        local A=$(grep -A 1 fs.defaultFS "${HADOOP_CONF_DIR}/core-site.xml" | grep "<value>" | awk -F\> '{print $2}' | awk -F\< '{print $1}' | awk -F/ '{print $3}')
        echo $A
        mr_trace "use HADOOP_CONF_DIR=${HADOOP_CONF_DIR}, got HDFS_URL=hdfs://$(A)"

    else
        if which hdfs > /dev/null ; then
            local PORT=$(hdfs getconf -confKey fs.defaultFS | awk -F: '{print $3}')
            #mr_trace "hdfs port=${PORT}"
            if [ ! "$PORT" = "" ]; then
                local A=$(netstat -na | grep LISTEN | grep $PORT | awk '{print $4}')
                mr_trace "use hdfs=$(which hdfs), got HDFS_URL=hdfs://$(A)"
            fi
        else
            mr_trace "Not found hdfs, unable to set HDFS_URL!"
        fi
    fi
}
HDFS_URL="hdfs://$(get_hdfs_url)"

## @fn convert_filename()
## @brief convert the file name to its absolute path
## @param FN_PREFIX the prefix of new path
## @param FN_INPUT the file name
##
## for example:
##   /path/to/file1  -->  /path/to/file1
##   file:///path/to/file2   -->  file:///path/to/file2
##   path/to/file2   -->  ${DN_EXEC}/input/path/to/file2
##   file://path/to/file2   -->  ${DN_EXEC}/input/path/to/file2
convert_filename() {
    local PARAM_FN_PREFIX=$1
    shift
    local PARAM_FN_INPUT=$1
    shift

    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && echo "r" && return
    [[ "${PARAM_FN_INPUT}" =~ ^sftp:// ]] && echo "r" && return

    if [[ "${PARAM_FN_INPUT}" =~ ^file:// ]]; then
        PARAM_FN_INPUT="${PARAM_FN_INPUT#file://}"
    fi
    if [[ "${PARAM_FN_INPUT#file://}" =~ ^/ ]]; then
        echo "${PARAM_FN_INPUT}"
    else
        echo "file://${PARAM_FN_PREFIX}/${PARAM_FN_INPUT#file://}"
    fi
}

## @fn is_local()
## @brief check if a file is a local file or not
## @param fn the file name
##
## @return 'l' if it is local file, 'r' for remote file
is_local() {
    local PARAM_FN_INPUT=$1
    shift
    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && echo "r" && return
    [[ "${PARAM_FN_INPUT}" =~ ^sftp:// ]] && echo "r" && return
    [[ "${PARAM_FN_INPUT}" =~ ^file:// ]] && echo "l" && return
    echo "l"
}

## @fn tail_file()
## @brief show the tail of a text file
## @param fn the file name
##
tail_file() {
    local PARAM_FN_INPUT=$1
    shift
    HDFS_URL="hdfs://$(get_hdfs_url)"
    #[[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && hadoop fs -cat "${PARAM_FN_INPUT}" | awk 'BEGIN{str="";}{str=$0;}END{print str;}' && return
    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && $MYEXEC hadoop fs -tail "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}" && return
    tail "${PARAM_FN_INPUT#file://}" $@
}

## @fn save_file()
## @brief save file from stdin
## @param fn the file name
##
save_file() {
    local PARAM_FN_SAVE=$1
    shift
    HDFS_URL="hdfs://$(get_hdfs_url)"
    [[ "${PARAM_FN_SAVE}" =~ ^hdfs:// ]] && $MYEXEC hadoop fs -appendToFile - "${HDFS_URL}${PARAM_FN_SAVE#hdfs://}" && return
    cat - >> "${PARAM_FN_SAVE#file://}"
}

## @fn is_file_or_dir()
## @brief check file type
## @param fn the file name
##
## @return 'e' if it is execuatable, 'f' for normal file, 'd' for directory
is_file_or_dir() {
    local PARAM_FN_INPUT=$1
    shift

    if [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] ; then
        E=$(which hadoop)
        if [ ! -x "${E}" ]; then
            mr_trace "not found hadoop in is_file_or_dir(), E=$E; PATH=$PATH"
            echo "e"
            return
        fi
        mr_trace "check hdfs '${PARAM_FN_INPUT}' ..."
        HDFS_URL="hdfs://$(get_hdfs_url)"
        mr_trace hadoop fs -ls "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}"
        local RET=$(hadoop fs -ls "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}" 2>&1 | awk 'BEGIN{f="n";}{if (match($0, "No such file or directory")) {f="e";} if (match($0, "Found")) {f="d";} if (f != "d") { if (/^-.*/) f="f"; } }END{print f;}')
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

## @fn chmod_file()
## @brief set the mode of a file
## @param fn the file name
##
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
                if [[ "${1}" =~ ^hdfs:// ]] ; then
                    HDFS_URL="hdfs://$(get_hdfs_url)"
                    $MYEXEC hadoop fs -chmod $OPT $MODE "${HDFS_URL}${1#hdfs://}"
                else
                    $MYEXEC chmod $OPT $MODE "${1#file://}"
                fi
            fi
            ;;
        esac
        shift
    done
}

## @fn cat_file()
## @brief output the content of a file to stdout
## @param fn the file name
cat_file() {
    local PARAM_FN_INPUT=$1
    shift

    HDFS_URL="hdfs://$(get_hdfs_url)"
    mr_trace "cat_file: input=${PARAM_FN_INPUT}"

    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && $MYEXEC hadoop fs -cat "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}" && return
    [[ "${PARAM_FN_INPUT}" =~ ^http:// ]] && $MYEXEC wget -qO /dev/null "${PARAM_FN_INPUT}" && return
    # curl sftp://username@hostname/path/to/file.txt
    # scp remotehost:/path/to/remote/file /dev/stdout
    #[[ "${PARAM_FN_INPUT}" =~ ^sftp:// ]] && $MYEXEC curl "${PARAM_FN_INPUT}" && return
    #[[ "${PARAM_FN_INPUT}" =~ ^sftp:// ]] && $MYEXEC scp "${PARAM_FN_INPUT#sftp://}" /dev/stdout && return

    $MYEXEC cat "${PARAM_FN_INPUT#file://}"
}

## @fn find_file()
## @brief find files by pattern
## @param fn the file name
##
## only support -name and -iname
find_file() {
    local PARAM_DN_SEARCH=$1
    shift

    local A=
    while [ ! "$1" = "" ]; do
        case $1 in
        -maxdepth)
            shift
            if [[ ! "${PARAM_DN_SEARCH}" =~ ^hdfs:// ]] ; then
                A="$A -maxdepth \"$1\""
            fi
            ;;
        *)
            A="$A \"$1\""
            ;;
        esac
        shift
    done

    mr_trace "PARAM_DN_SEARCH=${PARAM_DN_SEARCH}"
    if [[ "${PARAM_DN_SEARCH}" =~ ^hdfs:// ]] ; then
        if which hadoop > /dev/null ; then
            HDFS_URL="hdfs://$(get_hdfs_url)"
            eval "hadoop fs -find \"${HDFS_URL}${PARAM_DN_SEARCH#hdfs://}\" $A" | while read a; do echo "hdfs://${a#${HDFS_URL}}"; done
        fi
        return
    fi
    # -maxdepth 1 -type f
    mr_trace "find_file: find ${PARAM_DN_SEARCH#file://} $A"
    #find "${PARAM_DN_SEARCH#file://}" $A
    A="find \"${PARAM_DN_SEARCH#file://}\" $A"
    eval $A
}

## @fn make_dir()
## @brief create a directory
## @param fn the file name
make_dir() {
    local PARAM_FN_INPUT=$1
    shift

    if [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]]; then
        HDFS_URL="hdfs://$(get_hdfs_url)"
        mr_trace "HDFS_URL=${HDFS_URL}"
        $MYEXEC hadoop fs -mkdir -p "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}"
        echo $?
        return
    fi
    $MYEXEC mkdir -p "${PARAM_FN_INPUT#file://}"
    echo $?
}

rm_f_dir0() {
    local PARAM_FN_INPUT=$1
    shift

    HDFS_URL="hdfs://$(get_hdfs_url)"
    mr_trace "del dir: ${PARAM_FN_INPUT} ..."

    # original code:
    [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && $MYEXEC hadoop fs -rm -f -r "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}" && return
    $MYEXEC rm -rf "${PARAM_FN_INPUT#file://}"
}

## @fn rm_f_dir()
## @brief remove files
## @param fn the file name
rm_f_dir() {
    local PARAM_FN_INPUT=$1
    shift

    mr_trace "del dir: ${PARAM_FN_INPUT} ..."

    # original code:
    #[[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] && $MYEXEC hadoop fs -rm -f -r "${HDFS_URL}${PARAM_FN_INPUT#hdfs://}" && return
    #$MYEXEC rm -rf "${PARAM_FN_INPUT#file://}"

    local DN1=$(dirname "${PARAM_FN_INPUT}")
    if [[ "${DN1}" =~ ":" ]] ; then
        if [[ "${PARAM_FN_INPUT}" =~ ^file:// ]] ; then
            DN1=$(echo $DN1 | awk -F: '{print $2}')
        fi
    fi
    if [ "${DN1}" = "" ]; then
        DN1=.
    fi
    # debug code:
    find_file "${DN1}" -maxdepth 1 -name "$(basename "${PARAM_FN_INPUT}")" | while read a; do \
        #mr_trace "process: ${a} ..."
        if [[ "${PARAM_FN_INPUT}" =~ ^hdfs:// ]] ; then \
            HDFS_URL="hdfs://$(get_hdfs_url)"
            $MYEXEC hadoop fs -rm -f -r "${HDFS_URL}${a#hdfs://}" ; \
        else \
            $MYEXEC rm -rf "${a#file://}" ; \
        fi; \
    done
}

## @fn move_file()
## @brief remove files
## @param fn_src the source file name
## @param fn_dest the target file name
##
## using rsync style of directory name:
##   if the path end with '/' then move the contents of that directory,
##   if the path end without '/' then move the directory.
move_file() {
    local PARAM_FN_SRC=$1
    shift
    local PARAM_FN_DEST=$1
    shift

    HDFS_URL="hdfs://$(get_hdfs_url)"
    if [[ "${PARAM_FN_SRC}" =~ ^hdfs:// ]]; then
        local IS_OK=0
        if [[ "${PARAM_FN_DEST}" =~ ^hdfs:// ]]; then
            case ${PARAM_FN_SRC} in
            */)
                make_dir "${PARAM_FN_DEST}"
                $MYEXEC hadoop fs -mv "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
                ;;
            *)
                $MYEXEC hadoop fs -mv "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
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
                    $MYEXEC hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${PARAM_FN_DEST#file://}"
                    ;;
                *)
                    $MYEXEC hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${PARAM_FN_DEST#file://}"
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
                    $MYEXEC hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${FNTMP1}"
                    ;;
                *)
                    $MYEXEC hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${FNTMP1}"
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
                $MYEXEC hadoop fs -rm -f -r "${HDFS_URL}${PARAM_FN_SRC#hdfs://}"
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
            $MYEXEC hadoop fs -put -f "${PARAM_FN_SRC}*" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
            ;;
        *)
            $MYEXEC hadoop fs -put -f "${PARAM_FN_SRC}" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
            ;;
        esac
        if [ "$?" = "0" ]; then
            $MYEXEC rm -rf "${PARAM_FN_SRC}"
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
        $MYEXEC mv "${PARAM_FN_SRC}*" "${PARAM_FN_DEST}"
        ;;
    *)
        $MYEXEC mv "${PARAM_FN_SRC}" "${PARAM_FN_DEST}"
        ;;
    esac
    if [ "$?" = "0" ]; then
        echo "0"
    else
        echo "1"
    fi
}

## @fn copy_file()
## @brief copy files
## @param fn_src the source file name
## @param fn_dest the target file name
##
## using rsync style of directory name:
##   if the path end with '/' then copy the contents of that directory,
##   if the path end without '/' then copy the directory.
copy_file() {
    local PARAM_FN_SRC=$1
    shift
    local PARAM_FN_DEST=$1
    shift

    HDFS_URL="hdfs://$(get_hdfs_url)"
    local RET=0
    if [[ "${PARAM_FN_SRC}" =~ ^hdfs:// ]]; then
        local IS_OK=0
        if [[ "${PARAM_FN_DEST}" =~ ^hdfs:// ]]; then
            case ${PARAM_FN_SRC} in
            */)
                make_dir "${PARAM_FN_DEST}" >/dev/null 2>&1
                $MYEXEC hadoop fs -cp "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
                ;;
            *)
                $MYEXEC hadoop fs -cp "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
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
                    $MYEXEC hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${PARAM_FN_DEST#file://}"
                    ;;
                *)
                    $MYEXEC hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${PARAM_FN_DEST#file://}"
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
                    $MYEXEC hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}*" "${FNTMP1}"
                    ;;
                *)
                    $MYEXEC hadoop fs -get "${HDFS_URL}${PARAM_FN_SRC#hdfs://}" "${FNTMP1}"
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
            $MYEXEC hadoop fs -put -f "${PARAM_FN_SRC#file://}"* "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
            ;;
        *)
            $MYEXEC hadoop fs -put -f "${PARAM_FN_SRC#file://}" "${HDFS_URL}${PARAM_FN_DEST#hdfs://}"
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
        $MYEXEC cp -r "${PARAM_FN_SRC}"* "${PARAM_FN_DEST}"
        ;;
    *)
        $MYEXEC cp -r "${PARAM_FN_SRC}" "${PARAM_FN_DEST}"
        ;;
    esac
    if [ "$?" = "0" ]; then
        echo "0"
    else
        echo "1"
    fi
}

## @fn extract_file()
## @brief extract files from a file
## @param fn the source file name
## @param dn the target directory
##
extract_file() {
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
        $MYEXEC unrar x -o+ "${FN_SRC}"
        cd "${DN_CUR}"
        ;;
    *.zip)
        echo "extract (unzip) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        $MYEXEC unzip "${FN_SRC}"
        cd "${DN_CUR}"
        ;;
    *.deb)
        # ar xv "${FN_CUR}" && tar -xf data.tar.gz
        echo "extract (dpkg) ${DN_DIC}/${FN_CUR} ..."
        cd "${DN_DEST}"
        $MYEXEC dpkg -x "${FN_SRC}" .
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
        $MYEXEC rm -r -f "${DN_TMP}"
    fi
    if [ ! "${FN_TMP}" = "" ]; then
        $MYEXEC rm -f "${FN_TMP}"
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
    $MYEXEC hadoop fs -mkdir -p "${DEST}" >/dev/null 2>&1
    RET=$(is_file_or_dir "${DEST}")
    if [ ! "$RET" = "d" ]; then
        mr_trace "Error in is_file_or_dir ${DEST}, ret=$RET"
        exit 1
    else
        mr_trace "pass is_file_or_dir ${DEST}, ret=$RET"
    fi
    $MYEXEC hadoop fs -rm -r -f "${DEST}" >/dev/null 2>&1

    # test copy_file()
    $MYEXEC hadoop fs -rm -r -f "${DEST}" >/dev/null 2>&1
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
    $MYEXEC rm -f "${DEST#hdfs://}"
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
    $MYEXEC rm -f "${SRC2#file://}"
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

    $MYEXEC hadoop fs -rm -f "${DEST}" >/dev/null 2>&1
    $MYEXEC hadoop fs -rm -r -f "${DEST}" >/dev/null 2>&1
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

