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
#config line: "e1map.sh,e1red.sh,6,5,cb_end_stage1"
LIST_MAPREDUCE_WORK="e1map.sh,,6,5, e2map.sh,,6,5,"

#####################################################################
## @fn my_getpath()
## @brief get the real name of a path
## @param dn the path name
##
## get the real name of a path, return the real path
my_getpath() {
    PARAM_DN="$1"
    shift
    #readlink -f
    DN="${PARAM_DN}"
    FN=
    if [ ! -d "${DN}" ]; then
        FN=$(basename "${DN}")
        DN=$(dirname "${DN}")
    fi
    DNORIG=$(pwd)
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
        mr_trace "Error: destination is not local dir: ${HDFF_DN_BIN}"
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
        EXEC_TEST="$(my_getpath "${DN_EXEC}/testbin.sh")"
        mr_trace "try detect testbin.sh 1: ${EXEC_TEST}"
        echo -e "error-prepapp\ttry-get-file\t${DN_EXEC}/testbin.sh"
    else
        local DN2=$(extrace_binary "${HDFF_PATHTO_TAR_APP}")
        EXEC_TEST="$(my_getpath "${DN2}/app-test/testbin.sh")"
        mr_trace "try detect testbin.sh 2: ${EXEC_TEST}"
        echo -e "error-prepapp\ttry-get-file\t${DN2}/app-test/testbin.sh"
    fi

    lst_app_dirs=(
        "/home/$USER/mrtest/app-test/testbin.sh"
              "$HOME/mrtest/app-test/testbin.sh"
        )
    if [ ! -x "${EXEC_TEST}" ]; then
        CNT=0
        while [[ ${CNT} < ${#lst_app_dirs[*]} ]] ; do
            mr_trace "try detect ns2 lst_app_dirs(${CNT}):" ${lst_app_dirs[${CNT}]}
            if [ -x "${EXEC_TEST}" ]; then
                EXEC_TEST=${lst_app_dirs[${CNT}]}
                mr_trace "found: $EXEC_TEST"
                break
            fi
            CNT=$(( $CNT + 1 ))
        done
    fi

    if [ ! -x "${EXEC_TEST}" ]; then
        EXEC_TEST=$(which testbin.sh)
        mr_trace "try detect testbin.sh 10: ${EXEC_TEST}"
        echo -e "error-prepapp\ttry-get-file\t${EXEC_TEST}"
    fi
    mr_trace "EXEC_TEST=${EXEC_TEST}"
    if [ ! -x "${EXEC_TEST}" ]; then
        mr_trace "Error: not found testbin.sh"
        echo -e "error-prepapp\tnot-get-file\ttestbin.sh"
    fi
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
        echo -e "error-prepnative\tnot-get-tarfile\tHDFF_PATHTO_TAR_MRNATIVE=${HDFF_PATHTO_TAR_MRNATIVE}"
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

    local NUM_NODES=1
    cat "${PARAM_FN_CONFIG}" | while read get_sim_tasks_each_file_tmp_a; do
        A=$( echo $get_sim_tasks_each_file_tmp_a | grep NUM_CORES | sed -e 's|NUM_CORES=\(.*\)$|\1|' )
        if [ ! "$A" = "" ]; then
            #arr=($A)
            #NUM_NODES=${#arr[@]}
            NUM_NODES=$A
        fi
    done
    mr_trace "got num=$NUM_NODES"
    echo $NUM_NODES
}

## @fn libapp_generate_script_4hadoop()
## @brief generate the TCL scripts for all of the settings
## @param command the command
## @param fn_config_proj the config file of the application
##
## my_getpath, DN_EXEC, HDFF_DN_OUTPUT, should be defined before call this function
## HDFF_DN_SCRATCH should be in global config file (mrsystem.conf)
## PREFIX, LIST_NODE_NUM, LIST_TYPES, LIST_SCHEDULERS should be in the config file passed by argument
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
    cat_file "${DN_TOP}/bin/mod-setenv-hadoop.sh" | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libbash.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libshrt.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libfs.sh"       | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libplot.sh"     | save_file "${PARAM_OUTPUT}"
    cat_file "${DN_TOP}/lib/libconfig.sh"   | save_file "${PARAM_OUTPUT}"
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
        | grep -v "libconfig.sh" \
        | grep -v "libapp.sh"   \
        | sed -e "s|EXEC_TEST=.*$|EXEC_TEST=$(which ns)|" \
        | save_file "${PARAM_OUTPUT}"
        # -e "s|FN_CONF_SYS=.*$|echo > /dev/null|"
    #mr_trace cat_file "${PARAM_OUTPUT}"
    #cat_file "${PARAM_OUTPUT}"
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
libapp_prepare_execution_config() {
    local PARAM_COMMAND=$1
    shift
    local PARAM_FN_CONFIG_PROJ=$1
    shift

    local FN_TMP="/tmp/config-$(uuidgen)"
    mr_trace "read proj config file: ${PARAM_FN_CONFIG_PROJ} ..."
    copy_file "${PARAM_FN_CONFIG_PROJ}" "${FN_TMP}" > /dev/null 2>&1
    read_config_file "${FN_TMP}"
    rm_f_dir "${FN_TMP}" > /dev/null 2>&1

    CNT=$NUM_CORES
    while (( $CNT > 0 )) ; do
        echo "${PARAM_COMMAND}"
        CNT=$(( $CNT - 1 ))
    done
}

#####################################################################

#HDFF_DN_SCRATCH="/dev/shm/$USER/"

# PARAM_DN_PARENT -- the parent dir for the data to be saved.
# PARAM_DN_TEST   -- the sub dir for the data, related dir name to PARAM_DN_PARENT
# PARAM_FN_CONFIG_PROJ -- the config file for this simulation
run_one_test () {
    local PARAM_DN_PARENT=$1
    shift
    local PARAM_DN_TEST=$1
    shift
    local PARAM_FN_CONFIG_PROJ=$1
    shift

    if [ ! -x "${EXEC_TEST}" ]; then
        mr_trace "Error: not correctly set test env EXEC_TEST=${EXEC_TEST}"
    else
        ${EXEC_TEST}
    fi
}

