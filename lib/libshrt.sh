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
# multiple processes support
CNTCHILD=0
PID_CHILDREN=

# use this session id to trace the child process.
MP_SESSION_ID=
mp_new_session () {
  CNTCHILD=0
  PID_CHILDREN=
  MP_SESSION_ID=$(uuidgen)
  mr_trace "generated session id: ${MP_SESSION_ID}"
}
mp_get_session_id () {
  echo "${MP_SESSION_ID}"
}

mp_remove_child_record () {
  PARAM_CHILD_ID=$1
  shift

  #mr_trace "before remove child ${PARAM_CHILD_ID}, #=${CNTCHILD}, PID list='${PID_CHILDREN}'" 1>&2
  PID_CHILDREN=$(echo ${PID_CHILDREN} | awk -v ID=${PARAM_CHILD_ID} '{for (i = 1; i <= NF; i ++) {if ($i != ID) printf(" %d", $i); } }' )
  CNTCHILD=$(echo ${PID_CHILDREN} | awk '{print NF}' )
  mr_trace "after remove child ${PARAM_CHILD_ID}, #=${CNTCHILD}, PID list='${PID_CHILDREN}'"

}

# the parent wait all of the children
mp_wait_all_children () {
  mr_trace "wait all of children"
  while [ "$(echo | ${EXEC_AWK} -v A=${CNTCHILD} '{if(A>0){print 1;}else{print 0;}}' )" = "1" ]; do
    for ID2 in ${PID_CHILDREN} ; do
      wait ${ID2} 1>&2
      mr_trace "child ${ID2} done!"
      mp_remove_child_record ${ID2}
    done
    sleep 5
  done
}

#if [ "${DN_DATATMP}" = "" ]; then
#    DN_DATATMP=.
#fi
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
  #mr_trace "child notif exit: id=${BASHPID}"
}

# add new child, check if the children are too many then wait
mp_add_child_check_wait () {
  PARAM_CHILD_ID=$1
  shift

  if [ "${PARAM_CHILD_ID}" = "" ]; then
    mr_trace "Warning: child id null! ignored"
    return
  fi
  #mr_trace "add child id=${PARAM_CHILD_ID}"

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
  mr_trace "CNTCHILD=${CNTCHILD}; HDFF_NUM_CLONE=${HDFF_NUM_CLONE}, #=${CNTCHILD}, PID list='${PID_CHILDREN}' "
  while [ "$(echo | ${EXEC_AWK} -v A=${CNTCHILD} -v B=${HDFF_NUM_CLONE} '{if(A>=B){print 1;}else{print 0;}}' )" = "1" ]; do
    #echo "[DBG] (self=${BASHPID}) check all of children in the ${DN_DATATMP}/pids-${MP_SESSION_ID}/end/" 1>&2
    # the number of the end process is no more than HDFF_NUM_CLONE
    for ID in $PID_CHILDREN ; do
      ps -p ${ID} > /dev/null 2>&1
      if [ ! "$?" = "0" ]; then
        #mr_trace "1 child ${ID} done!"
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
