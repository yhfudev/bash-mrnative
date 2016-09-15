#!/bin/bash
#####################################################################
# Multimedia Transcoding Using Map/Reduce Paradigm -- Step 1 Reduce part
#
# In this part, the script will get a sorted list of file names,
# which are grouped by the key by Map/Reduce service, and
# the Map/Reduce service should guarante that all of the contents
# indexed by the key should be handle by the same node/thread.
#
# The script will generate the start frame number for each video segment.
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

libapp_prepare_app_binary

#####################################################################

# link all of the pictures in one folder(fmt0)
worker_pic_linker () {
    PARAM_SESSION_ID="$1"
    shift
    PARAM_FMT0="$1"
    shift
    PARAM_VIDEO_FPS="$1"
    shift
    PARAM_SEQ_FRAME="$1"
    shift
    PARAM_FN_OUTPUT="$1"
    shift
    PARAM_FN_AUDIO="$1"
    shift

    #ffmpeg -r ${FPS} -i "${FN_INPUT_VIDEO}" -c:v libx264 -preset ultrafast -qp 0 -pix_fmt yuv444p -f segment -segment_time ${MR_SEGSEC} -reset_timestamps 1 -map 0 -y "${FMT2}" 1>&2

    DN_TMP="${DN_DATATMP}/worker-$(uuidgen)"
    ${MYEXEC} mkdir -p "${DN_TMP}" 1>&2
    ${MYEXEC} cd "${DN_TMP}" 1>&2
    mr_trace "generate (${PARAM_FN_OUTPUT})"
    echo | ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} -r ${PARAM_VIDEO_FPS} -i "${PARAM_FMT0}" -c:v libx264 -preset ultrafast -qp 0 -pix_fmt yuv444p -reset_timestamps 1 -map 0 -y "${PARAM_FN_OUTPUT}" 1>&2
    ${MYEXEC} cd - 1>&2
    ${MYEXEC} ${DANGER_EXEC} rm -rf "${DN_TMP}" 1>&2

    mr_trace "begin lossless piclinker, FMT=${PARAM_FMT0}; VIDFPS=${PARAM_VIDEO_FPS}; SEQFRAME=${PARAM_SEQ_FRAME}; RES=${HDFF_TRANSCODE_RESOLUTIONS}; OUT=${PARAM_FN_OUTPUT}; AUD=${PARAM_FN_AUDIO}"
    echo "${PARAM_FN_OUTPUT}" | ${EXEC_AWK} -F/ -v RES="${HDFF_TRANSCODE_RESOLUTIONS}" -v SEQFRAME=${PARAM_SEQ_FRAME} -v AUD="${PARAM_FN_AUDIO}" '{
#split($NF, e, ".");
#split(e[1], f, "-");
#seq = 0 + f[length(f)];
split(RES, a, ",");
for (i = 1; i <= length(a); i ++) {
  split(a[i], b, "+");
  print "lossless\t" SEQFRAME "\t\"" $0 "\"\t" b[1] "\t" b[2] "\t\"" AUD "\"\t" b[3];
}
}'
    mr_trace "END lossless piclinker"
    # remove the temp folder with picture symbol links.
    ${MYEXEC} ${DANGER_EXEC} rm -rf "$(dirname "${PARAM_FMT0}")" 1>&2

    mp_notify_child_exit ${PARAM_SESSION_ID}
}

#####################################################################
gen_lossless_chunk_file_name () {
    PARAM_FN_INPUT=$1
    shift
    PARAM_IDX=$1
    shift

    FN_BASE=$(echo "${PARAM_FN_INPUT}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
    PREFIX0="$(basename "${FN_BASE}" )"
    PREFIX1=$(generate_prefix_from_filename "${PREFIX0}" )
    PREFIX2=$(echo "${PREFIX1}" | ${EXEC_AWK} -F% '{match($2,"[0-9]*d(.*)",b);print $1 b[1];}' )
    PREFIX="${DN_DATATMP}/${PREFIX2}"
    # we use libx264 to generate lossless video segments, don't use webm here
    FMT2="${PREFIX}-${PRIuSZ}.lossless.mkv"
    echo | ${EXEC_AWK} -v FMT="${FMT2}" -v N=${PARAM_IDX} '{printf(FMT, N);}'
}

gen_tmpdir_picgroup () {
    PARAM_FN=$1
    shift

    DN_TMP="${DN_DATATMP}/piclink-$(uuidgen)"
    ${MYEXEC} mkdir -p "${DN_TMP}" 1>&2
    SUFPIC=$(echo "${PARAM_FN}" | ${EXEC_AWK} -F. '{print $NF }')
    echo "${DN_TMP}/tmp-%019d.${SUFPIC}"
}

#####################################################################
# destination file name(and video file name) is the key of the data
PRE_DESTINATION_PICGROUP=
PICGROUP_SEQ_FRAME=0
PICGROUP_CNT=0
PICGROUP_IDX=0
PICGROUP_N_START=0
PICGROUP_MAX_GOP=0
PICGROUP_FMT0=
PICGROUP_AUDIO_FILE=
PICGROUP_VIDEO_FPS=0

PRE_DESTINATION_PROCESSVID=
PROCESSVID_SEQ_FRAME=0
#<type> <path_in> <segsec> <audio_file> [<path_out> <fps>]
#picgroup   <key> <audio_file> <vid_seg_file_name_out> <segsec> <fps> <frame_start_number>
#processvid <key> <audio_file> <vid_seg_file_name_out> <segsec>
# picgroup   "/path/to/film-%05d.png"      "/path/to/audio1.flac" "/path/to/video-0000000000000000001.lossless.mkv" 6 24 144
# processvid "/path/to/video-lossless.mkv" "/path/to/audio2.flac" "/path/to/video-0000000000000000001.lossless.mkv" 6
while read MR_TYPE MR_VIDEO_IN MR_AUDIO_FILE MR_VIDEO_OUT MR_SEGSEC MR_VIDEO_FPS MR_N_START ; do
    FN_VIDEO_IN=$( unquote_filename "${MR_VIDEO_IN}" )
    FN_AUDIO_FILE=$( unquote_filename "${MR_AUDIO_FILE}" )
    FN_VIDEO_OUT=$( unquote_filename "${MR_VIDEO_OUT}" )

    ERR=0
    case "${MR_TYPE}" in
    picgroup)
        if [ "${MR_VIDEO_FPS}" = "" ]; then
            mr_trace "Err: parameter video frame rate: ${MR_VIDEO_FPS}"
            ERR=1
        fi
        if [ "${MR_N_START}" = "" ]; then
            mr_trace "Err: parameter video frame start number: ${MR_N_START}"
            ERR=1
        fi
        ;;

    processvid)
        ;;

    *)
        mr_trace "Err: unknown type: ${MR_TYPE}"
        ERR=1
        ;;
    esac
    if [ "${FN_VIDEO_IN}" = "" ]; then
        mr_trace "Err: parameter input video file name: ${MR_VIDEO_IN}"
        ERR=1
        fi
    if [ "${FN_VIDEO_OUT}" = "" ]; then
        mr_trace "Err: parameter output video file name: ${MR_VIDEO_OUT}"
        ERR=1
    fi
    if [ ! -f "${FN_VIDEO_OUT}" ]; then
        # not found file
        mr_trace "Err: not found file 1: ${FN_VIDEO_OUT}"
        ERR=1
    fi
    if [ ! "${ERR}" = "0" ] ; then
        mr_trace "ignore line: ${MR_TYPE} ${MR_VIDEO_IN} ${MR_AUDIO_FILE} ${MR_VIDEO_OUT} ${MR_SEGSEC} ${MR_VIDEO_FPS} ${MR_N_START}"
        continue
    fi

    case "${MR_TYPE}" in
    picgroup)
        # REDUCE: read until reach to a different key, then reduce it
        if [ ! "${PRE_DESTINATION_PICGROUP}" = "${FN_VIDEO_IN}" ] ; then
            # new file set
            # save previous
            if [ ! "${PRE_DESTINATION_PICGROUP}" = "" ] ; then
                # assert MAX_GOP!=0
                FN_OUTPUT=$(gen_lossless_chunk_file_name "${PRE_DESTINATION_PICGROUP}" ${PICGROUP_IDX} )
                worker_pic_linker "$(mp_get_session_id)" "${PICGROUP_FMT0}" "${PICGROUP_VIDEO_FPS}" "${PICGROUP_SEQ_FRAME}" "${FN_OUTPUT}" "${PICGROUP_AUDIO_FILE}" &
                PID_CHILD=$!
                mp_add_child_check_wait ${PID_CHILD}
            fi

            PICGROUP_MAX_GOP=$(( ${MR_VIDEO_FPS} * ${MR_SEGSEC} ))

            # the link to pictures
            PICGROUP_FMT0=$(gen_tmpdir_picgroup "${FN_VIDEO_OUT}" )

            PRE_DESTINATION_PICGROUP="${FN_VIDEO_IN}"
            PICGROUP_N_START=${MR_N_START}
            PICGROUP_SEQ_FRAME=0
            PICGROUP_VIDEO_FPS=${MR_VIDEO_FPS}
            PICGROUP_AUDIO_FILE=${FN_AUDIO_FILE}
            PICGROUP_CNT=0
            PICGROUP_IDX=0
        fi

        TMP=$(echo | ${EXEC_AWK} -v FMT="${PICGROUP_FMT0}" -v S=${PICGROUP_N_START} -v N=${PICGROUP_CNT} '{printf(FMT, S+N);}' )
        mr_trace "link (${MR_VIDEO_OUT}) to (${TMP})"
        ${MYEXEC} ln -s "${MR_VIDEO_OUT}" "${TMP}" 1>&2

        PICGROUP_CNT=$(( ${PICGROUP_CNT} + 1 ))
        if [ "$(echo | ${EXEC_AWK} -v A=${PICGROUP_CNT} -v B=${PICGROUP_MAX_GOP} '{if (A<B) {print 1;} else {print 0;} }')" = "0" ]; then
            # save
            FN_OUTPUT=$(gen_lossless_chunk_file_name "${PRE_DESTINATION_PICGROUP}" ${PICGROUP_IDX} )
            worker_pic_linker "$(mp_get_session_id)" "${PICGROUP_FMT0}" "${PICGROUP_VIDEO_FPS}" "${PICGROUP_SEQ_FRAME}" "${FN_OUTPUT}" "${PICGROUP_AUDIO_FILE}" &
            PID_CHILD=$!

            # next group id
            PICGROUP_IDX=$(( ${PICGROUP_IDX} + 1 ))
            # next frame start position
            PICGROUP_SEQ_FRAME=$(( ${PICGROUP_SEQ_FRAME} + ${PICGROUP_CNT} ))
            # the pic id reset to 0 for next group pic
            PICGROUP_CNT=0
            # dir for next group pic
            PICGROUP_FMT0=$(gen_tmpdir_picgroup "${FN_VIDEO_OUT}" )

            mp_add_child_check_wait ${PID_CHILD}
        fi
    ;;

    processvid)
        # REDUCE: read until reach to a different key, then reduce it
        if [ ! "${PRE_DESTINATION_PROCESSVID}" = "${FN_VIDEO_IN}" ] ; then
            # new file set
            PROCESSVID_SEQ_FRAME=0
            PRE_DESTINATION_PROCESSVID="${FN_VIDEO_IN}"
        fi
        #<type> <seq_frame> <video_file> <resolution> <video_bps> <audio_file> <audio_bps>
        # lossless 0 "/path/to/video-0000000000000000000.lossless.mkv" 320x180 315k "/path/to/audio1.flac" 64k

        # get the frames of each segment file.
        #FN_TMP="${DN_DATATMP}/fames-$(uuidgen).txt"
        #echo | ${EXEC_FFMPEG} -i "${MR_VIDEO_OUT}" -an -c:v copy -f null /dev/nul > "${FN_TMP}" 2>&1
        #FRAME=$(cat "${FN_TMP}" | grep 'frame' | ${EXEC_AWK} '{print 0 + $2}' )
        FRAME=$(echo | ${EXEC_FFMPEG} -i "${FN_VIDEO_OUT}" -an -c:v copy -f null /dev/null 2>&1 | grep 'frame=' | ${EXEC_AWK} '{print 0 + $2}' )

        mr_trace "begin lossless vidfile, FRAME=${FRAME}; RES=${HDFF_TRANSCODE_RESOLUTIONS}; FN_VIDEO_OUT=${FN_VIDEO_OUT}; SEQFRAME=${PROCESSVID_SEQ_FRAME};"
        echo "${FN_VIDEO_OUT}" | ${EXEC_AWK} -F/ -v RES="${HDFF_TRANSCODE_RESOLUTIONS}" -v SEQFRAME=${PROCESSVID_SEQ_FRAME} -v AUD="${FN_AUDIO_FILE}" '{
#split($NF, e, ".");
#split(e[1], f, "-");
#seq = 0 + f[length(f)];
split(RES, a, ",");
for (i = 1; i <= length(a); i ++) {
split(a[i], b, "+");
print "lossless\t" SEQFRAME "\t\"" $0 "\"\t" b[1] "\t" b[2] "\t\"" AUD "\"\t" b[3];
}
}'
        #mr_trace "END lossless vidfile, FRAME=${FRAME}; FILE1=${FILE1};"
        PROCESSVID_SEQ_FRAME=$(( ${PROCESSVID_SEQ_FRAME} + ${FRAME} ))

        ;;

    *)
        mr_trace "Err: unknown type: ${MR_TYPE}"
        continue
        ;;
    esac
    if [ ! "${ERR}" = "0" ] ; then
        mr_trace "ignore line: ${MR_TYPE} ${MR_VIDEO_IN} ${MR_AUDIO_FILE} ${MR_VIDEO_OUT} ${MR_SEGSEC} ${MR_VIDEO_FPS} ${MR_N_START}"
        continue
    fi

done

if [ ! "${PRE_DESTINATION_PICGROUP}" = "" ]; then
    if [ "$(echo | awk -v A=${PICGROUP_SEQ_FRAME} '{if (A>0) { print 1; } else { print 0; } }')" = "1" ]; then
        # the rest of the files
        FN_OUTPUT=$(gen_lossless_chunk_file_name "${PRE_DESTINATION_PICGROUP}" ${PICGROUP_IDX} )
        worker_pic_linker "$(mp_get_session_id)" "${PICGROUP_FMT0}" "${PICGROUP_VIDEO_FPS}" "${PICGROUP_SEQ_FRAME}" "${FN_OUTPUT}" "${PICGROUP_AUDIO_FILE}" &
        PID_CHILD=$!
        mp_add_child_check_wait ${PID_CHILD}
    fi
fi

mp_wait_all_children
