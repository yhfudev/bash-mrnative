#!/bin/bash
#####################################################################
# Multimedia Transcoding Using Map/Reduce Paradigm -- Step 2 Reduce part
#
# In this part, the script will concate media files,
# generate the metric values for the media files/segments
#
# The script will concat the sorted list of media segments,
# it also merge the audio channel to the main media file.
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

#####################################################################
# reducer -- concat
#
worker_reduce_concat_process () {
  PARAM_SESSION_ID="$1"
  shift
  PARAM_DESTINATION_FILE="$1"
  shift
  PARAM_FILELIST="$1"
  shift
  PARAM_FN_AUDIO="$1"
  shift
  PARAM_AUDIO_BPS="$1"
  shift

  DN_TMP00="${DN_DATATMP}/worker-$(uuidgen)"
  ${MYEXEC} mkdir -p "${DN_TMP00}" 1>&2
  ${MYEXEC} cd "${DN_TMP00}" 1>&2
  # Audio: ${OPTIONS_FFM_ASYNC} -i "${PARAM_FN_AUDIO}" -acodec libvo_aacenc -ab ${PARAM_AUDIO_BPS} ${OPTIONS_FFM_AUDIO}
  #echo | ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} -f concat -i "${PARAM_FILELIST}" -c:v copy -y "${PARAM_DESTINATION_FILE}" 1>&2
  SUFFIX9=$(echo "${PARAM_DESTINATION_FILE}" | ${EXEC_AWK} -F. '{print $NF }')
if [ "${SUFFIX9}" = "webm" ]; then
  # Option 1: output concated video file only, for both video+audio and dashmpd
  # setup a tmp file for video only file
  FN_BASE1=$(echo "${PARAM_DESTINATION_FILE}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
  FN_BASE2=$(basename "${FN_BASE1}")
  FN_DEST_VIDONLY_TMP="${DN_DATATMP}/${FN_BASE2}.videoonlytmp.${SUFFIX9}"
  FN_DEST_VIDONLY="${HDFF_DN_OUTPUT}/${FN_BASE2}.videoonly.${SUFFIX9}"
  FN_AV_TMP="${DN_DATATMP}/${FN_BASE2}.avtmp.${SUFFIX9}"

  mr_trace "generate video only webm"
  echo   ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} -f concat -i "${PARAM_FILELIST}" -c:v copy -an -y "${FN_DEST_VIDONLY_TMP}" 1>&2
  echo | ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} -f concat -i "${PARAM_FILELIST}" -c:v copy -an -y "${FN_DEST_VIDONLY_TMP}" 1>&2
  mr_trace "align video for dashmpd (webm)"
  ${MYEXEC} ${EXEC_SAMPLEMUXER} -i "${FN_DEST_VIDONLY_TMP}" -o "${FN_DEST_VIDONLY}" 1>&2

  mr_trace "generate audio/video webm"
  echo   ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} ${OPTIONS_FFM_ASYNC} -f concat -i "${PARAM_FILELIST}" -i "${PARAM_FN_AUDIO}" -c:v copy ${OPTIONS_FFM_ACODEC} -ab ${PARAM_AUDIO_BPS} ${OPTIONS_FFM_AUDIO} -y "${FN_AV_TMP}" 1>&2
  echo | ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} ${OPTIONS_FFM_ASYNC} -f concat -i "${PARAM_FILELIST}" -i "${PARAM_FN_AUDIO}" -c:v copy ${OPTIONS_FFM_ACODEC} -ab ${PARAM_AUDIO_BPS} ${OPTIONS_FFM_AUDIO} -y "${FN_AV_TMP}" 1>&2
  mr_trace "align audio/video for dashmpd (webm)"
  ${MYEXEC} ${EXEC_SAMPLEMUXER} -i "${FN_AV_TMP}" -o "${PARAM_DESTINATION_FILE}" 1>&2

  ${MYEXEC} ${DANGER_EXEC} rm -f "${FN_DEST_VIDONLY_TMP}" 1>&2
  ${MYEXEC} ${DANGER_EXEC} rm -f "${FN_AV_TMP}" 1>&2

  #dashwebmgmerge <mpd_destination> <mediatype> <transcode_file>
  # dashwebmgmerge "/path/to/video.gwebm.mpd" video "/path/to/video-320x180-315k.webm"
  if [ -f "${FN_DEST_VIDONLY}" ]; then
    #FN_BASE1=$(echo "${PARAM_DESTINATION_FILE}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
    PREFIX1=$(echo "${FN_BASE1}" | ${EXEC_AWK} -F- '{b=$1; for (i=2; i + 1 < NF; i ++) {b=b "-" $(i)}; print b}')
    FN_DEST11="${PREFIX1}.gwebm.mpd"
    echo -e "dashwebmgmerge\t\"${FN_DEST11}\"\tvideo\t\"${FN_DEST_VIDONLY}\""
  else
    echo -e "processeerr\tdashwebmgmerge\t${FN_DEST_VIDONLY}"
  fi

else
  # Option 2: for video+audio output only
  FN_BASE1=$(echo "${PARAM_DESTINATION_FILE}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
  FN_SUFFIX1=$(echo "${PARAM_DESTINATION_FILE}" | ${EXEC_AWK} -F. '{print $NF;}')
  if [ "${FN_SUFFIX1}" = "mp4" ]; then
    TMP="${FN_BASE1}.4qtfast.${FN_SUFFIX1}"
    FN_TMP="${DN_DATATMP}/$(basename "${TMP}" )"
  else
    FN_TMP="${PARAM_DESTINATION_FILE}"
  fi
  echo   ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} ${OPTIONS_FFM_ASYNC} -f concat -i "${PARAM_FILELIST}" -i "${PARAM_FN_AUDIO}" -c:v copy ${OPTIONS_FFM_ACODEC} -ab ${PARAM_AUDIO_BPS} ${OPTIONS_FFM_AUDIO} -y "${FN_TMP}" 1>&2
  echo | ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} ${OPTIONS_FFM_ASYNC} -f concat -i "${PARAM_FILELIST}" -i "${PARAM_FN_AUDIO}" -c:v copy ${OPTIONS_FFM_ACODEC} -ab ${PARAM_AUDIO_BPS} ${OPTIONS_FFM_AUDIO} -y "${FN_TMP}" 1>&2

  if [ "${FN_SUFFIX1}" = "mp4" ]; then
    ${MYEXEC} ${EXEC_QTFAST} "${FN_TMP}" "${PARAM_DESTINATION_FILE}" 1>&2
    ${MYEXEC} ${DANGER_EXEC} rm -f "${FN_TMP}" 1>&2
  fi
fi

  ${MYEXEC} cd - 1>&2
  ${MYEXEC} ${DANGER_EXEC} rm -rf "${DN_TMP00}" 1>&2
  ${MYEXEC} ${DANGER_EXEC} rm -f "${PARAM_FILELIST}" 1>&2

  #dashmpd <mpd_destination> av <transcode_file>
  # dashmpd "/path/to/video.mpd" av "/path/to/video-320x180-315k.mkv"
  if [ -f "${PARAM_DESTINATION_FILE}" ]; then
    FN_BASE1=$(echo "${PARAM_DESTINATION_FILE}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
    PREFIX1=$(echo "${FN_BASE1}" | ${EXEC_AWK} -F- '{b=$1; for (i=2; i + 1 < NF; i ++) {b=b "-" $(i)}; print b}')
    FN_DEST11="${PREFIX1}.mpd"
    echo -e "dashmpd\t\"${FN_DEST11}\"\tav\t\"${PARAM_DESTINATION_FILE}\""
  else
    echo -e "processeerr\tconcat\t${PARAM_DESTINATION_FILE}"
  fi

  mp_notify_child_exit ${PARAM_SESSION_ID}
}

# encode audio with a bitrate
worker_reduce_audenc_process () {
  PARAM_SESSION_ID="$1"
  shift
  PARAM_FN_AUDIO_IN="$1"
  shift
  PARAM_FN_AUDIO_OUT="$1"
  shift
  PARAM_FILELIST="$1"
  shift
  PARAM_ABITRATE=$1
  shift

  echo -e "processedlog\taudenc\t${PARAM_FN_AUDIO_OUT}\t${PARAM_FILELIST}"

  FN_BASE1=$(echo "${PARAM_FN_AUDIO_OUT}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
  FN_SUFFIX1=$(echo "${PARAM_FN_AUDIO_OUT}" | ${EXEC_AWK} -F. '{print $NF;}')
  TMP="${FN_BASE1}.tmp.${FN_SUFFIX1}"
  FN_OUT_AUDIO_TMP="${DN_DATATMP}/$(basename "${TMP}" )"

  DN_TMP00="${DN_DATATMP}/worker-$(uuidgen)"
  ${MYEXEC} mkdir -p "${DN_TMP00}" 1>&2
  ${MYEXEC} cd "${DN_TMP00}" 1>&2
  ${MYEXEC} ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} ${OPTIONS_FFM_ASYNC} -i "${PARAM_FN_AUDIO_IN}" -vn ${OPTIONS_FFM_ACODEC} -ab ${PARAM_ABITRATE} ${OPTIONS_FFM_AUDIO} -y "${FN_OUT_AUDIO_TMP}"

  # align audio for dashmpd (webm)
  ${MYEXEC} ${EXEC_SAMPLEMUXER} -i "${FN_OUT_AUDIO_TMP}" -o "${PARAM_FN_AUDIO_OUT}" -output_cues 1 -cues_on_audio_track 1 -max_cluster_duration 5 -audio_track_number 2 1>&2
  ${MYEXEC} ${DANGER_EXEC} rm -f "${FN_OUT_AUDIO_TMP}" 1>&2
  if [ ! -f "${PARAM_FN_AUDIO_OUT}" ]; then
    echo -e "processeerr\taudenc\t${PARAM_FN_AUDIO_OUT}\tis_not_generated,EXEC_SAMPLEMUXER=${EXEC_SAMPLEMUXER}\n"
  fi

  #dashwebmgmerge <mpd_destination> <mediatype> <transcode_file>
  # dashwebmgmerge "/path/to/video.gwebm.mpd" audio "/path/to/audio-256k.webm"
  cat "${PARAM_FILELIST}" | while read DESTINATION_FILE ; do
    echo -e "dashwebmgmerge\t\"${DESTINATION_FILE}\"\taudio\t\"${PARAM_FN_AUDIO_OUT}\""
  done

  ${MYEXEC} cd - 1>&2
  ${MYEXEC} ${DANGER_EXEC} rm -rf "${DN_TMP00}" 1>&2

  mp_notify_child_exit ${PARAM_SESSION_ID}
}

worker_calculate_video_metric () {
  PARAM_SESSION_ID="$1"
  shift
  PARAM_DESTINATION_FILE="$1"
  shift
  PARAM_FN_ORIGIN="$1"
  shift
  PARAM_FN_COMPARE="$1"
  shift
  PARAM_SEQ_FRAME="$1"
  shift
  PARAM_RESOLUTIONS="$1"
  shift

  FN_BASE1=$(echo "${PARAM_FN_COMPARE}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
  #PREFIX1=$(echo "${FN_BASE1}" | ${EXEC_AWK} -F- '{b=$1; for (i=2; i + 1 < NF; i ++) {b=b "-" $(i)}; print b}')
  FN_SSIM_OUT="${FN_BASE1}.${PARAM_RESOLUTIONS}.metricsvideo"

  ${MYEXEC} ${EXEC_SSIM} -o "${FN_SSIM_OUT}" -b ${PARAM_SEQ_FRAME} -r ${PARAM_RESOLUTIONS} "${PARAM_FN_ORIGIN}" "${PARAM_FN_COMPARE}" 1>&2

  echo -e "metricsvconcat\t\"${PARAM_DESTINATION_FILE}\"\ttxt\t\"${FN_SSIM_OUT}\""

  mp_notify_child_exit ${PARAM_SESSION_ID}
}

#####################################################################
# destination file name(and video file name) is the key of the data
FN_FILELIST_CONCAT="${DN_DATATMP}/concat-filelist-$(uuidgen).txt"
PRE_DESTINATION_CONCAT=
PRE_AUDBPS_CONCAT=

FN_FILELIST_AUDENC="${DN_DATATMP}/audenc-filelist-$(uuidgen).txt"
PRE_DESTINATION_AUDENC=
PRE_AUDBPS_AUDENC=
PRE_MPDFILE_AUDENC=

# concat <video_destination> <transcode_file> <audio_file> <audio_bitrate>
# concat "/path/to/video-320x180-315k.mkv" "/path/to/video-320x180-315k-0000000000000000001.mkv" "/path/to/audio1.flac" 64k
# metricsv <metrics_destination> <transcode_file> <origin_file> <start_frame_number> <screen_resolution>
# metricsv "/path/to/video-320x180-315k.metricsvideo" "/path/to/video-320x180-315k-0000000000000000000.mkv" "/path/to/video-lossless-0000000000000000000.mkv" 0 1280x720
# audioenc <transcode_file> <origin_file> <mpd_destination> <audio_bitrate>
# audioenc "/path/to/audio-256k.webm" "/path/to/audio.flac" "/path/to/video.gwebm.mpd" 256k
while read MR_TYPE MR_FILE1 MR_FILE2 MR_FILE3 MR_VAL2 MR_VAL3 ; do
  FN_FILE3=$( unquote_filename "${MR_FILE3}" )

  ERR=0
  case "${MR_TYPE}" in
  concat)
    FN_DEST_FILE=$( unquote_filename "${MR_FILE1}" )
    FN_VIDEO_FILE=$( unquote_filename "${MR_FILE2}" )

    FN_AUDIO_FILE="${FN_FILE3}"
    AUDIO_BPS=${MR_VAL2}
    if [ "${AUDIO_BPS}" = "" ]; then
      mr_trace "Err: parameter audio bitrate: ${AUDIO_BPS}"
      ERR=1
    fi
    if [ ! -f "${FN_AUDIO_FILE}" ]; then
      # not found file
      mr_trace "Err: not found file 2: ${FN_FILE3}"
      ERR=1
    fi
    ;;

  metricsv)
    # we exchanged the position of the file1 and file2
    # so that's why DEST=FILE2
    FN_DEST_FILE=$( unquote_filename "${MR_FILE2}" )
    FN_VIDEO_FILE=$( unquote_filename "${MR_FILE1}" )

    FN_ORIG_FILE="${FN_FILE3}"
    SEQ_FRAME=${MR_VAL2}
    SCR_RES="${MR_VAL3}"
    if [ "${SEQ_FRAME}" = "" ]; then
      mr_trace "Err: parameter video star frame number: ${SEQ_FRAME}"
      ERR=1
    fi
    if [ "${SCR_RES}" = "" ]; then
      mr_trace "Err: parameter screem resolution: ${SCR_RES}"
      ERR=1
    fi
    if [ ! -f "${FN_ORIG_FILE}" ]; then
      # not found file
      mr_trace "Err: not found file 2: ${FN_FILE3}"
      ERR=1
    fi
    ;;

  audioenc)
    FN_DEST_FILE=$( unquote_filename "${MR_FILE1}" )
    FN_AUDIO_FILE=$( unquote_filename "${MR_FILE2}" )
    FN_MPD_FILE="${FN_FILE3}"
    # for the file detection code below
    FN_VIDEO_FILE="${FN_AUDIO_FILE}"

    AUDIO_BPS=${MR_VAL2}
    if [ "${AUDIO_BPS}" = "" ]; then
      mr_trace "Err: parameter audio bitrate: ${AUDIO_BPS}"
      ERR=1
    fi
    if [ ! -f "${FN_AUDIO_FILE}" ]; then
      # not found file
      mr_trace "Err: not found file 2: ${FN_FILE3}"
      ERR=1
    fi
    ;;

  *)
    mr_trace "Err: unknown type: ${MR_TYPE}"
    ERR=1
    ;;
  esac
  if [ "${FN_DEST_FILE}" = "" ]; then
    mr_trace "Err: parameter destination file name: ${FN_DEST_FILE}"
    ERR=1
  fi
  if [ ! -f "${FN_VIDEO_FILE}" ]; then
    # not found file
    mr_trace "Err: not found file 1: ${FN_VIDEO_FILE}"
    ERR=1
  fi
  if [ ! "${ERR}" = "0" ] ; then
    mr_trace "ignore line: ${MR_TYPE} ${MR_DESTINATION} ${MR_VIDEO_FILE} ${MR_FILE2} ${MR_VAL2} ${MR_VAL3}"
    continue
  fi


  case "${MR_TYPE}" in
  concat)
    # REDUCE: read until reach to a different key, then reduce it
    if [ ! "${PRE_DESTINATION_CONCAT}" = "${FN_DEST_FILE}" ] ; then
      PID_CHILD=
      if [ ! "${PRE_DESTINATION_CONCAT}" = "" ]; then
        # process the saved list
        # assert: PRE_ORIGAUD_CONCAT == FN_AUDIO_FILE
        worker_reduce_concat_process "$(mp_get_session_id)" "${PRE_DESTINATION_CONCAT}" "${FN_FILELIST_CONCAT}" "${PRE_ORIGAUD_CONCAT}" "${PRE_AUDBPS_CONCAT}" &
        PID_CHILD=$!
      fi

      PRE_ORIGAUD_CONCAT="${FN_AUDIO_FILE}"
      PRE_DESTINATION_CONCAT="${FN_DEST_FILE}"
      FN_FILELIST_CONCAT="${DN_DATATMP}/concat-filelist-$(uuidgen).txt"
      cat /dev/null > "${FN_FILELIST_CONCAT}" 1>&2
      PRE_AUDBPS_CONCAT="${AUDIO_BPS}"

      mp_add_child_check_wait ${PID_CHILD}
    fi
    # "${PRE_DESTINATION_CONCAT}" == "${FN_DEST_FILE}"
    # save the file name to list
    #worker_reduce_concat_save
    echo "${FN_VIDEO_FILE}" | ${EXEC_AWK} '{ print "file \"" $0 "\"" }' | tr \" \' >> "${FN_FILELIST_CONCAT}"
    ;;

  metricsv)
    worker_calculate_video_metric "$(mp_get_session_id)" "${FN_DEST_FILE}" "${FN_ORIG_FILE}" "${FN_VIDEO_FILE}" "${SEQ_FRAME}" "${SCR_RES}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
    ;;

  audioenc)
    # REDUCE: read until reach to a different key, then reduce it
    if [ ! "${PRE_DESTINATION_AUDENC}" = "${FN_DEST_FILE}" ] ; then
      PID_CHILD=
      if [ ! "${PRE_DESTINATION_AUDENC}" = "" ]; then
        # process the saved list
        # original audio file should be the same as the output name is formated as the same way: <original file name> + <bps>!
        # the mpd files may not the same, so we should save it and make it unique
        worker_reduce_audenc_process "$(mp_get_session_id)" "${FN_AUDIO_FILE}" "${PRE_DESTINATION_AUDENC}" "${FN_FILELIST_AUDENC}" "${PRE_AUDBPS_AUDENC}" &
        PID_CHILD=$!
      fi

      PRE_DESTINATION_AUDENC="${FN_DEST_FILE}"
      FN_FILELIST_AUDENC="${DN_DATATMP}/audenc-filelist-$(uuidgen).txt"
      cat /dev/null > "${FN_FILELIST_AUDENC}" 1>&2
      PRE_AUDBPS_AUDENC="${AUDIO_BPS}"

      mp_add_child_check_wait ${PID_CHILD}
    fi
    # "${PRE_DESTINATION_AUDENC}" == "${FN_DEST_FILE}"
    if [ ! "${PRE_MPDFILE_AUDENC}" = "${FN_MPD_FILE}" ] ; then
      PRE_MPDFILE_AUDENC="${FN_MPD_FILE}"
      echo "${FN_MPD_FILE}" >> "${FN_FILELIST_AUDENC}"
    fi
    ;;

  *)
    mr_trace "Err: unknown type: ${MR_TYPE}"
    continue
    ;;
  esac
  if [ ! "${ERR}" = "0" ] ; then
    mr_trace "ignore line: ${MR_TYPE} ${MR_DESTINATION} ${MR_VIDEO_FILE} ${MR_FILE2} ${MR_VAL2} ${MR_VAL3}"
    continue
  fi

done

if [ ! "${PRE_DESTINATION_CONCAT}" = "" ]; then
  if [ "${FN_FILELIST_CONCAT}" = "" ]; then
    mr_trace "Err: file list name: ${FN_FILELIST_CONCAT}"
    ERR=1
  fi
  if [ -f "${FN_FILELIST_CONCAT}" ]; then
    mr_trace "Err: file list not exist: ${FN_FILELIST_CONCAT}"
    ERR=1
  fi
  worker_reduce_concat_process "$(mp_get_session_id)" "${PRE_DESTINATION_CONCAT}" "${FN_FILELIST_CONCAT}" "${PRE_ORIGAUD_CONCAT}" "${PRE_AUDBPS_CONCAT}" &
  PID_CHILD=$!
  mp_add_child_check_wait ${PID_CHILD}
fi

if [ ! "${PRE_DESTINATION_AUDENC}" = "" ]; then
  worker_reduce_audenc_process "$(mp_get_session_id)" "${FN_AUDIO_FILE}" "${PRE_DESTINATION_AUDENC}" "${FN_FILELIST_AUDENC}" "${PRE_AUDBPS_AUDENC}" &
  PID_CHILD=$!
  mp_add_child_check_wait ${PID_CHILD}
fi

mp_wait_all_children
