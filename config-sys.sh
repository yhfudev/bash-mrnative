#!/bin/sh
# config file for system

# the outfile directory
#HDFF_DN_OUTPUT=hdfs://user/yfu/mapreduce-results
HDFF_DN_OUTPUT=mapreduce-results

# how many running processes in each node
# 0 -- auto detect the CPU cores, use about 5/7 of them
HDFF_NUM_CLONE=0

# total number of nodes (machines) in the system, default = 1
HDFF_TOTAL_NODES=1

#EXEC_NS2="$(which ns)"
HDFF_FN_LOG="/dev/null"
#HDFF_FN_LOG="mylog.txt"

# the temporary directory for NS2 simulator
HDFF_DN_SCRATCH="/dev/shm/${USER}/"
#HDFF_DN_SCRATCH="/local_scratch/${USER}/"

