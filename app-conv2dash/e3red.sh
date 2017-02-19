#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief Multimedia Transcoding Using Map/Reduce Paradigm -- Step 3 Reduce part
##
##   In this part, the script will generates DASH MPD files.
##
##   The script will generate the DASH .mpd file,
##   it also concat the metrics files.
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

## @fn worker_reduce_dashmpd_process()
## @brief 
## @param session_id the session id
## @param destination_file
## @param filelist
##
worker_reduce_dashmpd_process() {
  PARAM_SESSION_ID="$1"
  shift
  PARAM_DESTINATION_FILE="$1"
  shift
  PARAM_FILELIST="$1"
  shift

  FN_SAMPLE=$(head -n "${PARAM_FILELIST}")
  SUFFIX9=$(echo "${FN_SAMPLE}" | ${EXEC_AWK} -F. '{print $NF }')
  case "${SUFFIX9}" in
  mp4)
    cat "${PARAM_FILELIST}" | while read FILE0 ; do
      # -mpd-source
      SEGSEC=6
      FN_BASE1=$(echo "${FILE0}" | ${EXEC_AWK} -F. '{b=$1; for (i=2; i < NF; i ++) {b=b "." $(i)}; print b}')
      #$MYEXEC MP4Box -frag 8000 -dash 24000 -segment-name "${FN_BASE}_dash" "${PARAM_FN_MP4}"
      #$MYEXEC MP4Box ${ARGS_MP4BOX} -rap -frag $(( 1000 * ${SEGSEC})) -dash $(( 3000 * ${SEGSEC})) -segment-name "${FN_BASE}_dash" "${PARAM_FN_MP4}"
      ${MYEXEC} ${EXEC_MP4BOX} -url-template -rap -frag $((500 * ${SEGSEC})) -dash $((1000 * ${SEGSEC})) -segment-name "${FN_BASE1}_dash" "${FILE0}"
    done
    ;;

  webm)
if [ 0 = 1 ]; then
    FN_MPD="${PARAM_PREFIX}.webm.mpd"
    DURATION="PT0H0M52.01S"
    mr_trace "TODO merge the .mpd files for webm()"
    echo "<?xml version='1.0' ?>" > "${FN_MPD}"
    echo "<!-- MPD file Generated with ${VER_DESC} ${VER_MAJOR}.${VER_MAJOR} on $(date) -->" >> "${FN_MPD}"
    echo "" >> "${FN_MPD}"
    echo "<MPD xmlns='urn:mpeg:dash:schema:mpd:2011' minBufferTime='PT1.500000S' type='static' mediaPresentationDuration='${DURATION}' profiles='urn:mpeg:dash:profile:full:2011'>" >> "${FN_MPD}"
    echo "    <ProgramInformation moreInformationURL='http://dashsplitter.sourceforge.net'>" >> "${FN_MPD}"
    echo "        <Title></Title>"   >> "${FN_MPD}"
    echo "    </ProgramInformation>" >> "${FN_MPD}"
    echo "    <Period id='' duration='${DURATION}'>" >> "${FN_MPD}"

    # all of the mpd files:
    ls *.webm.mpd | grep -v "${PARAM_PREFIX}.webm.mpd" | xargs -n 1 cat >> "${FN_MPD}"

    # TODO: use map/reduce
    cat input_file_list | while read FILE0 ; do
        MAXWIDTH=$(echo ${PARAM_RESOLUTION} | awk -Fx '{print $1}')
        MAXHEIGHT=$(echo ${PARAM_RESOLUTION} | awk -Fx '{print $2}')
        UNIT=$(echo ${PARAM_VBITRATE} | awk '{ regex="[0-9][kmg]"; where = match($0, regex); if (where) { print substr($1, where+1, length($1)-where) } else { print "k" } }')
        VBMIN=$(echo ${PARAM_VBITRATE} | awk '{print $1 * (1.0 - 0.1)}')
        VBMAX=$(echo ${PARAM_VBITRATE} | awk '{print $1 * (1.0 + 0.1)}')
        VBUF=$(echo ${PARAM_VBITRATE} | awk '{print $1 * 2}')

        echo "<AdaptationSet segmentAlignment='true' maxWidth='${MAXWIDTH}' maxHeight='${MAXHEIGHT}' maxFrameRate='${FPS}'>" > "${PARAM_FNOUT_VIDEO}.webm.mpd"

        if [ -f "${PARAM_FNOUT_VIDEO}.webm" ]; then
            mr_trace "file ${PARAM_FNOUT_VIDEO}.webm exist, ignore"
        else
            echo | ${EXEC_FFMPEG} ${OPTIONS_FFM_GLOBAL} ${OPTIONS_FFM_ASYNC} -i "${PARAM_FN_VIDEO}" -vcodec ${CODEC_VPX} ${RESOLUTION} -maxrate ${VBMAX}${UNIT} -minrate ${VBMIN}${UNIT} -bufsize ${VBUF}${UNIT} -b:v ${PARAM_VBITRATE} ${OPTIONS_FFM_VIDEO} -f webm ${INPUTAUD} -acodec libvorbis -ab ${PARAM_ABITRATE} ${OPTIONS_FFM_AUDIO} -y "${PARAM_FNOUT_VIDEO}.webm" 1>&2
        fi
        SEGSEC=2
        ${MYEXEC} ${EXEC_PYTHON} ${EXEC_ITEC_MPDSEG} "${FILE0}" ${SEGSEC} $((${SEGSEC} * 2)) "" >> "${PARAM_FNOUT_VIDEO}.webm.mpd"
        if [ ! $? = 0 ]; then
            ${MYEXEC} ${DANGER_EXEC} rm -f "${PARAM_FNOUT_VIDEO}.webm.mpd" 1>&2
        else
            echo "</AdaptationSet>" >> "${PARAM_FNOUT_VIDEO}.webm.mpd"
        fi
    done
    echo "    </Period>" >> "${FN_MPD}"
    echo "</MPD>" >> "${FN_MPD}"
fi
    ;;

  *)
    mr_trace "Warning: unsupport DASH segment file type: ${SUFFIX9}"
    ERR=1
    ;;
  esac

  ${MYEXEC} ${DANGER_EXEC} rm -f "${PARAM_FILELIST}" 1>&2
  mp_notify_child_exit ${PARAM_SESSION_ID}
}

## @fn worker_reduce_dashwebmgmerge_process()
## @brief 
## @param session_id the session id
## @param destination_file
## @param filelist
##
worker_reduce_dashwebmgmerge_process() {
  PARAM_SESSION_ID="$1"
  shift
  PARAM_DESTINATION_FILE="$1"
  shift
  PARAM_FILELIST="$1"
  shift

  echo -e "processedlog\tdashwebmgmerge\t${PARAM_DESTINATION_FILE}\t${PARAM_FILELIST}"

  PMLIST_DASHGEN=$(cat "${PARAM_FILELIST}")
  # generate the MPD file
  ${MYEXEC} ${EXEC_WEBMDASH_MANIFEST} -o "${PARAM_DESTINATION_FILE}" ${PMLIST_DASHGEN}
  ${MYEXEC} sed -i 's|subsegmentStartsWithSAP="1">|subsegmentAlignment="true" subsegmentStartsWithSAP="1" bitstreamSwitching="true">|g' "${PARAM_DESTINATION_FILE}" 1>&2
  ${MYEXEC} sed -i "s|$(dirname "${PARAM_DESTINATION_FILE}")/*||g" "${PARAM_DESTINATION_FILE}" 1>&2

  ${MYEXEC} ${DANGER_EXEC} rm -f "${PARAM_FILELIST}" 1>&2
  mp_notify_child_exit ${PARAM_SESSION_ID}
}

#####################################################################
# destination file name(and video file name) is the key of the data
FN_TMP_MATRIC="${DN_DATATMP}/mmcat-$(uuidgen).txt"
PRE_DESTINATION_MATRIC=
PRE_SEGFILE_MATRIC=

FN_FILELIST_DASHMPD="${DN_DATATMP}/dashmpd-filelist-$(uuidgen).txt"
PRE_DESTINATION_DASHMPD=
PRE_SEGFILE_DASHMPD=

FN_FILELIST_DASHWEBMGMERGE="${DN_DATATMP}/dashwebmgmerge-filelist-$(uuidgen).txt"
PRE_DESTINATION_DASHWEBMGMERGE=
PRE_SEGFILE_DASHWEBMGMERGE=
DASHWEBMGMERGE_PRE_MEDIA=
DASHWEBMGMERGE_GRPCNT=0
DASHWEBMGMERGE_FILECNT=0

# metricsconcat <mmetrics_destination> <mmetrics_file>
# dashmpd <mpd_destination> <transcode_file>
# metricsconcat "/path/to/video-320x180-315k.mmetrics" "/path/to/video-320x180-315k-0000000000000000000.1920x1080.mmetrics"
# dashmpd "/path/to/video.mpd" "/path/to/video-320x180-315k.mkv"
# dashwebmgmerge <mpd_destination> <mediatype> <transcode_file>
# dashwebmgmerge "/path/to/video.mpd" video "/path/to/video-320x180-315k.mkv"
while read MR_TYPE MR_DESTINATION MR_MEDIATYPE MR_FILE ; do
  FN_DEST_FILE=$( unquote_filename "${MR_DESTINATION}" )
  FN_FILE=$( unquote_filename "${MR_FILE}" )

  ERR=0
  if [ "${FN_DEST_FILE}" = "" ]; then
    mr_trace "Err: parameter destination file name: ${FN_DEST_FILE}"
    ERR=1
  fi
  if [ ! -f "${FN_FILE}" ]; then
    # not found file
    mr_trace "Err: not found file 1: ${FN_FILE}"
    ERR=1
  fi
  if [ ! "${ERR}" = "0" ] ; then
    mr_trace "ignore line: ${MR_TYPE} ${MR_DESTINATION} ${MR_MEDIATYPE} ${MR_FILE}"
    continue
  fi

  case "${MR_TYPE}" in
  dashwebmgmerge)
    # audio
    # video
    # REDUCE: read until reach to a different key, then reduce it
    if [ ! "${PRE_DESTINATION_DASHWEBMGMERGE}" = "${FN_DEST_FILE}" ] ; then
      PID_CHILD=
      if [ ! "${PRE_DESTINATION_DASHWEBMGMERGE}" = "" ]; then
        # process the saved list
        worker_reduce_dashwebmgmerge_process "$(mp_get_session_id)" "${PRE_DESTINATION_DASHWEBMGMERGE}" "${FN_FILELIST_DASHWEBMGMERGE}" &
        PID_CHILD=$!
      fi

      DASHWEBMGMERGE_GRPCNT=0
      DASHWEBMGMERGE_FILECNT=0
      PRE_DESTINATION_DASHWEBMGMERGE="${FN_DEST_FILE}"
      FN_FILELIST_DASHWEBMGMERGE="${DN_DATATMP}/dashwebmgmerge-filelist-$(uuidgen).txt"
      cat /dev/null > "${FN_FILELIST_DASHWEBMGMERGE}" 1>&2

      mp_add_child_check_wait ${PID_CHILD}

    fi
    if [ ! "${DASHWEBMGMERGE_PRE_MEDIA}" = "${MR_MEDIATYPE}" ] ; then
      echo -e "-as id=${DASHWEBMGMERGE_GRPCNT},lang=eng" >> "${FN_FILELIST_DASHWEBMGMERGE}"
      DASHWEBMGMERGE_GRPCNT=$(( ${DASHWEBMGMERGE_GRPCNT} + 1 ))
      DASHWEBMGMERGE_PRE_MEDIA=${MR_MEDIATYPE}
    fi
    # "${PRE_DESTINATION_DASHWEBMGMERGE}" == "${FN_DEST_FILE}"
    # save the file name to list
    # get rid of duplicated files
    if [ "${PRE_SEGFILE_DASHWEBMGMERGE}" = "${FN_FILE}" ]; then
      echo -e "processederr\tdashwebmgmerge\tduplicated file: ${FN_FILE}" 1>&2
    else
      echo -e "-r id=${DASHWEBMGMERGE_FILECNT},file=${FN_FILE}" >> "${FN_FILELIST_DASHWEBMGMERGE}"
      DASHWEBMGMERGE_FILECNT=$(( ${DASHWEBMGMERGE_FILECNT} + 1 ))
    fi
    PRE_SEGFILE_DASHWEBMGMERGE="${FN_FILE}"
    ;;

  metricsvconcat)
    # REDUCE: read until reach to a different key, then reduce it
    if [ ! "${PRE_DESTINATION_MATRIC}" = "${FN_DEST_FILE}" ] ; then
      # process the saved list
      if [ ! "${PRE_DESTINATION_MATRIC}" = "" ]; then
        mv "${FN_TMP_MATRIC}" "${PRE_DESTINATION_MATRIC}" 1>&2
        echo -e "processedlog\tmetricsvconcat\t${PRE_DESTINATION_MATRIC}"
      fi

      PRE_DESTINATION_MATRIC="${FN_DEST_FILE}"
      FN_TMP_MATRIC="${DN_DATATMP}/mmcat-$(uuidgen).txt"
      cat /dev/null > "${FN_TMP_MATRIC}" 1>&2

    fi
    # get rid of duplicated files
    if [ "${PRE_SEGFILE_MATRIC}" = "${FN_FILE}" ]; then
      echo -e "processederr\tmetricsvconcat\tduplicated file: ${FN_FILE}" 1>&2
    else
      cat "${FN_FILE}" >> "${FN_TMP_MATRIC}"
    fi
    PRE_SEGFILE_MATRIC="${FN_FILE}"
    #${MYEXEC} ${DANGER_EXEC} rm -f "${FN_FILE}" 1>&2
    ;;

  dashmpd)
    #worker_reduce_dashmpd "$(mp_get_session_id)" "${FN_DEST_FILE}" "${FN_ORIG_FILE}" "${FN_VIDEO_FILE}" "${SEQ_FRAME}" "${SCR_RES}" &
    # REDUCE: read until reach to a different key, then reduce it
    if [ ! "${PRE_DESTINATION_DASHMPD}" = "${FN_DEST_FILE}" ] ; then
      PID_CHILD=
      if [ ! "${PRE_DESTINATION_DASHMPD}" = "" ]; then
        # process the saved list
        worker_reduce_dashmpd_process "$(mp_get_session_id)" "${PRE_DESTINATION_DASHMPD}" "${FN_FILELIST_DASHMPD}" &
        PID_CHILD=$!
      fi

      PRE_DESTINATION_DASHMPD="${FN_DEST_FILE}"
      FN_FILELIST_DASHMPD="${DN_DATATMP}/dashmpd-filelist-$(uuidgen).txt"
      cat /dev/null > "${FN_FILELIST_DASHMPD}" 1>&2

      mp_add_child_check_wait ${PID_CHILD}

    fi
    # "${PRE_DESTINATION_DASHMPD}" == "${FN_DEST_FILE}"
    # save the file name to list
    # get rid of duplicated files
    if [ "${PRE_SEGFILE_DASHMPD}" = "${FN_FILE}" ]; then
      echo -e "processederr\tdashmpd\tduplicated file: ${FN_FILE}" 1>&2
    else
      echo "${FN_FILE}" | ${EXEC_AWK} '{ print "file \"" $0 "\"" }' | tr \" \' >> "${FN_FILELIST_DASHMPD}"
    fi
    PRE_SEGFILE_DASHMPD="${FN_FILE}"
    ;;

  *)
    mr_trace "Err: unknown type: ${MR_TYPE}"
    continue
    ;;
  esac
  if [ ! "${ERR}" = "0" ] ; then
    mr_trace "ignore line: ${MR_TYPE} ${MR_DESTINATION} ${MR_MEDIATYPE} ${MR_FILE}"
    continue
  fi

done

if [ ! "${PRE_DESTINATION_MATRIC}" = "" ]; then
  if [ "${FN_TMP_MATRIC}" = "" ]; then
    mr_trace "Err: file list name: ${FN_TMP_MATRIC}"
    ERR=1
  fi
  if [ -f "${FN_TMP_MATRIC}" ]; then
    mv "${FN_TMP_MATRIC}" "${PRE_DESTINATION_MATRIC}"
    echo -e "processedlog\tmetricsvconcat\t${PRE_DESTINATION_MATRIC}"
  else
    mr_trace "Err: file list not exist: ${FN_TMP_MATRIC}"
    ERR=1
  fi
fi

if [ ! "${PRE_DESTINATION_DASHMPD}" = "" ]; then
  if [ "${FN_FILELIST_DASHMPD}" = "" ]; then
    mr_trace "Err: file list name: ${FN_FILELIST_DASHMPD}"
    ERR=1
  fi
  if [ -f "${FN_FILELIST_DASHMPD}" ]; then
    worker_reduce_dashmpd_process "$(mp_get_session_id)" "${PRE_DESTINATION_DASHMPD}" "${FN_FILELIST_DASHMPD}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
  else
    mr_trace "Err: file list not exist: ${FN_FILELIST_DASHMPD}"
    ERR=1
  fi
fi

if [ ! "${PRE_DESTINATION_DASHWEBMGMERGE}" = "" ]; then
  if [ "${FN_FILELIST_DASHWEBMGMERGE}" = "" ]; then
    mr_trace "Err: file list name: ${FN_FILELIST_DASHWEBMGMERGE}"
    ERR=1
  fi
  if [ -f "${FN_FILELIST_DASHWEBMGMERGE}" ]; then
    worker_reduce_dashwebmgmerge_process "$(mp_get_session_id)" "${PRE_DESTINATION_DASHWEBMGMERGE}" "${FN_FILELIST_DASHWEBMGMERGE}" &
    PID_CHILD=$!
    mp_add_child_check_wait ${PID_CHILD}
  else
    mr_trace "Err: file list not exist: ${FN_FILELIST_DASHWEBMGMERGE}"
    ERR=1
  fi
fi

mp_wait_all_children

# the last step
# remove temporarily directory
#${MYEXEC} ${DANGER_EXEC} rm -rf "${DN_DATATMP}/"* 1>&2
