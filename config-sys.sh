#!/bin/sh
# config file for system

# the project id for name prefix
HDFF_PROJ_ID=mr4ns2
# description
HDFF_PROJ_DESC="Map-Reduce for NS2 simulations"

# the output file directory
#HDFF_DN_OUTPUT=hdfs:///user/yhfu/mapreduce-results/
#HDFF_DN_OUTPUT=hdfs:///user/yhfu/mapreduce-results/
HDFF_DN_OUTPUT=hdfs:///user/yhfu/mapreduce-results/

# how many running processes in each node
# 0 -- auto detect the CPU cores, use about 5/7 of them
HDFF_NUM_CLONE=0

# total number of nodes (machines) in the system, default = 1
HDFF_TOTAL_NODES=1

#EXEC_NS2="$(which ns)"
HDFF_FN_LOG="/dev/null"
#HDFF_FN_LOG="mylog.txt"

# the temporary directory for NS2 simulator
#HDFF_DN_SCRATCH="/dev/shm/${USER}/"
#HDFF_DN_SCRATCH="/local_scratch/${USER}/"
HDFF_DN_SCRATCH=/dev/shm/yhfu/


# the directory for save the un-tar binary files
# it should be a directory in a local disk
#HDFF_DN_BIN="/dev/shm/${USER}/bin"
HDFF_DN_BIN=/dev/shm/yhfu/bin

# the tar file for application binary
#HDFF_FN_TAR_APP=hdfs:///user/${USER}/ns2docsis-ds31profile-i386-compiled.tar.gz
HDFF_FN_TAR_APP=hdfs:///user/yhfu/ns2docsis-ds31profile-i386-compiled.tar.gz

# the tar file for mrnative-ns2
#HDFF_FN_TAR_MRNATIVE=hdfs:///user/${USER}/mrnativens2-1.1.tar.gz
HDFF_FN_TAR_MRNATIVE=hdfs:///user/yhfu/mrnativens2-1.1.tar.gz

