#!/bin/bash
#####################################################################
# bash library
# some useful bash script functions:
#   exec_ignore
#   unquote_filename
#   read_config_file
#   mp_add_child_check_wait
#
# Copyright 2014 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################
# TODO

if [ "${DN_DATATMP}" = "" ]; then
    DN_DATATMP=.
fi

#####################################################################
myexec_ignore () {
    echo "[DBG] (skip) 6 $*" 1>&2
    A=
    while [ ! "$1" = "" ]; do
        A="$A \"$1\""
        shift
    done
    echo "[DBG] (skip) 5 $A" 1>&2
}
myexec_trace () {
    echo "[DBG] $*" 1>&2
    A=
    while [ ! "$1" = "" ]; do
        A="$A \"$1\""
        shift
    done
    echo "[DBG] $A" 1>&2
    eval $A
}
MYEXEC=myexec_trace
#MYEXEC=
if [ "$FLG_SIMULATE" = "1" ]; then
    MYEXEC=myexec_ignore
fi

fatal_error () {
  PARAM_MSG="$1"
  echo "[DBG] (self=${BASHPID}) fatal error: ${PARAM_MSG}" 1>&2
  #exit 1
}

#####################################################################
# multiple processes support
CNTCHILD=0
PID_CHILDREN=

# use this session id to trace the child process.
MP_SESSION_ID=
mp_new_session () {
  CNTCHILD=0
  PID_CHILDREN=
  MP_SESSION_ID=$(uuidgen)
  echo "[DBG] generated session id: ${MP_SESSION_ID}" 1>&2
}
mp_get_session_id () {
  echo "${MP_SESSION_ID}"
}

# directory ${DN_DATATMP}/pids-${MP_SESSION_ID}/running contains the id of the running children
# directory ${DN_DATATMP}/pids-${MP_SESSION_ID}/end contains the id of the finished children
mp_remove_child_record () {
  PARAM_CHILD_ID=$1
  shift

  echo "[DBG] (self=${BASHPID}) before remove child ${PARAM_CHILD_ID}, #=${CNTCHILD}, PID list='${PID_CHILDREN}'" 1>&2
  PID_CHILDREN=$(echo ${PID_CHILDREN} | awk -v ID=${PARAM_CHILD_ID} '{for (i = 1; i <= NF; i ++) {if ($i != ID) printf(" %d", $i); } }' )
  CNTCHILD=$(echo ${PID_CHILDREN} | awk '{print NF}' )
  echo "[DBG] (self=${BASHPID}) after remove child ${PARAM_CHILD_ID}, #=${CNTCHILD}, PID list='${PID_CHILDREN}'" 1>&2

}

# the parent wait all of the children
mp_wait_all_children () {
  echo "[DBG] (self=${BASHPID}) wait all of children" 1>&2
  while [ "$(echo | ${EXEC_AWK} -v A=${CNTCHILD} '{if(A>0){print 1;}else{print 0;}}' )" = "1" ]; do
    for ID2 in ${PID_CHILDREN} ; do
      wait ${ID2} 1>&2
      echo "[DBG] child ${ID2} done!" 1>&2
      mp_remove_child_record ${ID2}
    done
    sleep 5
  done
}

# ERROR: due to each process will will not share theirs variable,
#   it would not use the same pid directory, so we don't use file name to indicate the PID of finished child.
#DN_WAITID=
#init_multi_processes () {
  #if [ ! -d "${DN_WAITID}" ]; then
    # the temp directory to store the quitted PIDs for current environment
    #DN_WAITID="${DN_DATATMP}/pids-$(uuidgen)"
    #mkdir -p "${DN_WAITID}"
    #rm -f "${DN_WAITID}"/*
  #fi
#}

# the child process notify that its quit.
# since processes will not share theirs variable values,
# the children have to use session id from their parent.
mp_notify_child_exit () {
  # the session id
  PARAM_SID=$1
  shift

  CHILD_ID=${BASHPID}
  echo "[DBG] child notif exit: id=${BASHPID}" 1>&2
}

# add new child, check if the children are too many then wait
mp_add_child_check_wait () {
  PARAM_CHILD_ID=$1
  shift

  if [ "${PARAM_CHILD_ID}" = "" ]; then
    echo "[DBG] warning: child id null! ignored" 1>&2
    return
  fi
  echo "[DBG] (self=${BASHPID}) add child id=${PARAM_CHILD_ID}" 1>&2

  PID_CHILDREN="${PID_CHILDREN} ${PARAM_CHILD_ID}"
  CNTCHILD=$(( $CNTCHILD + 1 ))

  if [ "${MP_SESSION_ID}" = "" ]; then
    fatal_error "not generated session id!"
    return
    #mp_generate_session_id
  fi
  if [ "${MP_SESSION_ID}" = "" ]; then
    fatal_error "unable to generate session id!"
    return
  fi
  echo "[DBG] (self=${BASHPID}) CNTCHILD=${CNTCHILD}; HDFF_NUM_CLONE=${HDFF_NUM_CLONE}, #=${CNTCHILD}, PID list='${PID_CHILDREN}' " 1>&2
  while [ "$(echo | ${EXEC_AWK} -v A=${CNTCHILD} -v B=${HDFF_NUM_CLONE} '{if(A>=B){print 1;}else{print 0;}}' )" = "1" ]; do
    #echo "[DBG] (self=${BASHPID}) check all of children in the ${DN_DATATMP}/pids-${MP_SESSION_ID}/end/" 1>&2
    # the number of the end process is no more than HDFF_NUM_CLONE
    for ID in $PID_CHILDREN ; do
      ps -p ${ID} > /dev/null 2>&1
      if [ ! "$?" = "0" ]; then
        echo "[DBG] (self=${BASHPID}) 1 child ${ID} done!" 1>&2
        mp_remove_child_record ${ID}
      fi
    done
    if [ "$(echo | ${EXEC_AWK} -v A=${CNTCHILD} -v B=${HDFF_NUM_CLONE} '{if(A>=B){print 1;}else{print 0;}}' )" = "1" ]; then
#if [ 1 = 1 ]; then
      sleep 1
#else
#      #IDX1=$(echo | awk -v S=$RANDOM -v N=$(date +%N) -v M=${CNTCHILD} 'BEGIN{srand(S+N);}{print int(rand()*10*M) % M; }' )
#      #ID2=$(echo ${PID_CHILDREN} | awk -v R=${RANDOM} '{IDX=R % NF + 1; print $IDX ;}' )
#      ID2=$(echo ${PID_CHILDREN} | awk '{print $1;}' )
#      timeout -k 2s 2s wait ${ID2} &
#      wait $!
#fi
    fi
  done
}

#####################################################################
HDFF_EXCLUDE_4PREFIX="\.\,?\!\-_:;\]\[\#\|\$()\"%"
generate_prefix_from_filename () {
  PARAM_FN="$1"
  shift

  echo "${PARAM_FN//[${HDFF_EXCLUDE_4PREFIX}]/}" | tr [:upper:] [:lower:]
}

HDFF_EXCLUDE_4FILENAME="\""
unquote_filename () {
  PARAM_FN="$1"
  shift
  #echo "e1map [DBG] PARAM_FN=${PARAM_FN}; dirname=$(dirname "${PARAM_FN}"); readlink2=$(readlink -f "$(dirname "${PARAM_FN}")" )" 1>&2
  echo "${PARAM_FN//[${HDFF_EXCLUDE_4FILENAME}]/}"
}

#####################################################################
# check if the global variable not set, set it to default values.
check_global_config () {
  if [ "${HDFF_DN_OUTPUT}" = "" ]; then
    # set to ${DN_TOP}/data/output/
    HDFF_DN_OUTPUT=data/output
  fi

  FLG_AUTOCPU=0
  if [ "${HDFF_NUM_CLONE}" = "" ] ; then
    FLG_AUTOCPU=1
    HDFF_NUM_CLONE=1
  fi
  if [ "${HDFF_NUM_CLONE}" -lt 1 ] ; then
    FLG_AUTOCPU=1
  fi
  if [ "${FLG_AUTOCPU}" = "1" ] ; then
    HDFF_NUM_CLONE=1
    # number of CPUs
    NUM_PROC=$(cat /proc/cpuinfo | egrep ^processor | wc -l)
    if [ "${NUM_PROC}" -gt 1 ] ; then
      #HDFF_NUM_CLONE=$(( ${NUM_PROC} * 8 / 9 ))
      #NUM=$(( ${NUM_PROC} / 9 ))
      #if [ "${NUM}" -gt 8 ] ; then
      #  HDFF_NUM_CLONE=$(( ${NUM_PROC} - 8 ))
      #fi
      HDFF_NUM_CLONE=${NUM_PROC}
    fi
  fi
  if [ "${HDFF_NUM_CLONE}" -lt 1 ] ; then
    HDFF_NUM_CLONE=1
  fi

  #HDFF_TRANSCODE_RESOLUTIONS=320x180+315k+64k,640x360+500k+64k,853x480+1000k+192k,1280x720+1500k+256k,1280x720+2600k+256k,1920x1080+3800k+256k,1920x1080+4800k+256k,3840x1714+9000k+256k,3840x1714+12000k+256k
  #HDFF_SCREEN_RESOLUTIONS=320x180,640x360,854x480,1280x720,1920x1080,3840x2160,7680x4320
}

read_config_file () {
### Read in some system-wide configurations (if applicable) but do not override
### the user's environment
PARAM_FN_CONF="$1"
echo "parse config file $1" 1>&2
if [ -e "$PARAM_FN_CONF" ]; then
  while read LINE; do
    REX='^[^# ]*='
    if [[ ${LINE} =~ ${REX} ]]; then
      VARIABLE=$(echo "${LINE}" | awk -F= '{print $1}' )
      VALUE0=$(echo "${LINE}" | awk -F= '{print $2}' )
      VALUE=$( unquote_filename "${VALUE0}" )
      #echo "[DBG] VARIABLE=${VARIABLE}; VALUE=${VALUE}" 1>&2
      if [ "z${!VARIABLE}" == "z" ]; then
        eval "${VARIABLE}=\"${VALUE}\""
        echo "Setting ${VARIABLE}=${VALUE} from $PARAM_FN_CONF" 1>&2
      #else echo "Keeping $VARIABLE=${!VARIABLE} from user environment" 1>&2
      fi
    fi
  done < "$PARAM_FN_CONF"
fi
}

generate_default_config () {

  cat << EOF
# default configure file for HDFF generated by $(basename $0)

# the outfile directory
HDFF_DN_OUTPUT=data/output

# how many running processes in each node
# 0 -- auto detect the CPU cores, use about 5/7 of them
HDFF_NUM_CLONE=0
EOF
}

#####################################################################
