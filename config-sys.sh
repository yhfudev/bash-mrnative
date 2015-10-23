#!/bin/sh
# config file for system

# the outfile directory
HDFF_DN_OUTPUT=/home/yhfu/working/vmshare/ns2docsis-1.0-workingspace/ns2docsis-ds31profile/ns-2.33/ns2testscripts/mapreduce-ns2docsis/projtools/results-mr

# how many running processes in each node
# 0 -- auto detect the CPU cores, use about 5/7 of them
HDFF_NUM_CLONE=0

#EXEC_NS2="$(which ns)"
FN_LOG="/dev/null"
#FN_LOG="mylog.txt"
