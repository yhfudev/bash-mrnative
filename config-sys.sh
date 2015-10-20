#!/bin/sh
# config file for system

# the outfile directory
HDFF_DN_OUTPUT=results

# how many running processes in each node
# 0 -- auto detect the CPU cores, use about 5/7 of them
HDFF_NUM_CLONE=0

#EXEC_NS2="$(which ns)"
FN_LOG="/dev/null"
#FN_LOG="mylog.txt"
