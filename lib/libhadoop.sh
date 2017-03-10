#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief Bash lib for hadoop functions
##
##   this lib depend on libbash.sh, libfs.sh
## @author Yunhui Fu <yhfudev@gmail.com>
## @copyright GPL v3.0 or later
## @version 1
##
#####################################################################

## @fn hadoop_set_default_mapredsitexml_1x()
## @brief create a default settings for file mapred-site.xml (Hadoop 1.x)
## @param FN_MAPREDSITE the file name for mapred-site.xml
##
## The content of the hadoop/conf/mapred-site.xml includes
##  1. the configure from the myhadoop
##  2. the memory parameters for this package
hadoop_set_default_mapredsitexml_1x() {
    local PARAM_FN_MAPREDSITE="$1"
    shift

cat << EOF > "${PARAM_FN_MAPREDSITE}"
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>

<property>
  <name>mapred.job.tracker</name>
  <value>MASTER_NODE:54311</value>
  <description>The host and port that the MapReduce job tracker runs
  at.  If "local", then jobs are run in-process as a single map
  and reduce task.
  </description>
</property>

<property>
  <name>mapred.local.dir</name>
  <value>MAPRED_LOCAL_DIR</value>
  <final>true</final>
</property>

<property>
  <name>mapred.tasktracker.map.tasks.maximum</name>
  <value>MAPRED_TASKTRACKER_MAP_TASKS_MAXIMUM</value>
  <description>The MH_MAP_TASKS_MAXIMUM will set the maximum amount of
     MAP tasks to be started on a single TASK node, this is either CPU
     or memory bound.</description>
</property>

<property>
  <name>mapred.tasktracker.reduce.tasks.maximum</name>
  <value>MAPRED_TASKTRACKER_REDUCE_TASKS_MAXIMUM</value>
  <description>The MH_REDUCE_TASKS_MAXIMUM will set the maximum amount
     of REDUCE tasks to be started on a single TASK node, this is most
     likely memory bound.</description>
</property>

<property>
  <name>mapred.map.tasks</name>
  <value>MAPRED_MAP_TASKS</value>
  <description>The MH_MAP_TASKS is used to hint the application of the
     total amount of MAP tasks that can be run on the cluster.</description>
</property>

<property>
  <name>mapred.reduce.tasks</name>
  <value>MAPRED_REDUCE_TASKS</value>
  <description>The MH_REDUCE_TASKS is used to hint the application of
     the total amount of REDUCE tasks that can be run on the cluster.</description>
</property>

    <property>
        <name>mapred.job.map.memory.mb</name>
        <value>512</value>
    </property>
    <property>
        <name>mapred.job.reduce.memory.mb</name>
        <value>1024</value>
    </property>
    <property>
        <name>mapred.map.child.java.opts</name>
        <value>-Xmx384m</value>
    </property>
    <property>
        <name>mapred.reduce.child.java.opts</name>
        <value>-Xmx768m</value>
    </property>
</configuration>
EOF
}

## @fn hadoop_set_default_mapredsitexml()
## @brief create a default settings for file mapred-site.xml (>= Hadoop 2.x)
## @param FN_MAPREDSITE the file name for mapred-site.xml
##
## The content of the hadoop/etc/hadoop/mapred-site.xml includes
##  1. the configure from the myhadoop
##  2. the memory parameters for this package
hadoop_set_default_mapredsitexml() {
    local PARAM_FN_MAPREDSITE="$1"
    shift

cat << EOF > "${PARAM_FN_MAPREDSITE}"
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>

<property>
  <name>mapreduce.framework.name</name>
  <value>yarn</value>
  <description>The runtime framework for executing MapReduce jobs. Can be one of
    local, classic or yarn.</description>
</property>

<property>
    <name>mapreduce.map.memory.mb</name>
    <value>512</value>
</property>
<property>
    <name>mapreduce.reduce.memory.mb</name>
    <value>1024</value>
</property>
<property>
    <name>mapreduce.map.java.opts</name>
    <value>-Xmx384m</value>
</property>
<property>
    <name>mapreduce.reduce.java.opts</name>
    <value>-Xmx768m</value>
</property>


<!-- A value of 0 disables the timeout -->
<!--
<property>
    <name>mapreduce.task.timeout</name>
    <value>0</value>
</property>
-->
<!-- setting the vcores -->
<property>
    <name>mapreduce.map.cpu.vcores</name>
    <value>1</value>
</property>
<property>
    <name>mapreduce.reduce.cpu.vcores</name>
    <value>1</value>
</property>

</configuration>
EOF
}

## @fn hadoop_set_default_yarnsitexml()
## @brief create a default settings for file yarn-site.xml (>= Hadoop 2.x)
## @param FN_YARNSITE the file name for yarn-site.xml
##
## The content of the hadoop/etc/hadoop/yarn-site.xml includes
##  1. the configure from the myhadoop
##  2. the memory parameters for this package
hadoop_set_default_yarnsitexml() {
    local PARAM_FN_YARNSITE="$1"
    shift

cat << EOF > "${PARAM_FN_YARNSITE}"
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>

<!-- Site specific YARN configuration properties -->
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>MASTER_NODE</value>
    <description>The hostname of the RM.</description>
    <final>true</final>
  </property>

  <property>
    <name>yarn.nodemanager.local-dirs</name>
    <value>MAPRED_LOCAL_DIR</value>
    <description>The hostname of the RM.
        Default: \${hadoop.tmp.dir}/nm-local-dir</description>
  </property>

<!-- yarn.nodemanager.log-dirs defaults to \${yarn.log.dir}/userlogs, where
     yarn.log.dir is set by yarn-env.sh via the YARN_LOG_DIR environment
     variable -->

<!-- these are necessary for mapreduce to work with YARN -->
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
    <description>The valid service name should only contain a-zA-Z0-9_ and can
        not start with numbers.  Default: none</description>
  </property>

<!--
  <property>
    <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    <description>Java class to handle the shuffle stage of
        mapreduce.
        Default:  org.apache.hadoop.mapred.ShuffleHandler</description>
  </property>
-->

<property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>3072</value>
</property>
<property>
    <name>yarn.scheduler.minimum-allocation-mb</name>
    <value>256</value>
</property>
<property>
    <name>yarn.scheduler.maximum-allocation-mb</name>
    <value>3072</value>
</property>

<property>
    <name>yarn.nodemanager.vmem-check-enabled</name>
    <value>false</value>
    <description>Whether virtual memory limits will be enforced for containers</description>
</property>
<property>
    <name>yarn.nodemanager.vmem-pmem-ratio</name>
    <value>4</value>
    <description>Ratio between virtual memory to physical memory when setting memory limits for containers</description>
</property>

<!-- setting the vcores -->
<property>
    <name>yarn.app.mapreduce.am.resource.cpu-vcores</name>
    <value>1</value>
</property>
<property>
    <name>yarn.scheduler.maximum-allocation-vcores</name>
    <value>24</value>
</property>
<property>
    <name>yarn.scheduler.minimum-allocation-vcores</name>
    <value>1</value>
</property>
<property>
    <name>yarn.nodemanager.resource.cpu-vcores</name>
    <value>24</value>
</property>

</configuration>
EOF
}

######################################################################

## @fn hadoop_set_default_coresitexml_1x()
## @brief create a default settings for file core-site.xml (Hadoop 1.x)
## @param FN_CORESITE the file name for core-site.xml
##
## The content of the hadoop/conf/core-site.xml includes
##  1. the configure from the myhadoop
hadoop_set_default_coresitexml_1x() {
    local PARAM_FN_CORESITE="$1"
    shift

cat << EOF > "${PARAM_FN_CORESITE}"
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
<property>
  <name>hadoop.tmp.dir</name>
  <value>HADOOP_TMP_DIR</value>
  <description>A base for other temporary directories.</description>
</property>

<property>
  <name>fs.default.name</name>
  <value>hdfs://MASTER_NODE:54310</value>
  <description>The name of the default file system.  A URI whose
  scheme and authority determine the FileSystem implementation.  The
  uri's scheme determines the config property (fs.SCHEME.impl) naming
  the FileSystem implementation class.  The uri's authority is used to
  determine the host, port, etc. for a filesystem.</description>
</property>
</configuration>
EOF
}

## @fn hadoop_set_default_coresitexml()
## @brief create a default settings for file core-site.xml (>= Hadoop 2.x)
## @param FN_CORESITE the file name for core-site.xml
##
## The content of the hadoop/etc/hadoop/core-site.xml includes
##  1. the configure from the myhadoop
hadoop_set_default_coresitexml() {
    local PARAM_FN_CORESITE="$1"
    shift

cat << EOF > "${PARAM_FN_CORESITE}"
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
<property>
  <name>hadoop.tmp.dir</name>
  <value>HADOOP_TMP_DIR</value>
  <description>A base for other temporary directories.</description>
</property>

<property>
  <name>fs.defaultFS</name>
  <value>hdfs://MASTER_NODE:54310</value>
</property>
</configuration>
EOF
}

## @fn hadoop_set_default_hdfssitexml_1x()
## @brief create a default settings for file hdfs-site.xml (Hadoop 1.x)
## @param FN_HDFSSITE the file name for hdfs-site.xml
##
## The content of the hadoop/conf/hdfs-site.xml includes
##  1. the configure from the myhadoop
hadoop_set_default_hdfssitexml_1x() {
    local PARAM_FN_HDFSSITE="$1"
    shift

cat << EOF > "${PARAM_FN_HDFSSITE}"
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <property>
    <name>dfs.name.dir</name>
    <value>DFS_NAME_DIR</value>
    <description>Determines where on the local filesystem the DFS name node
      should store the name table.  If this is a comma-delimited list
      of directories then the name table is replicated in all of the
      directories, for redundancy. </description>
    <final>true</final>
  </property>

  <property>
    <name>dfs.data.dir</name>
    <value>DFS_DATA_DIR</value>
    <description>Determines where on the local filesystem an DFS data node
       should store its blocks.  If this is a comma-delimited
       list of directories, then data will be stored in all named
       directories, typically on different devices.
       Directories that do not exist are ignored.
    </description>
    <final>true</final>
  </property>

  <property>
    <name>dfs.replication</name>
    <value>DFS_REPLICATION</value>
    <description>HDFS is partly designed to allow storage failures and uses
       replication for this. Since either your data on myhadoop jobs is only
       supposed to live through a single run or you can use persistent data
       that will most likely run on solid hardware it is quite save to keep
       replication at 1 and reduce the IO overhead.
    </description>
  </property>

  <property>
    <name>dfs.block.size</name>
    <value>DFS_BLOCK_SIZE</value>
    <description>The HDFS block size defines the size of the parts in which
       the HDFS files will be divided and distributed over the data nodes.
  </description>
  </property>
</configuration>
EOF
}

## @fn hadoop_set_default_hdfssitexml()
## @brief create a default settings for file hdfs-site.xml (>= Hadoop 2.x)
## @param FN_HDFSSITE the file name for hdfs-site.xml
##
## The content of the hadoop/etc/hadoop/hdfs-site.xml includes
##  1. the configure from the myhadoop
hadoop_set_default_hdfssitexml() {
    local PARAM_FN_HDFSSITE="$1"
    shift

cat << EOF > "${PARAM_FN_HDFSSITE}"
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>DFS_NAME_DIR</value>
    <description>Determines where on the local filesystem the DFS name node
      should store the name table.  If this is a comma-delimited list
      of directories then the name table is replicated in all of the
      directories, for redundancy. </description>
    <final>true</final>
  </property>

  <property>
    <name>dfs.datanode.data.dir</name>
    <value>DFS_DATA_DIR</value>
    <description>Determines where on the local filesystem an DFS data node
       should store its blocks.  If this is a comma-delimited
       list of directories, then data will be stored in all named
       directories, typically on different devices.
       Directories that do not exist are ignored.
    </description>
    <final>true</final>
  </property>

  <property>
    <name>dfs.replication</name>
    <value>DFS_REPLICATION</value>
    <description>HDFS is partly designed to allow storage failures and uses
       replication for this. Since either your data on myhadoop jobs is only
       supposed to live through a single run or you can use persistent data
       that will most likely run on solid hardware it is quite save to keep
       replication at 1 and reduce the IO overhead.
    </description>
  </property>

  <property>
   <name>dfs.namenode.secondary.http-address</name>
   <value>MASTER_NODE:50090</value>
   <description>The secondary namenode http server address and
       port.</description>
   <final>true</final>
  </property>

</configuration>
EOF
}

## @fn hadoop_set_default_hdfsdefaultxml()
## @brief create a default settings for file hdfs-default.xml  (>= Hadoop 2.x)
## @param FN_HDFSDEFAULT the file name for hdfs-default.xml
##
## The content of the hadoop/etc/hadoop/hdfs-default.xml  includes
##  1. the configure for data node failed
hadoop_set_default_hdfsdefaultxml() {
    local PARAM_FN_HDFSDEFAULT="$1"
    shift

cat << EOF > "${PARAM_FN_HDFSDEFAULT}"
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <property>
    <name>dfs.client.block.write.replace-datanode-on-failure.enable</name>
    <value>true</value>
  </property>
  <property>
    <name>dfs.client.block.write.replace-datanode-on-failure.policy</name>
    <value>ALWAYS</value>
  </property>
  <property>
    <name>dfs.client.block.write.replace-datanode-on-failure.best-effort</name>
    <value>true</value>
  </property>
</configuration>
EOF
}

######################################################################

## @fn hadoop_set_memory()
## @brief change the memory related config for hadoop
## @param HADOOP_HOME the environment variable HADOOP_HOME
## @param mem the total memory size(in MB) available for application in each node
##
## HADOOP_HOME should be set before this function
hadoop_set_memory() {
    local PARAM_HADOOP_HOME="$1"
    shift
    local PARAM_MEM=$1
    shift

    mr_trace "hadoop_set_memory(): PARAM_MEM=${PARAM_MEM}; PARAM_HADOOP_HOME=${PARAM_HADOOP_HOME}"

    # set the vcores to 1 to let bash script generate multiple processes.
    local CORES=1

    #local MR_JOB_MEM=2048
    #local MR_JOB_MEM=8192
    local MR_JOB_MEM=512
    if (( ${MR_JOB_MEM} < ${PARAM_MEM}/${CORES} )) ; then
        MR_JOB_MEM=$(( ${PARAM_MEM}/${CORES} ))
    fi
    if (( ${MR_JOB_MEM} * 6 > ${PARAM_MEM} )) ; then
        MR_JOB_MEM=$(( ${PARAM_MEM} / 6 ))
    fi

    mr_trace "hadoop_set_memory(): adjusted MR_JOB_MEM=${MR_JOB_MEM}; PARAM_HADOOP_HOME=${PARAM_HADOOP_HOME}"

    FN_TEMP_MAPREDSITE="mapred-site.xml"
    FN_TEMP_YARNSITE="yarn-site.xml"
    FN_TEMP_CORESITE="core-site.xml"
    FN_TEMP_HDFSSITE="hdfs-site.xml"
    FN_TEMP_HDFSDEFAULT="hdfs-default.xml"

    if [ -d "${PARAM_HADOOP_HOME}/conf" ]; then           # Hadoop 1.x
        mr_trace "set hadoop 1.x memory: cores=$CORES, mem=${PARAM_MEM}; mem/cores=$((${PARAM_MEM}/${CORES})), MR_JOB_MEM=${MR_JOB_MEM}"
        local DN_CONF="${PARAM_HADOOP_HOME}/conf"

        rm -f "${DN_CONF}/${FN_TEMP_CORESITE}"
        hadoop_set_default_coresitexml_1x "${DN_CONF}/${FN_TEMP_CORESITE}"
        rm -f "${DN_CONF}/${FN_TEMP_HDFSSITE}"
        hadoop_set_default_hdfssitexml_1x "${DN_CONF}/${FN_TEMP_HDFSSITE}"
        rm -f "${DN_CONF}/${FN_TEMP_HDFSDEFAULT}"
        hadoop_set_default_hdfsdefaultxml "${DN_CONF}/${FN_TEMP_HDFSDEFAULT}"

        rm -f "${DN_CONF}/${FN_TEMP_MAPREDSITE}"
        hadoop_set_default_mapredsitexml_1x "${DN_CONF}/${FN_TEMP_MAPREDSITE}"

        sed -i \
            -e  "s|<value>512</value>|<value>$(( ${MR_JOB_MEM}     ))</value>|" \
            -e "s|<value>1024</value>|<value>$(( ${MR_JOB_MEM}*3   ))</value>|" \
            -e  "s|<value>-Xmx384m</value>|<value>-Xmx$(( ${MR_JOB_MEM}*3/4 ))m</value>|" \
            -e  "s|<value>-Xmx768m</value>|<value>-Xmx$(( ${MR_JOB_MEM}*3*3/4   ))m</value>|" \
            "${DN_CONF}/${FN_TEMP_MAPREDSITE}"

    elif [ -d "${PARAM_HADOOP_HOME}/etc/hadoop" ]; then   # >= Hadoop 2.x

        mr_trace "set hadoop 2.x memory: cores=$CORES, mem=${PARAM_MEM}; mem/cores=$((${PARAM_MEM}/${CORES})), MR_JOB_MEM=${MR_JOB_MEM}"
        local DN_CONF="${PARAM_HADOOP_HOME}/etc/hadoop"

        rm -f "${DN_CONF}/${FN_TEMP_CORESITE}"
        hadoop_set_default_coresitexml "${DN_CONF}/${FN_TEMP_CORESITE}"
        rm -f "${DN_CONF}/${FN_TEMP_HDFSSITE}"
        hadoop_set_default_hdfssitexml "${DN_CONF}/${FN_TEMP_HDFSSITE}"
        rm -f "${DN_CONF}/${FN_TEMP_HDFSDEFAULT}"
        hadoop_set_default_hdfsdefaultxml "${DN_CONF}/${FN_TEMP_HDFSDEFAULT}"

        rm -f "${DN_CONF}/${FN_TEMP_MAPREDSITE}"
        hadoop_set_default_mapredsitexml "${DN_CONF}/${FN_TEMP_MAPREDSITE}"
        rm -f "${DN_CONF}/${FN_TEMP_YARNSITE}"
        hadoop_set_default_yarnsitexml   "${DN_CONF}/${FN_TEMP_YARNSITE}"

        sed -i \
            -e "s|<value>3072</value>|<value>${PARAM_MEM}</value>|" \
            -e  "s|<value>256</value>|<value>${MR_JOB_MEM}</value>|" \
            -e   "s|<value>24</value>|<value>${CORES}</value>|" \
            "${DN_CONF}/${FN_TEMP_YARNSITE}"

        sed -i \
            -e  "s|<value>512</value>|<value>$(( ${MR_JOB_MEM}     ))</value>|" \
            -e "s|<value>1024</value>|<value>$(( ${MR_JOB_MEM}*3   ))</value>|" \
            -e  "s|<value>-Xmx384m</value>|<value>-Xmx$(( ${MR_JOB_MEM}*3/4 ))m</value>|" \
            -e  "s|<value>-Xmx768m</value>|<value>-Xmx$(( ${MR_JOB_MEM}*3*3/4   ))m</value>|" \
            "${DN_CONF}/${FN_TEMP_MAPREDSITE}"

    else
        mr_trace "unknown hadoop version from dir '${PARAM_HADOOP_HOME}'"
        exit 1
    fi
}

######################################################################

## @fn run_stage_hadoop()
## @brief run map and reduce script in Hadoop
## @param config_line config line, such as "e1map.sh,e1red.sh,6,5,cb_end_stage1"
## @param stage the stage #
## @param cb_gen_mrbin the callback function for generating single MR script
## @param hdfs_working the working directory
## @param hdfs_input the input directory
## @param hdfs_ouput the output directory
##
## <config line> format: "<map>,<reduce>,<# of output key>,<# of partition key>,<callback end function>"
##   java streaming argument 'stream.num.map.output.key.fields' is map to '# of output key'
##   java streaming argument 'num.key.fields.for.partition' is map to '# of partition key'
##   stream.num.map.output.key.fields >= num.key.fields.for.partition
##   'callback end function' is called at the end of function
##
## This function will split the input files to several files with prefix 'splitfile-'
## with the paremter HDFF_TOTAL_NODES from global config file. Then all these 'splitfile-' files
## will be used as input of the map task.
##
## The predefined variables should exist before call this function:
##     HDFF_TOTAL_NODES, HDFF_NUM_CLONE, HADOOP_JAR_STREAMING, HDFF_PROJ_ID, DN_EXEC
##
## example:
## run_stage "e1map.sh,,6,5," 1 "workingdir" "${DN_INPUT_HDFS}/0" "${DN_INPUT_HDFS}/1"
run_stage_hadoop() {
    mr_trace "run_stage $@"

    local PARAM_CONFIG_LINE=$1
    shift
    local PARAM_STAGE=$1
    shift
    local PARAM_CB_GEN_MRBIN=$1
    shift
    local PARAM_HDFS_WORKING=$1
    shift
    local PARAM_HDFS_INPUT=$1
    shift
    local PARAM_HDFS_OUTPUT=$1
    shift

    local PARAM_FNMAP=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $1}')
    local PARAM_FNRED=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $2}')
    local PARAM_KEYS_SEP=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $3}')
    local PARAM_KEYS_BLK=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $4}')
    local PARAM_CBEND=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $5}')

    mr_trace "Stage ${PARAM_STAGE} ..."
    #####################################################################
    # use hundreds of files instead of one small file:
    mr_trace "origin HDFF_TOTAL_NODES=${HDFF_TOTAL_NODES}, HDFF_NUM_CLONE=${HDFF_NUM_CLONE}"
    if [ "${HDFF_TOTAL_NODES}" = "" ]; then
        HDFF_TOTAL_NODES=0
    fi
    if (( ${HDFF_TOTAL_NODES} < 1 )) ; then
        HDFF_TOTAL_NODES=1
    fi
    if [ "${HDFF_NUM_CLONE}" = "" ]; then
        HDFF_NUM_CLONE=0
    fi
    mr_trace "adjusted HDFF_TOTAL_NODES=${HDFF_TOTAL_NODES}, HDFF_NUM_CLONE=${HDFF_NUM_CLONE}"

    # use temp dir to store the output of awk since it don't support save to hdfs
    local DN_TMP="/tmp/dir-$(uuidgen)"
    make_dir "${DN_TMP}" > /dev/null

    find_file "${PARAM_HDFS_INPUT}/" -name "splitfile-*.txt" | while read a; do rm_f_dir "${a}"; done
    mr_trace "at the stage ${PARAM_STAGE}, split file ${PARAM_HDFS_INPUT}/*.txt to ${PARAM_HDFS_INPUT}/splitfile-*.txt"
    find_file "${PARAM_HDFS_INPUT}/" -name "*.txt" | while read a; do \
        cat_file "${a}" | awk -v DUP=${HDFF_TOTAL_NODES} -v CLONE=${HDFF_NUM_CLONE} -v DN="${DN_TMP}/" \
            'BEGIN{cnt=0; DUP=int(DUP);}{cnt ++; print $0 >> "" DN "/splitfile-" (cnt % DUP) ".txt"}'; \
    done

    rm_f_dir "${PARAM_HDFS_WORKING}/"
    make_dir "${PARAM_HDFS_WORKING}/"
    mr_trace "copy ${DN_TMP}/splitfile-*.txt to ${PARAM_HDFS_WORKING}"
    copy_file "${DN_TMP}/" "${PARAM_HDFS_WORKING}/" > /dev/null
    rm_f_dir "${DN_TMP}/"

    # this fix the user be changed problem
    [[ "${PARAM_HDFS_WORKING}"  =~ ^hdfs:// ]] && chmod_file -R 777 "${PARAM_HDFS_WORKING}/"

    local HD_MAP="-mapper /bin/cat"
    local HD_RED="-reducer /bin/cat"
    # combine all of the bash scripts to one file
    local FN_MAP=
    if [ ! "${PARAM_FNMAP}" = "" ]; then
        FN_MAP="/tmp/tmp-e${PARAM_STAGE}map-$(uuidgen).sh"
        mr_trace "generating exec file: ${PARAM_FNMAP}"
        ${PARAM_CB_GEN_MRBIN} "${DN_EXEC}/${PARAM_FNMAP}" "${FN_MAP}"
        RET=$(is_file_or_dir "${FN_MAP}")
        if [ ! "${RET}" = "f" ]; then
            mr_trace "Error: not found exec file: ${FN_MAP}"
            return
        fi
        RET=$(is_local "${FN_MAP}")
        if [ ! "${RET}" = "l" ]; then
            mr_trace "Error: not a local file: ${FN_MAP}"
            return
        fi
        chmod 755 "${FN_MAP}"
        if [ ! -e "${FN_MAP}" ]; then
            mr_trace "Error: not a exec file: ${FN_MAP}"
            return
        fi
        HD_MAP="-file ${FN_MAP} -mapper $(basename ${FN_MAP})"
    fi
    local FN_RED=
    if [ ! "${PARAM_FNRED}" = "" ]; then
        FN_RED="/tmp/tmp-e${PARAM_STAGE}red-$(uuidgen).sh"
        ${PARAM_CB_GEN_MRBIN} "${DN_EXEC}/${PARAM_FNRED}" "${FN_RED}"
        RET=$(is_file_or_dir "${FN_RED}")
        if [ ! "${RET}" = "f" ]; then
            mr_trace "Error: not found exec file: ${FN_RED}"
            return
        fi
        RET=$(is_local "${FN_RED}")
        if [ ! "${RET}" = "l" ]; then
            mr_trace "Error: not a local file: ${FN_RED}"
            return
        fi
        chmod 755 "${FN_RED}"
        if [ ! -e "${FN_RED}" ]; then
            mr_trace "Error: not a exec file: ${FN_RED}"
            return
        fi
        HD_RED="-file ${FN_RED} -reducer $(basename ${FN_RED})"
    fi

    rm_f_dir "${PARAM_HDFS_OUTPUT}"
    #make_dir "${PARAM_HDFS_OUTPUT}"
    #[[ "${PARAM_HDFS_OUTPUT}"  =~ ^hdfs:// ]] && chmod_file -R 777 "${PARAM_HDFS_OUTPUT}"
    mr_trace "hadoop stream: -input ${PARAM_HDFS_WORKING} -output ${PARAM_HDFS_OUTPUT} ${HD_MAP} ${HD_RED}"
    $MYEXEC ${EXEC_HADOOP} jar ${HADOOP_JAR_STREAMING} \
        -D mapred.job.name=${HDFF_PROJ_ID}-${PARAM_STAGE} \
        -D mapreduce.task.timeout=0 \
        -D stream.num.map.output.key.fields=${PARAM_KEYS_SEP} \
        -D num.key.fields.for.partition=${PARAM_KEYS_BLK} \
        -input "${PARAM_HDFS_WORKING}" -output "${PARAM_HDFS_OUTPUT}" \
        ${HD_MAP} ${HD_RED} \
        ${NULL}
    if [ ! "$?" = "0" ]; then
        mr_trace "Error in hadoop stage: ${PARAM_STAGE}"
        return
    fi

    [[ "${PARAM_HDFS_OUTPUT}"  =~ ^hdfs:// ]] && chmod_file -R 777 "${PARAM_HDFS_OUTPUT}"

    mr_trace move_file "${PARAM_HDFS_OUTPUT}/part-00000" "${PARAM_HDFS_OUTPUT}/redout.txt"
    move_file "${PARAM_HDFS_OUTPUT}/part-00000" "${PARAM_HDFS_OUTPUT}/redout.txt" > /dev/null

    if [ ! "${PARAM_CBEND}" = "" ]; then
        ${PARAM_CBEND}
    fi
}

#####################################################################
## @fn run_stage_sh1()
## @brief run map and reduce script in bash
## @param config_line config line, such as "e1map.sh,e1red.sh,6,5,cb_end_stage1"
## @param stage the stage #
## @param cb_gen_mrbin the callback function for generating single MR script
## @param hdfs_working the working directory
## @param hdfs_input the input directory
## @param hdfs_ouput the output directory
##
## <config line> format: "<map>,<reduce>,<# of output key>,<# of partition key>,<callback end function>"
##   java streaming argument 'stream.num.map.output.key.fields' is map to '# of output key'
##   java streaming argument 'num.key.fields.for.partition' is map to '# of partition key'
##   stream.num.map.output.key.fields >= num.key.fields.for.partition
##   'callback end function' is called at the end of function
##
## This function will split the input files to several files with prefix 'splitfile-'
## with the paremter HDFF_TOTAL_NODES from global config file. Then all these 'splitfile-' files
## will be used as input of the map task.
##
## The predefined variables should exist before call this function:
##     DN_EXEC
##
## example:
## run_stage "e1map.sh,,6,5," 1 "cb_null" "workingdir" "${DN_INPUT_HDFS}/0" "${DN_INPUT_HDFS}/1"
## run_stage "${DN_EXEC}/e1map.sh,,6,5," 1 "cb_null" "workingdir" "${DN_INPUT_HDFS}/0" "${DN_INPUT_HDFS}/1"
run_stage_sh1() {
    mr_trace "run_stage $@"

    local PARAM_CONFIG_LINE=$1
    shift
    local PARAM_STAGE=$1
    shift
    local PARAM_CB_GEN_MRBIN=$1
    shift
    local PARAM_HDFS_WORKING=$1
    shift
    local PARAM_HDFS_INPUT=$1
    shift
    local PARAM_HDFS_OUTPUT=$1
    shift

    local PARAM_FNMAP=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $1}')
    local PARAM_FNRED=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $2}')
    local PARAM_KEYS_SEP=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $3}')
    local PARAM_KEYS_BLK=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $4}')
    local PARAM_CBEND=$(echo $PARAM_CONFIG_LINE | awk -F, '{print $5}')

    local HD_MAP="cat"
    local HD_RED="cat"
    if [ ! "${PARAM_FNMAP}" = "" ]; then
        HD_MAP="${DN_EXEC}/${PARAM_FNMAP}"
    fi
    if [ ! "${PARAM_FNRED}" = "" ]; then
        HD_RED="${DN_EXEC}/${PARAM_FNRED}"
    fi

    mr_trace "Stage ${PARAM_STAGE} ..."
    rm_f_dir ${PARAM_HDFS_OUTPUT} > /dev/null
    make_dir ${PARAM_HDFS_OUTPUT} > /dev/null
    mr_trace "bash stream: -input ${PARAM_HDFS_INPUT}/redout.txt -output ${PARAM_HDFS_OUTPUT} ${HD_MAP} ${HD_RED}"
    cat_file ${PARAM_HDFS_INPUT}/redout.txt  | ${HD_MAP} | sort | save_file ${PARAM_HDFS_OUTPUT}/mapout.txt
    TM_MAP_MID=$(date +%s)
    cat_file ${PARAM_HDFS_OUTPUT}/mapout.txt | ${HD_RED} | sort | save_file ${PARAM_HDFS_OUTPUT}/redout.txt

    if [ ! "${PARAM_CBEND}" = "" ]; then
        ${PARAM_CBEND} 1>&2
    fi
    echo "${TM_MAP_MID}"
}

