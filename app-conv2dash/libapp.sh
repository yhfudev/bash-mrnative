#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief the library for the app
## @author Yunhui Fu <yhfudev@gmail.com>
## @copyright GPL v3.0 or later
## @version 1
##
#####################################################################

#config binary for map/reduce task
# <config line> format: "<map>,<reduce>,<# of output key>,<# of partition key>,<callback end function>"
#   java streaming argument 'stream.num.map.output.key.fields' is map to '# of output key'
#   java streaming argument 'num.key.fields.for.partition' is map to '# of partition key'
#   stream.num.map.output.key.fields >= num.key.fields.for.partition
#   'callback end function' is called at the end of function
#
# config line example: "e1map.sh,e1red.sh,6,5,cb_end_stage1"
LIST_MAPREDUCE_WORK="e1map.sh,e1red.sh,4,4, e2map.sh,e2red.sh,3,2, ,e3red.sh,4,2,"
#LIST_MAPREDUCE_WORK="e1map.sh,e1red.sh,4,4, e2map.sh,e2red.sh,3,2,"
#LIST_MAPREDUCE_WORK="e1map.sh,e1red.sh,4,4, e2map.sh,,3,2,"
#LIST_MAPREDUCE_WORK="e1map.sh,e1red.sh,4,4,"
#LIST_MAPREDUCE_WORK="e1map.sh,,4,4,"

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
#DN_EXEC=$(dirname $(my_getpath "$0") )
#####################################################################
EXEC_FFMPEG=$(which "ffmpeg")
EXEC_FFPROBE=$(which "ffprobe")
EXEC_QTFAST=$(which "qt-faststart")
EXEC_SSIM=$(which "mediametrics")
EXEC_SAMPLEMUXER=$(which "sample_muxer")
EXEC_WEBMDASH_MANIFEST=$(which "webm_dash_manifest")
EXEC_MP4BOX=$(which "MP4Box")
EXEC_ITEC_MPDSEG=$(which "create_mpd_segment_info.py")

FN_CONF_FFMPEG="${DN_EXEC}/config-conv2dash.conf"

if [ ! "${DN_EXEC_4HADOOP}" = "" ]; then
    DN_EXEC="${DN_EXEC_4HADOOP}"
    DN_TOP="${DN_TOP_4HADOOP}"
    FN_CONF_SYS="${FN_CONF_SYS_4HADOOP}"
fi

RET=$(is_file_or_dir "${FN_CONF_SYS}")
if [ ! "${RET}" = "f" ]; then
    FN_CONF_SYS="${DN_EXEC}/mrsystem-working.conf"
    RET=$(is_file_or_dir "${FN_CONF_SYS}")
    if [ ! "${RET}" = "f" ]; then
        FN_CONF_SYS="${DN_TOP}/mrsystem.conf"
        RET=$(is_file_or_dir "${FN_CONF_SYS}")
        if [ ! "${RET}" = "f" ]; then
            mr_trace "not found config file: ${FN_CONF_SYS}"
        fi
    fi
fi
#####################################################################
## @fn generate_default_conv2dash_config()
## @brief generate a default config file for conv2dash
## @param fn the config file name
##
generate_default_conv2dash_config() {
    local PARAM_FN_CONFIG=$1
    shift
    cat << EOF > "${PARAM_FN_CONFIG}"

# if generate the snapshot picture, set it to 1
HDFF_SNAPSHOT=1

# the resolutions for transcoding
# video resolution + video bitrate + audio bitrate
#HDFF_TRANSCODE_RESOLUTIONS=320x180+315k+64k,640x360+500k+64k,853x480+1000k+192k,1280x720+1500k+256k,1280x720+2600k+256k,1920x1080+3800k+256k,1920x1080+4800k+256k,3840x1714+9000k+256k,3840x1714+12000k+256k
#HDFF_TRANSCODE_RESOLUTIONS=320x180+315k+64k,640x360+500k+64k,853x480+1000k+192k
HDFF_TRANSCODE_RESOLUTIONS=320x180+315k+64k,640x360+500k+64k

# the screen size for mmetrics
# http://en.wikipedia.org/wiki/File:Vector_Video_Standards2.svg
# HD 1.78:1(16:9), ?,?,?,720p,1080p(2k),4k,8k
#HDFF_SCREEN_RESOLUTIONS=320x180,640x360,854x480,1280x720,1920x1080,3840x2160,7680x4320
#HDFF_SCREEN_RESOLUTIONS=320x180,640x360
HDFF_SCREEN_RESOLUTIONS=320x180

# WHXGA 1.60:1 (16:10), 4k
#HDFF_SCREEN_RESOLUTIONS=320x200,1280x800,1680x1050,1920x1200,2560x1600,5120x3200

# VGA 1.33:1 (4:3); QVGA,VGA,PAL,SVGA,XGA,?,SXGA+,UXGA,QXGA
#HDFF_SCREEN_RESOLUTIONS=320x240,640x480,768x576,800x600,1024x786,1280x960,1400x1050,1600x1200,2048x1536


# global options for ffmpeg
#OPTIONS_FFM_GLOBAL="-threads 0"
OPTIONS_FFM_GLOBAL=
OPTIONS_FFM_ASYNC="-async 2286 -vsync 2"
OPTIONS_FFM_AUDIO=
#OPTIONS_FFM_VIDEO="-keyint_min 48 -g 48"
# -keyint_min <Minimum GOP length, the minimum distance between I-frames. Recommended default: 25>
# -g <Keyframe interval, GOP length>
OPTIONS_FFM_VIDEO="-keyint_min 150 -g 150 -sc_threshold 0"

# the transcode codec for the ffmpeg -- using mpeg4
#OPTIONS_FFM_VCODEC="-vcodec mpeg4"
#OPTIONS_FFM_ACODEC="-c:a aac -strict -2"
#OPTIONS_FFM_VCODEC_SUFFIX="mp4"

# the transcode codec for the ffmpeg -- using webm
#OPTIONS_FFM_VCODEC="-vcodec libvpx-vp9 -strict experimental"
OPTIONS_FFM_VCODEC="-vcodec libvpx"
OPTIONS_FFM_ACODEC="-c:a libvorbis"
OPTIONS_FFM_VCODEC_SUFFIX="webm"

EOF
}

#####################################################################
mr_trace "DN_TOP=${DN_TOP}, DN_EXEC=${DN_EXEC}, FN_CONF_SYS=${FN_CONF_SYS}"

RET0=$(is_file_or_dir "${FN_CONF_SYS}")
if [ ! "$RET0" = "f" ]; then
    echo -e "debug\t$(hostname)\tgenerated_config\t${FN_CONF_SYS}"
    mr_trace "Warning: not found config file '${FN_CONF_SYS}'!"
    mr_trace "generating new config file '${FN_CONF_SYS}' ..."
    generate_default_config | save_file "${FN_CONF_SYS}"
fi
FN_TMP_1m="/tmp/config-$(uuidgen)"
copy_file "${FN_CONF_SYS}" "${FN_TMP_1m}" 1>&2
read_config_file "${FN_TMP_1m}"

FN_TMP_1m="/tmp/config-$(uuidgen)"

RET0=$(is_file_or_dir "${FN_CONF_FFMPEG}")
if [ ! "$RET0" = "f" ]; then
    mr_trace "Warning: not found config file '${FN_CONF_FFMPEG}'!"

    # generate default application configs?
    generate_default_conv2dash_config "${FN_TMP_1m}"

else
    copy_file "${FN_CONF_FFMPEG}" "${FN_TMP_1m}" 1>&2
fi
read_config_file "${FN_TMP_1m}"

if [ $(is_local "${FN_TMP_1m}") = l ]; then
    #cat_file "${FN_TMP_1m}" | awk -v P=debug -v H=$(hostname) '{print P "\t" H "\ttmpconfig____"$0}'
    rm_f_dir "${FN_TMP_1m}" 1>&2
else
    echo -e "debug\tError_file_is_not_local\t${FN_TMP_1m}"
fi
check_global_config

mr_trace "DN_TOP=${DN_TOP}, DN_EXEC=${DN_EXEC}, FN_CONF_SYS=${FN_CONF_SYS}"
mr_trace "HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"
#echo -e "debug\tFN_CONF_SYS=${FN_CONF_SYS},FN_TMP=${FN_TMP_1m},HDFF_FN_TAR_MRNATIVE=${HDFF_FN_TAR_MRNATIVE}"

DN_DATATMP="${HDFF_DN_SCRATCH}"

## @fn extrace_binary()
## @brief untar the app binary
## @param fn_tar the file name
##
## untar the app binary from the file specified by HDFF_PATHTO_TAR_APP
extrace_binary() {
    local PARAM_FN_TAR=$1
    shift

    local RET=$(is_local "${HDFF_DN_BIN}")
    if [ ! "${RET}" = "l" ]; then
        mr_trace "Error: binary is not local dir: ${HDFF_DN_BIN}"
        echo -e "error-extractbin\tnot-local-dir\t${HDFF_DN_BIN}"
        exit 1
    fi
    mr_trace "extract ${PARAM_FN_TAR} to dir ${HDFF_DN_BIN} ..."
    extract_file "${PARAM_FN_TAR}" ${HDFF_DN_BIN} >/dev/null 2>&1
    P=$(echo $(basename "${PARAM_FN_TAR}") | awk -F. '{name=$1; for (i=2; i + 1 < NF; i ++) name=name "." $i } END {print name}')

    #DN=$(ls ${HDFF_DN_BIN}/${P}* | head -n 1)
    mr_trace "DN1=$(ls ${HDFF_DN_BIN}/${P}* | head -n 1)"
    DN="${HDFF_DN_BIN}/${P}"
    mr_trace "DN=$DN"
    echo $DN
}

# find the exec from default dir
find_exec_inst() {
    local PARAM_EXEC_NAME=$1
    shift
    lst_app_dirs=("$(my_getpath "${DN_TOP}/../../")")
    if [ ! "${HDFF_PATHTO_TAR_APP}" = "" ]; then
        local DN2=$(extrace_binary "${HDFF_PATHTO_TAR_APP}")
        lst_app_dirs+=(
                "$(my_getpath "${DN2}/usr/bin/")"
                )
    fi

    lst_app_dirs+=(
        "/home/$USER/ffmpeg-i686/usr/bin/"
              "$HOME/ffmpeg-i686/usr/bin/"
        "/home/$USER/ffmpeg-x86_64/usr/bin/"
              "$HOME/ffmpeg-x86_64/usr/bin/"
        "/home/$USER/software/bin/ffmpeg-bin/bin/"
              "$HOME/software/bin/ffmpeg-bin/bin/"
        "/home/$USER/bin/"
              "$HOME/bin/"
        )
    if [ ! -x "${EXEC_RET}" ]; then
        CNT=0
        while [[ ${CNT} < ${#lst_app_dirs[*]} ]] ; do
            mr_trace "try detect ${PARAM_EXEC_NAME} lst_app_dirs(${CNT}):" ${lst_app_dirs[${CNT}]}
            if [ -x "${lst_app_dirs[${CNT}]}/${PARAM_EXEC_NAME}" ]; then
                EXEC_RET=${lst_app_dirs[${CNT}]}/${PARAM_EXEC_NAME}
                mr_trace "found: $EXEC_RET"
                break
            fi
            CNT=$(( $CNT + 1 ))
        done
    fi
    if [ ! -x "${EXEC_RET}" ]; then
        EXEC_RET=$(which ${PARAM_EXEC_NAME})
        mr_trace "try detect ${PARAM_EXEC_NAME} 13: ${EXEC_RET}"
    fi
    mr_trace "EXEC_RET=${EXEC_RET}"
    echo "${EXEC_RET}"
}

## @fn libapp_prepare_app_binary()
## @brief setup some environment variable for application
##
## to setup some environment variable for application
## and extract the apllication binaries and data if the config HDFF_PATHTO_TAR_APP exist
## (MUST be implemented)
libapp_prepare_app_binary() {
    EXEC_FFMPEG=$(find_exec_inst "ffmpeg")
    EXEC_FFPROBE=$(find_exec_inst "ffprobe")
    EXEC_QTFAST=$(find_exec_inst "qt-faststart")
    EXEC_SSIM=$(find_exec_inst "mediametrics")
    EXEC_SAMPLEMUXER=$(find_exec_inst "sample_muxer")
    EXEC_WEBMDASH_MANIFEST=$(find_exec_inst "webm_dash_manifest")
    EXEC_MP4BOX=$(find_exec_inst "MP4Box")
    EXEC_ITEC_MPDSEG=$(find_exec_inst "create_mpd_segment_info.py")
    mr_trace "EXEC_FFMPEG=${EXEC_FFMPEG}"
    if [ -x "${EXEC_FFMPEG}" ]; then
        detect_gawk_from    "$(dirname ${EXEC_NS2})"
        detect_gnuplot_from "$(dirname ${EXEC_NS2})"
        if [ "$?" = "0" ]; then
            GNUPLOT_PS_DIR="$(dirname ${EXEC_PLOT})/../share/gnuplot/5.0/PostScript/"
            export GNUPLOT_PS_DIR="$(my_getpath "${GNUPLOT_PS_DIR}")"
            GNUPLOT_LIB="$(dirname ${EXEC_PLOT})/../share/gnuplot/5.0/"
            export GNUPLOT_LIB="$(my_getpath "${GNUPLOT_LIB}")"
            LD_LIBRARY_PATH="$(dirname ${EXEC_PLOT})/../lib"
            export LD_LIBRARY_PATH="$(my_getpath "${LD_LIBRARY_PATH}")"
        fi
    else
        mr_trace "Error: not found ffmpeg"
        echo -e "error-prepapp\tNOT-get-file\tffmpeg"
    fi
    echo -e "env\tffmpeg=${EXEC_FFMPEG}\tgawk=${EXEC_AWK}\tplot=${EXEC_PLOT}\tlib=${GNUPLOT_LIB}\tpsdir=${GNUPLOT_PS_DIR}\tLD=${LD_LIBRARY_PATH}"
}

## @fn libapp_prepare_mrnative_binary()
## @brief untar the mrnative binary (this package)
##
## untar the mrnative binary from the file specified by HDFF_PATHTO_TAR_MRNATIVE
## return the path to the untar files
## (MUST be implemented)
libapp_prepare_mrnative_binary() {
    if [ "${HDFF_PATHTO_TAR_MRNATIVE}" = "" ]; then
        # detect the marnative dir
        mr_trace "Error: not found mrnative file '${HDFF_PATHTO_TAR_MRNATIVE}'"
        #echo -e "error-prepnative\tnot-get-tarfile\tHDFF_PATHTO_TAR_MRNATIVE=${HDFF_PATHTO_TAR_MRNATIVE}"
    else
        local DN2=$(extrace_binary "${HDFF_PATHTO_TAR_MRNATIVE}")
        if [ -d "${DN2}" ] ; then
            DN_TOP=$(my_getpath "${DN2}")
            mr_trace "[DBG] set top dir to '${DN_TOP}'"
        else
            mr_trace "Error: not found mrnative top dir '${DN2}'"
            echo -e "error-prepnative\tnot-get-dir\t${DN2}"
        fi
    fi
}


## @fn libapp_get_tasks_number_from_config()
## @brief get number of simulation tasks from a config file
## @param fn_config the config file name
##
## (MUST be implemented)
libapp_get_tasks_number_from_config() {
    local PARAM_FN_CONFIG=$1
    shift

    NUM_SCHE=1
    NUM_NODES=1
    NUM_TYPE=1
    cat "${PARAM_FN_CONFIG}" | while read get_sim_tasks_each_file_tmp_a; do
        A=$( echo $get_sim_tasks_each_file_tmp_a | grep LIST_TYPES | sed -e 's|LIST_TYPES="\(.*\)"$|\1|' )
        if [ ! "$A" = "" ]; then
            arr=($A)
            NUM_TYPE=${#arr[@]}
            #echo "$(basename $0) [DBG] got type=$NUM_TYPE, A=$A, from line $get_sim_tasks_each_file_tmp_a" 1>&2
        fi
        A=$( echo $get_sim_tasks_each_file_tmp_a | grep LIST_NODE_NUM | sed -e 's|LIST_NODE_NUM="\(.*\)"$|\1|' )
        if [ ! "$A" = "" ]; then
            arr=($A)
            NUM_NODES=${#arr[@]}
            #echo "$(basename $0) [DBG] got node=$NUM_NODES, A=$A, from line $get_sim_tasks_each_file_tmp_a" 1>&2
        fi
        A=$( echo $get_sim_tasks_each_file_tmp_a | grep LIST_SCHEDULERS | sed -e 's|LIST_SCHEDULERS="\(.*\)"$|\1|' )
        if [ ! "$A" = "" ]; then
            arr=($A)
            NUM_SCHE=${#arr[@]}
            #echo "$(basename $0) [DBG] got sch=$NUM_SCHE, A=$A, from line $get_sim_tasks_each_file_tmp_a" 1>&2
        fi
    done
    #mr_trace "type=$NUM_TYPE, sch=$NUM_SCHE, node=$NUM_NODES"
    mr_trace "got type=$NUM_TYPE, sch=$NUM_SCHE, node=$NUM_NODES"
    echo $(( $NUM_TYPE * $NUM_SCHE * $NUM_NODES ))
}

## @fn libapp_generate_script_4hadoop()
## @brief generate scripts for Hadoop environment
## @param orig the path to the app
## @param output the generated script file name
##
## generate scripts for Hadoop environment, because there's no PATH env in it
## (MUST be implemented)
libapp_generate_script_4hadoop() {
    local PARAM_ORIG="$1"
    shift
    local PARAM_OUTPUT="$1"
    shift

    local DN_FILE9=$(dirname "${PARAM_ORIG}")
    local DN_EXEOUT9=$(dirname "${PARAM_OUTPUT}")

    local RET=
    RET=$(is_file_or_dir "${DN_EXEOUT9}")
    if [ ! "${RET}" = "d" ]; then
        make_dir "${DN_EXEOUT9}"
        RET=$(is_file_or_dir "${DN_EXEOUT9}")
        if [ ! "${RET}" = "d" ]; then mr_trace "Error in mkdir $DN_EXEOUT9"; fi
    fi

    rm_f_dir "${PARAM_OUTPUT}"
    mr_trace "generating ${PARAM_OUTPUT} ..."
    echo '#!/bin/bash'                      | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC_4HADOOP=${DN_EXEC}"       | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP_4HADOOP=${DN_TOP}"         | save_file "${PARAM_OUTPUT}"
    echo "FN_CONF_SYS_4HADOOP=${FN_CONF_SYS}" | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC=${DN_EXEC}"               | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP=${DN_TOP}"                 | save_file "${PARAM_OUTPUT}"
    echo "FN_CONF_SYS=${FN_CONF_SYS}"       | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_FILE9}/mod-setenv-hadoop.sh" | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libbash.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libshrt.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libfs.sh"       | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libplot.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libconfig.sh"   | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_FILE9}/libns2figures.sh" | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_FILE9}/libapp.sh"        | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC_4HADOOP=${DN_EXEC}"       | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP_4HADOOP=${DN_TOP}"         | save_file "${PARAM_OUTPUT}"
    echo "DN_EXEC=${DN_EXEC}"               | save_file "${PARAM_OUTPUT}"
    echo "DN_TOP=${DN_TOP}"                 | save_file "${PARAM_OUTPUT}"
    cat_file "${PARAM_ORIG}"    \
        | grep -v "libbash.sh"  \
        | grep -v "libshrt.sh"  \
        | grep -v "libfs.sh"    \
        | grep -v "libplot.sh"  \
        | grep -v "libconfig.sh"    \
        | grep -v "libns2figures.sh" \
        | grep -v "libapp.sh"   \
        | sed -e "s|EXEC_FFMPEG=.*$|EXEC_FFMPEG=$(which ffmpeg)|" \
        | sed -e "s|EXEC_FFPROBE=.*$|EXEC_FFPROBE=$(which ffprobe)|" \
        | sed -e "s|EXEC_QTFAST=.*$|EXEC_QTFAST=$(which qt-faststart)|" \
        | sed -e "s|EXEC_SSIM=.*$|EXEC_SSIM=$(which mediametrics)|" \
        | sed -e "s|EXEC_SAMPLEMUXER=.*$|EXEC_SAMPLEMUXER=$(which sample_muxer)|" \
        | sed -e "s|EXEC_WEBMDASH_MANIFEST=.*$|EXEC_WEBMDASH_MANIFEST=$(which webm_dash_manifest)|" \
        | sed -e "s|EXEC_MP4BOX=.*$|EXEC_MP4BOX=$(which MP4Box)|" \
        | sed -e "s|EXEC_ITEC_MPDSEG=.*$|EXEC_ITEC_MPDSEG=$(which create_mpd_segment_info.py)|" \
        | save_file "${PARAM_OUTPUT}"
}

## @fn libapp_prepare_execution_config()
## @brief generate the TCL scripts for all of the settings
## @param command the command
## @param fn_config_proj the config file of the application
##
## my_getpath, DN_EXEC, HDFF_DN_OUTPUT, should be defined before call this function
## HDFF_DN_SCRATCH should be in global config file (mrsystem.conf)
## PREFIX, LIST_NODE_NUM, LIST_TYPES, LIST_SCHEDULERS should be in the config file passed by argument
## (MUST be implemented)
libapp_prepare_execution_config () {
    local PARAM_COMMAND=$1
    shift
    local PARAM_FN_CONFIG_PROJ=$1
    shift

    local FN_TMP1="/tmp/config-$(uuidgen)"
    mr_trace "read proj config file: ${PARAM_FN_CONFIG_PROJ} ..."
    copy_file "${PARAM_FN_CONFIG_PROJ}" "${FN_TMP1}" > /dev/null 2>&1
    read_config_file "${FN_TMP1}"
    rm_f_dir "${FN_TMP1}" > /dev/null 2>&1

    mr_trace "prepare_all_tcl_scripts, HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"

    DN_TMP_CREATECONF="${HDFF_DN_SCRATCH}/tmp-createconf-$(uuidgen)"
    rm_f_dir "${DN_TMP_CREATECONF}" >/dev/null 2>&1
    make_dir "${DN_TMP_CREATECONF}" >/dev/null 2>&1
    mr_trace "LIST_NODE_NUM='${LIST_NODE_NUM}'"
    mr_trace "LIST_TYPES='${LIST_TYPES}'"
    mr_trace "LIST_SCHEDULERS='${LIST_SCHEDULERS}'"
    for idx_num9 in $LIST_NODE_NUM ; do
        for idx_type9 in $LIST_TYPES ; do
            for idx_sche9 in $LIST_SCHEDULERS ; do
                mr_trace "prefix='${PREFIX}', type='$idx_type9', sche='$idx_sche9', num='$idx_num9', exec='${DN_EXEC}', comm='${DN_COMM}', tmp='${DN_TMP_CREATECONF}'"
                case "${PARAM_COMMAND}" in
                sim)
                    prepare_one_tcl_scripts "${PREFIX}" "$idx_type9" "$idx_sche9" "$idx_num9" "${DN_EXEC}" "${DN_COMM}" "${DN_TMP_CREATECONF}"
                    ;;
                esac
                echo -e "${PARAM_COMMAND}\t\"${PARAM_FN_CONFIG_PROJ}\"\t\"${PREFIX}\"\t\"${idx_type9}\"\tunknown\t\"${idx_sche9}\"\t${idx_num9}"
            done
        done
    done
    make_dir "${HDFF_DN_OUTPUT}/dataconf/" > /dev/null 2>&1

    #DN_ORIG15=$(pwd)
    #cd "${DN_TMP_CREATECONF}"
    #tar -cf - * | tar -C "${HDFF_DN_OUTPUT}/dataconf/" -xf -
    #cd "${DN_ORIG15}"

    case "${PARAM_COMMAND}" in
    sim)
        mr_trace "create conf: rsync from temp to result dir: ${DN_TMP_CREATECONF}/ --> ${HDFF_DN_OUTPUT}/dataconf/"
        #rsync -av --log-file "${HDFF_DN_OUTPUT}/rsync-log-createconf-copyback-1-${PREFIX}.log" "${DN_TMP_CREATECONF}/" "${HDFF_DN_OUTPUT}/dataconf/" 1>&2
        RET=$(copy_file "${DN_TMP_CREATECONF}/" "${HDFF_DN_OUTPUT}/dataconf/")
        #rm_f_dir "${DN_TMP_CREATECONF}/"*
        if [ ! "$RET" = "0" ]; then
            mr_trace "Error: copy temp dir: ${DN_TMP_CREATECONF}/ to ${HDFF_DN_OUTPUT}/dataconf/"
            exit 1
        fi
        ;;
    esac

    #rm_f_dir "${DN_TMP_CREATECONF}"

    mr_trace "DONE create config files"
}


