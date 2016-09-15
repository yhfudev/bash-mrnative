#!/bin/bash
#####################################################################
# Multimedia Transcoding Using Map/Reduce Paradigm -- Step 1 Map part
#
# In this part, the script check the file name format, and
# collect all of the files to be processed and send it to output.
#
# Copyright 2014 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################
my_getpath () {
    local PARAM_DN="$1"
    shift
    #readlink -f
    local DN="${PARAM_DN}"
    local FN=
    if [ ! -d "${DN}" ]; then
        FN=$(basename "${DN}")
        DN=$(dirname "${DN}")
    fi
    local DNORIG=$(pwd)
    cd "${DN}" > /dev/null 2>&1
    DN=$(pwd)
    cd "${DNORIG}"
    if [ "${FN}" = "" ]; then
        echo "${DN}"
    else
        echo "${DN}/${FN}"
    fi
}
#DN_EXEC=`echo "$0" | ${EXEC_AWK} -F/ '{b=$1; for (i=2; i < NF; i ++) {b=b "/" $(i)}; print b}'`
DN_EXEC=$(dirname $(my_getpath "$0") )
if [ ! "${DN_EXEC}" = "" ]; then
    DN_EXEC="$(my_getpath "${DN_EXEC}")/"
else
    DN_EXEC="${DN_EXEC}/"
fi
DN_TOP="$(my_getpath "${DN_EXEC}/../")"
DN_BIN="$(my_getpath "${DN_TOP}/bin/")"
DN_EXEC="$(my_getpath ".")"

#####################################################################
if [ -f "${DN_EXEC}/liball.sh" ]; then
. ${DN_EXEC}/liball.sh
fi

#####################################################################
# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

# extract the mrnative, include the files in app-ns2/common which are used in setting ns2 TCL scripts
libapp_prepare_mrnative_binary

#####################################################################
create_snapshot () {
    local PARAM_FN_MP4=$1
    shift

    # 把视频的前３０帧转换成一个Animated Gif ：
    #${EXEC_FFMPEG} -i "${FN_MP4}" -vframes 30 -y -f gif a.gif

    FN_BASE=$(echo "${PARAM_FN_MP4}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')

    SEC_LENGTH=$(mplayer -identify -nosound -vc dummy -vo null "${PARAM_FN_MP4}" | grep ID_LENGTH | sed -r 's/ID_LENGTH=([[:digit:]]*)(.[[:digit:]]*)?/\1/g')

    NUM=6
    CNT=0
    NEXT=7

    STEP=$(expr \( $SEC_LENGTH - ${NEXT} - ${NEXT} \) / $NUM)
    while [ $(echo | ${EXEC_AWK} -v CUR=${CNT} -v MAX=${NUM} '{if (CUR < MAX) {print 1} else {print 0}}') = 1 ]; do
        # 从时间 NEXT 处截取 320*180 的缩略图
        $MYEXEC ${EXEC_FFMPEG} ${OPTIONS_FFM_ASYNC} -i "${PARAM_FN_MP4}" -y -f mjpeg -ss $NEXT -t 0.001 -s 320x180 "${FN_BASE}-snaptmp${CNT}.jpg"
        NEXT=$(expr $NEXT + $STEP)
        CNT=$(expr $CNT + 1)
    done

    # 使用 imagemagick 中的montage命令合并图片，-geometry +0+0是设定使用原始图片大小，-tile 2参数设定每行放2张图片
    $MYEXEC montage -geometry +0+0 -tile 2 "${FN_BASE}-snaptmp*.jpg" "${FN_BASE}-snap.jpg"
    $MYEXEC rm -f ${FN_BASE}-snaptmp*.jpg
}

#####################################################################
# split .mkv file to segments
# variable DN_DATATMP should be set before call this function
worker_mkv_split () {
    local PARAM_SESSION_ID="$1"
    shift
    local PARAM_AUDIO_FILE="$1"
    shift
    local PARAM_VIDEO_FILE="$1"
    shift
    local PARAM_SEGSEC="$1"
    shift

    DN_TMP="${DN_DATATMP}/worker-$(uuidgen)"
    ${MYEXEC} mkdir -p "${DN_TMP}" 1>&2
    ${MYEXEC} cd "${DN_TMP}" 1>&2

    FN_BASE=$(echo "${PARAM_VIDEO_FILE}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
    FN_SUFFIX=$(echo "${PARAM_VIDEO_FILE}" | ${EXEC_AWK} -F. '{print $NF }')
    FN_INPUT_VIDEO="${PARAM_VIDEO_FILE}"
    FN_INPUT_AUDIO="${PARAM_AUDIO_FILE}"

    PREFIX0=$(basename "${FN_BASE}" )
    PREFIX1=$(generate_prefix_from_filename "${PREFIX0}" )
    #PREFIX2=$(echo "${PREFIX1}" | ${EXEC_AWK} -F% '{match($2,"[0-9]*d(.*)",b);print $1 b[1];}' )
    PREFIX="${DN_DATATMP}/${PREFIX1}"

    FMT2="${PREFIX}-${PRIuSZ}.lossless.${FN_SUFFIX}"
    FN_PATTERN2=$(echo "${FMT2}" | ${EXEC_AWK} -F% '{ match($2,"[0-9]*d(.*)",b); print $1 "[0-9]*" b[1]; }' )
    #mr_trace "FMT2=${FMT2}; FN_PATTERN2=${FN_PATTERN2}; FN_BASE=${FN_BASE}; FN_INPUT_VIDEO=${FN_INPUT_VIDEO}; PREFIX0=${PREFIX0}; PREFIX1=${PREFIX1}; PREFIX2=${PREFIX2};"

    DIR1=$(dirname "${PREFIX}")
    ${MYEXEC} mkdir -p "${DIR1}"

    # detect if exist audio
    mr_trace "[DBG] ${EXEC_FFPROBE} -v quiet -select_streams a -show_streams ${FN_INPUT_VIDEO}"
    echo | ${EXEC_FFPROBE} -v quiet -select_streams a -show_streams "${FN_INPUT_VIDEO}" | grep duration 1>&2
    if [ "$?" = "0" ]; then
        # remove audio
        FN_INPUT_VIDEO="${PREFIX}.videolossless.${FN_SUFFIX}"
        mr_trace "[DBG] extract video only file: ${FN_INPUT_VIDEO}"
        echo | ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} -i "${PARAM_VIDEO_FILE}" -c:v copy -an -y "${FN_INPUT_VIDEO}" 1>&2
        if [ "${PARAM_AUDIO_FILE}" = "${PARAM_VIDEO_FILE}" ]; then
          FN_INPUT_AUDIO="${PREFIX}-audio.${FN_SUFFIX}"
          echo | ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} -i "${PARAM_VIDEO_FILE}" -c:a copy -vn -y "${FN_INPUT_AUDIO}" 1>&2
        fi
    fi
    ${MYEXEC} ${DANGER_EXEC} rm -f "${FN_PATTERN2}" 1>&2
    mr_trace "[DBG] ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} -i ${FN_INPUT_VIDEO} -f segment -segment_time ${PARAM_SEGSEC} -vcodec copy -reset_timestamps 1 -map 0 -y ${FMT2}"
    echo | ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} -i "${FN_INPUT_VIDEO}" \
              -f segment -segment_time ${PARAM_SEGSEC} -segment_list_type flat -segment_list out.list \
              -c:v copy -reset_timestamps 1 -map 0 -an -y "${FMT2}" 1>&2

    #if [ -f "${PREFIX}.videolossless.${FN_SUFFIX}" ]; then
    #  ${MYEXEC} ${DANGER_EXEC} rm -f "${PREFIX}.videolossless.${FN_SUFFIX}" 1>&2
    #fi

    # pass the file name to the reducer, so that the files name are sorted
    # the reducer will calculate the frame numbers of each video chunks,
    # and set the sequence number for request 'lossless'
    cat out.list | ${EXEC_AWK} -v KEY="${PARAM_VIDEO_FILE}" \
                    -v SEGSEC=${PARAM_SEGSEC} \
                    -v AUD="${FN_INPUT_AUDIO}" \
                    -v PREFIX="$(dirname "${FMT2}")" \
                    '{print "processvid\t\"" KEY "\"\t\"" AUD "\"\t\"" PREFIX "/" $0 "\"\t" SEGSEC ; }'
    #processvid <key> <audio_file> <vid_seg_file_name_out> <segsec>
    # processvid "/path/to/video-lossless.mkv" "/path/to/audio2.flac" "/path/to/video-0000000000000000001.lossless.mkv" 6

    ${MYEXEC} cd - 1>&2
    ${MYEXEC} ${DANGER_EXEC} rm -rf "${DN_TMP}" 1>&2

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

# list all of pic files
worker_pic_list () {
    local PARAM_SESSION_ID="$1"
    shift
    local PARAM_FN_PATTERN="$1"
    shift
    local PARAM_AUDIO_FILE="$1"
    shift
    local PARAM_VIDEO_FILE="$1"
    shift
    local PARAM_SEGSEC="$1"
    shift
    local PARAM_VIDEO_FPS="$1"
    shift
    local PARAM_N_START="$1"
    shift

    # pass the file name to the reducer, so that it sort the files names
    # the reducer will calculate the frame numbers of each video chunks,
    # and set the sequence number for request 'lossless'
    ls ${PARAM_FN_PATTERN} \
        | ${EXEC_AWK} -v KEY="${PARAM_VIDEO_FILE}" -v SEGSEC=${PARAM_SEGSEC} -v AUD="${PARAM_AUDIO_FILE}" -v FPS=${PARAM_VIDEO_FPS} -v NSTART=${PARAM_N_START} \
            '{print "picgroup\t\"" KEY "\"\t\"" AUD "\"\t\"" $0 "\"\t" SEGSEC "\t" FPS "\t" NSTART ; }'
    #picgroup   <key> <audio_file> <vid_seg_file_name_out> <segsec> <fps> <frame_start_number>
    # picgroup   "/path/to/film-%05d.png"      "/path/to/audio1.flac" "/path/to/video-0000000000000000001.lossless.mkv" 6 24 144

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

process_stream_e1map() {

    local RET=0
    local ERR=0

    #<type> <audio_file> <video_file_fmt> <segsec> [<fps> <#start> <#files>]
    # origpic "/path/to/audio1.flac" "/path/to/film-%05d.png" 6   24 1 144
    # origvid "/path/to/audio2.flac" "/path/to/video-lossless.mkv" 6
    while read MR_TYPE MR_AUDIO_FILE MR_VIDEO_FILE MR_SEGSEC MR_VIDEO_FPS MR_N_START MR_N_FILES ; do
        FN_VIDEO_FILE1=$( unquote_filename "${MR_VIDEO_FILE}" )
        FN_VIDEO_FILE=$( convert_filename "${DN_EXEC}/input/" "${FN_VIDEO_FILE1}" )

        ERR=0
        case "${MR_TYPE}" in
        config)
            # this will call this function itself to dump the info from config files
            FN_AUDIO_FILE1=$( unquote_filename "${MR_AUDIO_FILE}" )
            FN_AUDIO_FILE=$( convert_filename "${DN_EXEC}/input/" "${FN_AUDIO_FILE1}" )
            mr_trace "call self to dump config data: ${FN_AUDIO_FILE}"
            cat_file "${FN_AUDIO_FILE}" | process_stream_e1map
            continue
            ;;

        origpic)
            if [ "${MR_N_START}" = "" ]; then
                MR_N_START=1
            fi
            #FN_SUFFIX=${OPTIONS_FFM_VCODEC_SUFFIX}
            FN_PATTERN="${FN_VIDEO_FILE}"
            # check if the file exist
            RET=$(is_file_or_dir "${FN_VIDEO_FILE}")
            if [ ! "${RET}" = "f" ]; then
                mr_trace "check if the format of the file name(${FN_VIDEO_FILE}) is xxx-%05d.mkv"
                TMP=$(echo | ${EXEC_AWK} -v FMT="${FN_VIDEO_FILE}" -v N=${MR_N_START} '{printf(FMT, N);}' )
                mr_trace "TMP=${TMP}"
                RET=$(is_file_or_dir "${TMP}")
                if [ "${RET}" = "f" ]; then
                    FN_PATTERN=$(echo "${FN_VIDEO_FILE}" | ${EXEC_AWK} -F% '{match($2,"[0-9]*d(.*)",b);print $1 "[0-9]*"b[1];}' )
                    mr_trace "convert xxx-%05d.mkv(${FN_VIDEO_FILE}) to xxx-[0-9]*.mkv(${FN_PATTERN})"
                else
                    mr_trace "check if the file name is xxx-*.mkv(${FN_VIDEO_FILE})"
                    find_file "${FN_VIDEO_FILE}" -name "${FN_VIDEO_FILE}"
                    TMP="$(dirname ${TMP})"
                    TMP="$( find_file "${TMP}" -name "${FN_VIDEO_FILE}" | head -n 1 )"
                    if [ "${TMP}" = "" ]; then
                        RET="e"
                    else
                        RET=$(is_file_or_dir "${TMP}")
                    fi
                    if [ ! "${RET}" = "f" ]; then
                        mr_trace "Err: not found file 1: '${FN_VIDEO_FILE}' (${MR_VIDEO_FILE})"
                        ERR=1
                    fi
                fi
            fi
            if [ "${MR_SEGSEC}" = "" ]; then
                mr_trace "Err: no segment size: ${MR_SEGSEC}"
                ERR=1
            fi
            if [ "${MR_VIDEO_FPS}" = "" ]; then
                mr_trace "Err: no video fps: ${MR_VIDEO_FPS}"
                ERR=1
            fi
            ;;

        origvid)
            RET=$(is_file_or_dir "${FN_VIDEO_FILE}")
            if [ ! "${RET}" = "f" ]; then
                # not found file
                mr_trace "Err: not found file 2: '${FN_VIDEO_FILE}' (${MR_VIDEO_FILE})"
                ERR=1
            fi
            ;;

        *)
            mr_trace "Err: unknown type: ${MR_TYPE}"
            ERR=1
            ;;
        esac
        #if [ ! -f "${FN_AUDIO_FILE}" ]; then
        #  mr_trace "Err: not found file 2: ${MR_AUDIO_FILE}"
        #  ERR=1
        #fi
        if [ ! "${ERR}" = "0" ] ; then
            mr_trace "ignore line: ${MR_TYPE} ${MR_AUDIO_FILE} ${MR_VIDEO_FILE} ${MR_SEGSEC} ${MR_VIDEO_FPS} ${MR_N_START} ${MR_N_FILES}"
            continue
        fi
        FN_AUDIO_FILE1=$( unquote_filename "${MR_AUDIO_FILE}" )
        FN_AUDIO_FILE=$( convert_filename "${DN_EXEC}/input/" "${FN_AUDIO_FILE1}" )

        case "${MR_TYPE}" in
        origpic)
            # 1. search all of the files and generate the the task lines for next stage
            # 2. support xxx-*.png format
            #if [ -f "${FN_VIDEO_FILE}" ]; then
            #  # one single file?
            #else
            #  if [ "${FN_PATTERN}" = "${FN_VIDEO_FILE}" ]; then
            #    # format xxx-%09d.png
            #  else
            #    # format xxx-*.png
            #  fi
            #fi

            worker_pic_list "$(mp_get_session_id)" "${FN_PATTERN}" "${FN_AUDIO_FILE}" "${FN_VIDEO_FILE}" ${MR_SEGSEC} ${MR_VIDEO_FPS} ${MR_N_START} &
            PID_CHILD=$!
            mp_add_child_check_wait ${PID_CHILD}
            ;;

        origvid)
            worker_mkv_split "$(mp_get_session_id)" "${FN_AUDIO_FILE}" "${FN_VIDEO_FILE}" ${MR_SEGSEC} &
            PID_CHILD=$!
            mp_add_child_check_wait ${PID_CHILD}
            ;;

        *)
            mr_trace "Err: unknown type: ${MR_TYPE}"
            ERR=1
            ;;
        esac

    done
}

process_stream_e1map

mp_wait_all_children
