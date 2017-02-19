#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief Multimedia Transcoding Using Map/Reduce Paradigm -- Step 2 Map part
##
##   In this part, the script will transcode the media segments.
## @author Yunhui Fu <yhfudev@gmail.com>
## @copyright GPL v3.0 or later
## @version 1
##
#####################################################################

## @fn my_getpath()
## @brief get the real name of a path
## @param dn the path name
##
## get the real name of a path, return the real path
my_getpath() {
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

#####################################################################
## @fn worker_transcode_ffmpeg()
## @brief transcode the video segments
## @param session_id the session id
## @param video_file the video file
## @param video_out
## @param desti_prefix
## @param resolution_ffm
## @param resolution_mr
## @param video_fps the fps of video
## @param seq_frame
## @param audio_file the audio file
## @param audio_bps
##
##   if the output file is .webm type, try to fire the audio encoding
##   request of a current audio bitrate
worker_transcode_ffmpeg() {
  PARAM_SESSION_ID="$1"
  shift
  PARAM_VIDEO_FILE="$1"
  shift
  PARAM_VIDEO_OUT="$1"
  shift
  PARAM_DESTI_PREFIX="$1"
  shift
  PARAM_RESOLUTION_FFM="$1"
  shift
  PARAM_RESOLUTION_MR="$1"
  shift
  PARAM_VIDEO_BPS="$1"
  shift
  PARAM_SEQ_FRAME="$1"
  shift
  PARAM_AUDIO_FILE="$1"
  shift
  PARAM_AUDIO_BPS="$1"
  shift

  # because we use 2pass, we need somewhere to store the ffmpeg's log file to avoid conflict with other threads
  DN_TMP="${DN_DATATMP}/worker-$(uuidgen)"
  ${MYEXEC} mkdir -p "${DN_TMP}" 1>&2
  ${MYEXEC} cd "${DN_TMP}" 1>&2
  mr_trace "transcode file=${PARAM_VIDEO_FILE}, output=${PARAM_VIDEO_OUT}, resolution=${PARAM_RESOLUTION_FFM}, bps=${PARAM_VIDEO_BPS}"
  ${MYEXEC} ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} -i "${PARAM_VIDEO_FILE}" -pass 1 ${OPTIONS_FFM_VCODEC} ${PARAM_RESOLUTION_FFM} -b:v ${PARAM_VIDEO_BPS} -bt ${PARAM_VIDEO_BPS} ${OPTIONS_FFM_VIDEO} -an -f rawvideo -y /dev/null 1>&2
  ${MYEXEC} ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} -i "${PARAM_VIDEO_FILE}" -pass 2 ${OPTIONS_FFM_VCODEC} ${PARAM_RESOLUTION_FFM} -b:v ${PARAM_VIDEO_BPS} -bt ${PARAM_VIDEO_BPS} ${OPTIONS_FFM_VIDEO} -y "${PARAM_VIDEO_OUT}" 1>&2
  ${MYEXEC} cd - 1>&2
  ${MYEXEC} ${DANGER_EXEC} rm -rf "${DN_TMP}" 1>&2

  # concat <video_destination> <transcode_file> <audio_file> <audio_bitrate>
  # metrics <mmetrics_destination> <transcode_file> <origin_file> <start_frame_number> <screen_resolution>
  # concat "/path/to/video-320x180-315k.mkv"      "/path/to/video-320x180-315k-0000000000000000001.mkv" "/path/to/audio1.flac" 64k
  # metrics "/path/to/video-320x180-315k.metricsvideo" "/path/to/video-320x180-315k-0000000000000000000.mkv" "/path/to/video-lossless-0000000000000000000.mkv" 0 1280x720

  SUFFIX9=$(echo "${PARAM_VIDEO_OUT}" | ${EXEC_AWK} -F. '{print $NF }')
  echo -e "concat\t\"${PARAM_DESTI_PREFIX}.${SUFFIX9}\"\t\"${PARAM_VIDEO_OUT}\"\t\"${PARAM_AUDIO_FILE}\"\t${PARAM_AUDIO_BPS}"

  #HDFF_SCREEN_RESOLUTIONS=320x180,640x360,854x480,1280x720,1920x1080,3840x2160,7680x4320
  #echo "metrics ${PARAM_DESTI_PREFIX}.metricsvideo ${PARAM_VIDEO_OUT} ${PARAM_VIDEO_FILE} ${SEQ1} SCREEN_RESOLUTION"
  SEQ1=$(echo | ${EXEC_AWK} -v A=${PARAM_SEQ_FRAME} '{print 0 + A;}')
  echo | ${EXEC_AWK} -v DEST="${PARAM_DESTI_PREFIX}.metricsvideo" -v RESLST="${HDFF_SCREEN_RESOLUTIONS}" -v SEQ="${SEQ1}" \
             -v VID="${PARAM_VIDEO_FILE}" -v VIDOUT="${PARAM_VIDEO_OUT}" '{
split(RESLST, b, ",");
for (i = 1; i <= length(b); i ++) {
  print "metricsv\t\"" VIDOUT "\"\t\"" DEST "\"\t\"" VID "\"\t" SEQ "\t" b[i];
}
}'

  # if the format is .webm, then we need to prepare the audio encoded files for google's webm dash tool
  # we don't need to join(unify) the codec bitrate here, if the next step is ''reducer'', we can handle it there.
  # so that it can simplify the code here.
  # so the audioenc should be processed by a reducer for the best performance.
  #audioenc <transcode_file> <origin_file> <mpd_destination> <audio_bitrate>
  # audioenc "/path/to/audio-256k.webm" "/path/to/audio.flac" "/path/to/video.gwebm.mpd" 256k
  # example PARAM_AUDIO_FILE=/path/to/audio.a.webm
  if [ "${SUFFIX9}" = "webm" ]; then
    # example PARAM_AUDIO_FILE=/path/to/audio.a.flac
    #FN_BASE1=$(echo "${PARAM_AUDIO_FILE}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
    # example FN_BASE1=/path/to/media-audio.a
    #FN_BASE2=$(basename "${FN_BASE1}")
    # example PARAM_DESTI_PREFIX=/path-to/media-320x180-315k
    FN_BASE3=$(echo "${PARAM_DESTI_PREFIX}" | ${EXEC_AWK} -F- '{b=$1; for (i=2; i + 1 < NF; i ++) {b=b "-" $(i)}; print b}')
    # example FN_BASE3=/path-to/media
    FN_OUT_AUDIO="${FN_BASE3}-audio-${PARAM_AUDIO_BPS}.${SUFFIX9}"
    # example FN_OUT_AUDIO=/output/media-audio-256k.webm

    echo -e "audioenc\t\"${FN_OUT_AUDIO}\"\t\"${PARAM_AUDIO_FILE}\"\t\"${FN_BASE3}.gwebm.mpd\"\t${PARAM_AUDIO_BPS}"
  fi

  mp_notify_child_exit ${PARAM_SESSION_ID}
}

#####################################################################
#<type> <seq_frame> <video_file> <resolution> <video_bps> <audio_file> <audio_bps>
# lossless 0 "/path/to/video-0000000000000000000.lossless.mkv"  320x180 315k "/path/to/audio1.flac" 64k
#example MR_VIDEO_FILE="/path/to/video-0000000000000000000.lossless.mkv"
while read MR_TYPE MR_SEQ_FRAME MR_VIDEO_FILE MR_RESOLUTION MR_VIDEO_BPS MR_AUDIO_FILE MR_AUDIO_BPS ; do
  FN_VIDEO_FILE=$( unquote_filename "${MR_VIDEO_FILE}" )
  FN_AUDIO_FILE=$( unquote_filename "${MR_AUDIO_FILE}" )

  ERR=0
  if [ ! "${MR_TYPE}" = "lossless" ] ; then
    mr_trace "Err: unknown type: ${MR_TYPE}"
    ERR=1
  fi
  if [ ! -f "${FN_VIDEO_FILE}" ]; then
    # not found file
    mr_trace "Err: not found file 1: ${MR_VIDEO_FILE}"
    ERR=1
  fi
  if [ "${MR_RESOLUTION}" = "" ]; then
    mr_trace "Err: parameter resolution: ${MR_RESOLUTION}"
    ERR=1
  fi
  if [ "${MR_SEQ_FRAME}" = "" ]; then
    mr_trace "Err: parameter video star frame number: ${MR_SEQ_FRAME}"
    ERR=1
  fi
  if [ "${MR_VIDEO_BPS}" = "" ]; then
    mr_trace "Err: parameter video bps: ${MR_VIDEO_BPS}"
    ERR=1
  fi
  if [ ! "${ERR}" = "0" ] ; then
    mr_trace "ignore line: ${MR_TYPE} ${MR_VIDEO_FILE} ${MR_RESOLUTION} ${MR_VIDEO_BPS}"
    continue
  fi

  RESOLUTION="-s ${MR_RESOLUTION}"
  ${EXEC_FFMPEG} -i "${FN_VIDEO_FILE}" 2>&1 | grep "${MR_RESOLUTION}" 1>&2
  if [ $? = 0 ]; then
    RESOLUTION=
  fi
  FN_INPUT_VIDEO="${FN_VIDEO_FILE}"
  # get rid of the .lossless. in the file name
  #FN_BASE=$(echo "${FN_INPUT_VIDEO}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
  # example FN_INPUT_VIDEO=/path/to/tmp/video-320x180-315k-0000000000000000000.mkv
  FN_PREFIX1=$(echo "${FN_INPUT_VIDEO}" | ${EXEC_AWK} -F. '{print $1}')
  # example FN_PREFIX1=/path/to/tmp/video-320x180-315k-0000000000000000000
  FN_BASE0="$(basename "${FN_PREFIX1}" )"
  # example FN_BASE0=video-320x180-315k-0000000000000000000
  FN_BASE=$(echo "${FN_BASE0}" | ${EXEC_AWK} -F- '{b=$1; for (i=2; i < NF; i ++) {b=b "-" $(i)}; print b}')
  # example FN_BASE=video-320x180-315k
  DN_RELEASE="${HDFF_DN_OUTPUT}/"
  DN_TMP="${DN_DATATMP}"

  SEQ=$(echo "${FN_BASE0}" | ${EXEC_AWK} -F- '{print $NF }')
  #FN_SUFFIX=$(echo "${FN_INPUT_VIDEO}" | ${EXEC_AWK} -F. '{print $NF }')

  FN_DESTINATION_BASE="${FN_BASE}-${MR_RESOLUTION}-${MR_VIDEO_BPS}"
  # example FN_DESTINATION_BASE=video-320x180-315k
  FN_DESTINATION_PREFIX="${DN_RELEASE}${FN_DESTINATION_BASE}"
  # example FN_DESTINATION_PREFIX=output/video-320x180-315k
  FN_VIDOUT="${DN_TMP}/${FN_DESTINATION_BASE}-${SEQ}.${OPTIONS_FFM_VCODEC_SUFFIX}"
  # example FN_VIDOUT=/tmp/video-320x180-315k-0000000000000000000.mkv
  #mr_trace "clean the file: rm -f ${FN_VIDOUT}"
  ${MYEXEC} ${DANGER_EXEC} rm -f "${FN_VIDOUT}" 1>&2

  # create multiple instances
  mr_trace "run child $CNTCHILD"
  worker_transcode_ffmpeg "$(mp_get_session_id)" "${FN_VIDEO_FILE}" "${FN_VIDOUT}" "${FN_DESTINATION_PREFIX}" "${RESOLUTION}" ${MR_RESOLUTION} "${MR_VIDEO_BPS}" "${MR_SEQ_FRAME}" "${FN_AUDIO_FILE}" "${MR_AUDIO_BPS}" &
  PID_CHILD=$!
  mp_add_child_check_wait ${PID_CHILD}

done

mp_wait_all_children
