#!/bin/bash
#
# plot all of the figures of results
# 
# Copyright 2015 Yunhui Fu
# License: GPL v3.0 or later
#####################################################################
my_getpath () {
  PARAM_DN="$1"
  shift
  #readlink -f
  DN="${PARAM_DN}"
  FN=
  if [ ! -d "${DN}" ]; then
    FN=$(basename "${DN}")
    DN=$(dirname "${DN}")
  fi
  cd "${DN}" > /dev/null 2>&1
  DN=$(pwd)
  cd - > /dev/null 2>&1
  echo "${DN}/${FN}"
}
DN_EXEC=$(dirname $(my_getpath "$0") )
#####################################################################

DN_COMM="$(my_getpath "${DN_EXEC}/common")"
source ${DN_COMM}/libbash.sh
source ${DN_COMM}/libshrt.sh
source ${DN_COMM}/libplot.sh
source ${DN_COMM}/libns2figures.sh

DN_PARENT="$(my_getpath ".")"

#read_config_file "${DN_PARENT}/config.conf"
source ${DN_PARENT}/config.sh

check_global_config

#echo "HDFF_NUM_CLONE=$HDFF_NUM_CLONE"; exit 1 # debug

#####################################################################
echo ""
echo ""
echo "$MSG_TITLE"
echo "=========="
echo "$MSG_DESCRIPTION"
echo "----------"
echo "Ploting ..."

FN_ASSIGN=$1

# generate session for this process and its children
#  use mp_get_session_id to get the session id later
mp_new_session

for idx_type in ${list_types[*]} ; do

    case "$idx_type" in
    "tcp")
        generate_tcp_figures "${PREFIX}" "$idx_type" "DSFTPTCPstats*.out" "CMTCPDS*.out"
        ;;
    "has")
        generate_tcp_figures "${PREFIX}" "$idx_type" "DSFTPTCPstats*.out" "CMTCPDS*.out"
        ;;
    "tcp+has")
        generate_tcp_figures "${PREFIX}" "$idx_type" "DSFTPTCPstats*.out" "CMTCPDS*.out"
        ;;
    "udp")
        generate_udp_figures "${PREFIX}" "$idx_type" "DSUDPstats*.out"    "CMUDPDS*.out"
        ;;
    *)
    #"udp+has")
        generate_tcp_figures "${PREFIX}" "$idx_type" "DSFTPTCPstats*.out" "CMTCPDS*.out"
        generate_udp_figures "${PREFIX}" "$idx_type" "DSUDPstats*.out"    "CMUDPDS*.out"
        ;;
    esac
done

for idx_type in ${list_types[*]} ; do
    # this function cost a lot of time:
    generate_pkt_delay_figures "${PREFIX}" "$idx_type"
done

mp_wait_all_children
echo "DONE!"
