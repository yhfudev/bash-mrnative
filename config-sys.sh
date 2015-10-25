#!/bin/sh
# config file for system

# the outfile directory
HDFF_DN_OUTPUT=results-mr

# how many running processes in each node
# 0 -- auto detect the CPU cores, use about 5/7 of them
HDFF_NUM_CLONE=0

#EXEC_NS2="$(which ns)"
FN_LOG="/dev/null"
#FN_LOG="mylog.txt"

# the temporary directory for NS2 simulator
DN_SCRATCH="/dev/shm"
#DN_SCRATCH="/local_scratch/$USER/"
