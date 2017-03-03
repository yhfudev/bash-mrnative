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
LIST_MAPREDUCE_WORK="e1map.sh,,3,2, e2map.sh,,2,1,"


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
EXEC_HASHCAT=$(which "hashcat")
EXEC_AIRCRACK=$(which "aircrack-ng")
EXEC_PYRIT=$(which "pyrit")
EXEC_WPACLEAN=$(which "wpaclean")

FN_CONF_HASHCAT="${DN_EXEC}/config-wpapw.conf"

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
## @fn generate_default_wpapw_config()
## @brief generate a default config file for wpapw
## @param fn the config file name
##
generate_default_wpapw_config() {
    local PARAM_FN_CONFIG=$1
    shift
    cat << EOF > "${PARAM_FN_CONFIG}"
# the config file for the application

# the word list
#HDFF_WORDLISTS=wl1.txt,wl2.txt
HDFF_WORDLISTS=

# the rule list for the hashcat
#HDFF_RULELISTS=best64,combinator
HDFF_RULELISTS=

# the number of entries for each segment of wordlist/pattern
# default: 10m
HDFF_SIZE_SEGMENT=10000000

# if we use mask, such as ?d?d?d?d?d for hashcat
HDFF_USE_MASK=1
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

RET0=$(is_file_or_dir "${FN_CONF_HASHCAT}")
if [ ! "$RET0" = "f" ]; then
    mr_trace "Warning: not found config file '${FN_CONF_HASHCAT}'!"

    # generate default application configs?
    generate_default_wpapw_config "${FN_TMP_1m}"

else
    copy_file "${FN_CONF_HASHCAT}" "${FN_TMP_1m}" 1>&2
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
    PARAM_FN_TAR=$1
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

## @fn libapp_prepare_app_binary()
## @brief setup some environment variable for application
##
## to setup some environment variable for application
## and extract the apllication binaries and data if the config HDFF_PATHTO_TAR_APP exist
## (MUST be implemented)
libapp_prepare_app_binary() {
    if [ "${HDFF_PATHTO_TAR_APP}" = "" ]; then
        # detect the application execuable
        EXEC_HASHCAT="$(my_getpath "${DN_TOP}/3rd/aircrack-bin/usr/bin/hashcat")"
        mr_trace "try detect hashcat 1: ${EXEC_HASHCAT}"
        #echo -e "error-prepapp\ttry-get-file\t${DN_TOP}/3rd/aircrack-bin/usr/bin/hashcat"
    else
        local DN2=$(extrace_binary "${HDFF_PATHTO_TAR_APP}")
        EXEC_HASHCAT="$(my_getpath "${DN2}/usr/bin/hashcat")"
        mr_trace "try detect hashcat 2: ${EXEC_HASHCAT}"
        if [ ! -x "${EXEC_HASHCAT}" ]; then
            EXEC_HASHCAT="$(my_getpath "${DN2}/hashcat-git/hashcat")"
            mr_trace "try detect hashcat 3: ${EXEC_HASHCAT}"
        fi
        #echo -e "error-prepapp\ttry-get-file\t${DN2}/usr/bin/hashcat"
        if [ ! -x "${EXEC_HASHCAT}" ]; then
            EXEC_HASHCAT="$(dirname ${DN2})/aircrack-git-x86_64/usr/bin/hashcat"
            mr_trace "try detect hashcat 3: ${EXEC_HASHCAT}"
            #echo -e "error-prepapp\ttry-get-file\t${EXEC_HASHCAT}"
        fi
        if [ ! -x "${EXEC_HASHCAT}" ]; then
            EXEC_HASHCAT="${HDFF_DN_BIN}/aircrack-git-x86_64/usr/bin/hashcat"
            mr_trace "try detect hashcat 4: ${EXEC_HASHCAT}"
            #echo -e "error-prepapp\ttry-get-file\t${EXEC_HASHCAT}"
        fi
        if [ ! -x "${EXEC_HASHCAT}" ]; then
            EXEC_HASHCAT="$(dirname ${HDFF_PATHTO_TAR_APP})/aircrack-git-x86_64/usr/bin/hashcat"
            mr_trace "try detect hashcat 5: ${EXEC_HASHCAT}"
            #echo -e "error-prepapp\ttry-get-file\t${EXEC_HASHCAT}"
        fi
    fi

    lst_app_dirs=(
        "/home/$USER/aircrack-bin/usr/bin/hashcat"
              "$HOME/aircrack-bin/usr/bin/hashcat"
        "/home/$USER/software/bin/aircrack-bin/bin/hashcat"
              "$HOME/software/bin/aircrack-bin/bin/hashcat"
        "/home/$USER/aircrack-git-x86_64/usr/bin/hashcat"
              "$HOME/aircrack-git-x86_64/usr/bin/hashcat"
        "/home/$USER/working/vmshare/ns2docsis-1.0-workingspace/aircrack-git-x86_64/usr/bin/hashcat"
              "$HOME/working/vmshare/ns2docsis-1.0-workingspace/aircrack-git-x86_64/usr/bin/hashcat"
        "/home/$USER/bin/hashcat"
              "$HOME/bin/hashcat"
        )
    if [ ! -x "${EXEC_HASHCAT}" ]; then
        CNT=0
        while [[ ${CNT} < ${#lst_app_dirs[*]} ]] ; do
            mr_trace "try detect hashcat lst_app_dirs(${CNT}):" ${lst_app_dirs[${CNT}]}
            if [ -x "${lst_app_dirs[${CNT}]}" ]; then
                EXEC_HASHCAT=${lst_app_dirs[${CNT}]}
                mr_trace "found: $EXEC_HASHCAT"
                detect_gawk_from "$(dirname ${EXEC_HASHCAT})"
                detect_gnuplot_from "$(dirname ${EXEC_HASHCAT})"
                break
            fi
            CNT=$(( $CNT + 1 ))
        done
    fi
    if [ ! -x "${EXEC_HASHCAT}" ]; then
        EXEC_HASHCAT=$(which hashcat)
        mr_trace "try detect hashcat 13: ${EXEC_HASHCAT}"
    fi
    mr_trace "EXEC_HASHCAT=${EXEC_HASHCAT}"
    if [ -x "${EXEC_HASHCAT}" ]; then
        detect_gawk_from    "$(dirname ${EXEC_HASHCAT})"
        detect_gnuplot_from "$(dirname ${EXEC_HASHCAT})"
        if [ "$?" = "0" ]; then
            GNUPLOT_PS_DIR="$(dirname ${EXEC_PLOT})/../share/gnuplot/5.0/PostScript/"
            export GNUPLOT_PS_DIR="$(my_getpath "${GNUPLOT_PS_DIR}")"
            GNUPLOT_LIB="$(dirname ${EXEC_PLOT})/../share/gnuplot/5.0/"
            export GNUPLOT_LIB="$(my_getpath "${GNUPLOT_LIB}")"
            LD_LIBRARY_PATH="$(dirname ${EXEC_PLOT})/../lib"
            export LD_LIBRARY_PATH="$(my_getpath "${LD_LIBRARY_PATH}")"
        fi
    else
        mr_trace "Error: not found hashcat"
        echo -e "error-prepapp\tNOT-get-file\thashcat"
    fi

    #EXEC_AIRCRACK=`which aircrack-ng`
    if [ ! -x "${EXEC_AIRCRACK}" ]; then
        EXEC_AIRCRACK="$(dirname ${EXEC_HASHCAT})/aircrack-ng"
        mr_trace "try detect aircrack-ng 1: ${EXEC_AIRCRACK}"
    fi
    if [ ! -x "${EXEC_AIRCRACK}" ]; then
        EXEC_AIRCRACK=$(which aircrack-ng)
        mr_trace "try detect aircrack-ng 2: ${EXEC_AIRCRACK}"
    fi
    if [ ! -x "${EXEC_AIRCRACK}" ]; then
        mr_trace "Error: not found aircrack-ng"
        echo -e "error-prepapp\tNOT-get-file\taircrack-ng"
    fi

if [ 0 = 1 ]; then
    #EXEC_PYRIT=`which pyrit`
    if [ ! -x "${EXEC_PYRIT}" ]; then
        EXEC_PYRIT="$(dirname ${EXEC_HASHCAT})/pyrit"
        mr_trace "try detect pyrit 1: ${EXEC_PYRIT}"
    fi
    if [ ! -x "${EXEC_PYRIT}" ]; then
        EXEC_PYRIT=$(which pyrit)
        mr_trace "try detect pyrit 2: ${EXEC_PYRIT}"
    fi
    if [ ! -x "${EXEC_PYRIT}" ]; then
        mr_trace "Error: not found pyrit"
        echo -e "error-prepapp\tNOT-get-file\tpyrit"
    fi
fi

    echo -e "env\thashcat=${EXEC_HASHCAT}\tgawk=${EXEC_AWK}\tplot=${EXEC_PLOT}\tlib=${GNUPLOT_LIB}\tpsdir=${GNUPLOT_PS_DIR}\tLD=${LD_LIBRARY_PATH}"
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
        | sed -e "s|EXEC_HASHCAT=.*$|EXEC_HASHCAT=$(which hashcat)|" \
        | save_file "${PARAM_OUTPUT}"
}


## @fn libapp_prepare_execution_config()
## @brief generate scripts for all of the settings
## @param command the command
## @param fn_config_proj the config file of the application
##
## my_getpath, DN_EXEC, HDFF_DN_OUTPUT, should be defined before call this function
## HDFF_DN_SCRATCH should be in global config file (mrsystem.conf)
## PREFIX, LIST_NODE_NUM, LIST_TYPES, LIST_SCHEDULERS should be in the config file passed by argument
## (MUST be implemented)
libapp_prepare_execution_config() {
    local PARAM_COMMAND=$1
    shift
    local PARAM_FN_CONFIG_PROJ=$1
    shift

    local FN_TMP1="/tmp/config-$(uuidgen)"
    mr_trace "read proj config file: ${PARAM_FN_CONFIG_PROJ} ..."
    copy_file "${PARAM_FN_CONFIG_PROJ}" "${FN_TMP1}" > /dev/null 2>&1
    read_config_file "${FN_TMP1}"
    rm_f_dir "${FN_TMP1}" > /dev/null 2>&1

    mr_trace "parse the config file, HDFF_DN_SCRATCH=${HDFF_DN_SCRATCH}"

    DN_TMP_CREATECONF="${HDFF_DN_SCRATCH}/tmp-createconf-$(uuidgen)"
    rm_f_dir "${DN_TMP_CREATECONF}" >/dev/null 2>&1
    make_dir "${DN_TMP_CREATECONF}" >/dev/null 2>&1
    mr_trace "HDFF_WORDLISTS='${HDFF_WORDLISTS}'"
    mr_trace "HDFF_RULELISTS='${HDFF_RULELISTS}'"
    mr_trace "HDFF_SIZE_SEGMENT='${HDFF_SIZE_SEGMENT}'"
    mr_trace "HDFF_USE_MASK='${HDFF_USE_MASK}'"

    #rm_f_dir "${DN_TMP_CREATECONF}"

    mr_trace "DONE create config files"
}

#####################################################################
#HDFF_DN_SCRATCH="/dev/shm/$USER/"

# PARAM_DN_PARENT -- the parent dir for the data to be saved.
# PARAM_DN_TEST   -- the sub dir for the data, related dir name to PARAM_DN_PARENT
# PARAM_FN_CONFIG_PROJ -- the config file for this simulation
run_one_ns2 () {
    local PARAM_DN_PARENT=$1
    shift
    local PARAM_DN_TEST=$1
    shift
    local PARAM_FN_CONFIG_PROJ=$1
    shift

    # read in the config file for this test group
    # in this case, is to read the config for USE_MEDIUMPACKET
    local FN_TMP2="/tmp/config-$(uuidgen)"
    copy_file "${PARAM_FN_CONFIG_PROJ}" "${FN_TMP2}" > /dev/null 2>&1
    read_config_file "${FN_TMP2}"
    rm_f_dir "${FN_TMP2}" > /dev/null 2>&1

    # set the scratch dir, which is used to store temperary files.
    local RET=0

    local DN_WORKING="${PARAM_DN_PARENT}/${PARAM_DN_TEST}/"
    local FLG_USETMP=0
    RET=$(is_local "${PARAM_DN_PARENT}")
    if [ ! "${RET}" = "l" ]; then
        FLG_USETMP=1
    fi
    if [ ! "${HDFF_DN_SCRATCH}" = "" ]; then
        FLG_USETMP=1
    fi
    DN_ORIG2=$(pwd)
    if [ ! "${FLG_USETMP}" = "0" ]; then
        RET=$(is_local "${HDFF_DN_SCRATCH}")
        if [ ! "${RET}" = "l" ]; then
            mr_trace "Error in prepare the scratch dir: ${HDFF_DN_SCRATCH}"
            return
        fi

        DN_WORKING="${HDFF_DN_SCRATCH}/run-${PARAM_DN_TEST}-$(uuidgen)/"
        mkdir -p "${DN_WORKING}" > /dev/null 2>&1
        mr_trace "run ns2: copy from parent to working dir: ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/ --> ${DN_WORKING}/"
        #rsync -av --log-file "${PARAM_DN_PARENT}/rsync-log-runns2-copytemp-1.log" "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" "${DN_WORKING}/" 1>&2
        mr_trace "copy ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/*.tcl to ${DN_WORKING}/"
        find_file "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" -name "*.tcl" | while read a; do mr_trace "copy ${a} to ${DN_WORKING}/"; copy_file "$a" "${DN_WORKING}/" > /dev/null 2>&1; done
        mr_trace "copy ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/*.dat to ${DN_WORKING}/"
        find_file "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" -name "*.dat" | while read a; do mr_trace "copy ${a} to ${DN_WORKING}/"; copy_file "$a" "${DN_WORKING}/" > /dev/null 2>&1; done
        mr_trace "copy ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/*.sh to ${DN_WORKING}/"
        find_file "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" -name "*.sh" | while read a; do mr_trace "copy ${a} to ${DN_WORKING}/"; copy_file "$a" "${DN_WORKING}/" > /dev/null 2>&1; done
        RET=$?
        if [ ! "$RET" = "0" ]; then
            mr_trace "Error: copy temp dir: $PARAM_DN_TEST to ${DN_WORKING}/"
            return
        fi
        cd "${DN_WORKING}"
    else
        cd "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/"
    fi
    mr_trace "rm -f *.bin *.txt *.out out.* *.tr *.log tmp*"
    rm -f *.bin *.txt *.out out.* *.tr *.log tmp* > /dev/null 2>&1
    mr_trace ${EXEC_HASHCAT} ${FN_TCL} 1 "${PARAM_DN_TEST}" FILTER grep PFSCHE TO "${HDFF_FN_LOG}"
    if [ ! -x "${EXEC_HASHCAT}" ]; then
        mr_trace "Error: not correctly set ns2 env EXEC_HASHCAT=${EXEC_HASHCAT}, which ns=$(which ns)"
    else
        #${EXEC_HASHCAT} ${FN_TCL} 1 "${PARAM_DN_TEST}" 2>&1 | grep PFSCHE >> "${HDFF_FN_LOG}"
        mr_trace ${EXEC_HASHCAT} ${FN_TCL} 1 "${PARAM_DN_TEST}" TO "${HDFF_FN_LOG}"
        ${EXEC_HASHCAT} ${FN_TCL} 1 "${PARAM_DN_TEST}" >> "${HDFF_FN_LOG}"
    fi

    mr_trace "USE_MEDIUMPACKET='${USE_MEDIUMPACKET}'"
    if [ "${USE_MEDIUMPACKET}" = "1" ]; then
        if [ -f mediumpacket.out ]; then
            rm_f_dir mediumpacket.out.gz > /dev/null
            mr_trace "compressing mediumpacket.out ..."
            gzip mediumpacket.out > /dev/null 2>&1
        else
            mr_trace "Warning: not found mediumpacket.out."
        fi
    else
        mr_trace "Warning: remove mediumpacket.out*!"
        rm_f_dir mediumpacket.out* > /dev/null
    fi

    cd "${DN_ORIG2}"
    if [ ! "${FLG_USETMP}" = "0" ]; then
        mr_trace "run ns2: copy back from working to parent dir: ${DN_WORKING}/ --> ${PARAM_DN_PARENT}/${PARAM_DN_TEST}/"
        #rsync -av  --log-file "${PARAM_DN_PARENT}/rsync-log-runns2-copyback-1-${PARAM_DN_TEST}.log" "${DN_WORKING}/" "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/" 1>&2
        RET=$(copy_file "${DN_WORKING}/" "${PARAM_DN_PARENT}/${PARAM_DN_TEST}/")
        if [ ! "$RET" = "0" ]; then
            mr_trace "Error: copy temp dir: ${DN_WORKING} to $PARAM_DN_TEST"
            return
        fi
        #rm_f_dir "${DN_WORKING}"
    fi
}

# parse the parameters and generate the requests for ploting figures
prepare_figure_commands_for_one_stats () {
    PARAM_CONFIG_FILE="$1"
    shift
    # the prefix of the test
    PARAM_PREFIX=$1
    shift
    # the test type, "udp", "tcp", "has", "udp+has", "tcp+has"
    PARAM_TYPE=$1
    shift
    # the scheduler, such as "PF", "DRR"
    PARAM_SCHE=$1
    shift
    # the number of flows
    PARAM_NUM=$1
    shift

    #${DN_PARENT}/plotfigns2.sh tpflow "${HDFF_DN_OUTPUT}/dataconf/" "${HDFF_DN_OUTPUT}/figures/" "${PARAM_PREFIX}" "${PARAM_TYPE}" "${PARAM_SCHE}" "${PARAM_NUM}"

    case $PARAM_TYPE in
    udp)
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"udp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    tcp)
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    has*)
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    udp+has*)
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"udp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    tcp+has*)
        echo -e "packet\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"any\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        echo -e "throughput\t\"${PARAM_CONFIG_FILE}\"\t\"${PARAM_PREFIX}\"\t\"${PARAM_TYPE}\"\t\"tcp\"\t\"${PARAM_SCHE}\"\t${PARAM_NUM}"
        ;;
    esac
}

# clean temperary files with file name prefix "tmp-"
clean_one_tcldir () {
    # the prefix of the test
    PARAM_DN_DEST=$1
    shift

    FLG_ERR=1
    if [ -d "${PARAM_DN_DEST}" ]; then
        FLG_ERR=0
        find_file "${PARAM_DN_DEST}" -name "tmp-*" | xargs -n 1 rm_f_dir
    fi

    if [ "${FLG_ERR}" = "1" ]; then
        echo -e "error-clean\t${DN_TEST}"
    fi
}

# check the throughput log file, if the log time reach to the pre-set end time.
# checked both for UDP and TCP packets, with file prefix CMTCPDS and CMUDPDS
# get the TIME_STOP from your config file
check_one_tcldir () {
    PARAM_FN_CONF=$1
    shift
    PARAM_DN_DEST=$1
    shift
    # output file save the failed directories
    PARAM_FN_LOG_ERROR=$1
    shift

    local FN_TMP3="/tmp/config-$(uuidgen)"
    copy_file "${PARAM_FN_CONF}" "${FN_TMP3}" > /dev/null 2>&1
    read_config_file "${FN_TMP3}"
    rm_f_dir "${FN_TMP3}" > /dev/null 2>&1

    FLG_ERR=1
    mr_trace "checking $(basename ${PARAM_DN_DEST}) ..."
    local RET
    RET=$(is_file_or_dir "${PARAM_DN_DEST}")
    if [ "${RET}" = "d" ]; then
        FLG_ERR=0
        FLG_NONE=1

        FN_TPFLOW="CMTCPDS*.out"
        mr_trace "checking tcp FN_TPFLOW=$FN_TPFLOW ..."
        #mr_trace "find_file '${PARAM_DN_DEST}' -name '${FN_TPFLOW}' ..."
        LST=$(find_file "${PARAM_DN_DEST}" -name "${FN_TPFLOW}" | sort)
        for i in $LST ; do
            FLG_NONE=0
            mr_trace "process flow throughput (tcp) $i ..."
            idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
            #mr_trace "curr dir=$(pwd), tail i=$i"
            TM1=$(tail_file "$i" -n 1 | awk '{print $1}')
            # we assume it done correctly if the time different is in 8 seconds
            if [ $(echo | awk -v A=$TM1 -v B=$TIME_STOP '{if (A + 8 < B) print 1; else print 0;}') = 1 ] ; then
                FLG_ERR=1
            fi
        done

        FN_TPFLOW="CMUDPDS*.out"
        mr_trace "checking udp FN_TPFLOW=$FN_TPFLOW ..."
        #mr_trace "find_file '${PARAM_DN_DEST}' -name '${FN_TPFLOW}' ..."
        LST=$(find_file "${PARAM_DN_DEST}" -name "${FN_TPFLOW}" | sort)
        for i in $LST ; do
            FLG_NONE=0
            mr_trace "process flow throughput (udp) $i ..."
            idx=$(echo "$i" | sed -e 's|[^0-9]*\([0-9]\+\)[^0-9]*|\1|')
            TM1=$(tail_file "$i" -n 1 | awk '{print $1}')
            if [ $(echo | awk -v A=$TM1 -v B=$TIME_STOP '{if (A + 5 < B) print 1; else print 0;}') = 1 ] ; then
                FLG_ERR=1
            fi
        done
        if [ "$FLG_NONE" = "1" ]; then
            FLG_ERR=1
        fi
    fi

    if [ "${FLG_ERR}" = "1" ]; then
        mr_trace "save ${PARAM_FN_LOG_ERROR}: ${PARAM_DN_DEST}"
        echo "${PARAM_DN_DEST}" >> "${PARAM_FN_LOG_ERROR}"
    fi
}

