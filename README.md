mrnativens2
===========


This folder contains the scripts to run various NS2 DOCSIS 3.1 tests.


Directory Structure
-------------------

├── lib/
│   ├── libconfig.sh        # bash lib for read config file
│   ├── libplot.sh          # bash lib for plotting
│   ├── libns2figures.sh    # bash lib for plotting ns2 figures
│   ├── libbash.sh          # bash lib misc functions
│   └── libshrt.sh          # bash lib for multi-process support
├── projconfigs/
│   ├── config-baseh2l.sh   # config file for test case: 1.9 Gbps channel, with 2 profiles, change from high profile to low profile
│   ├── config-basel2h.sh   # test case: 1.9 Gbps channel, with 2 profiles, change from low profile to high profile
│   ├── config-verifyd30.sh # test case: Docsis 3.0 42.88 Mbps channel, various flows
│   └── config-verifyd31.sh # test case: Docsis 3.1 1.9 Gbps channel, various flows
├── projtools/
│   ├── checkall.sh         # run from current dir, to check if all test cases are finished
│   ├── cleanall.sh         # run from current dir, to clean all of the temperary files
│   ├── plotall.sh          # run from current dir, to plot all of figures of all test cases
│   ├── plotfigns2.sh       # called by e2red.sh, to plot all kinds of figures
│   ├── runall.sh           # run from current dir, to check and run all of the un-finshed test cases
│   ├── run-sh1.sh          # signle host version, to check and run all of the un-finshed test cases
│   ├── run-hadoop.sh       # hadoop version, to check and run all of the un-finshed test cases
│   ├── run-hadooppbs.sh    # hadoop for HPC version, to check and run all of the un-finshed test cases
│   ├── mod-hadooppbs-jobmain.sh # main entry for HPC Hadoop
│   ├── mod-hadooppbs-setenv.sh  # environment variables for HPC Hadoop
│   ├── mod-share-worker.sh # Hadoop main flow for both run-hadoop.sh and run-hadooppbs.sh
│   ├── e1map.sh            # map-reduce function, map() for stage 1
│   ├── e2map.sh            # map-reduce function, map() for stage 2
│   ├── e2red.sh            # map-reduce function, reduce() for stage 2
│   ├── libapp.sh           # help functions for NS2
│   ├── main.tcl            # a template file for the TCL entry function of NS2
│   ├── run-conf.tcl        # TCL config variables
│   ├── common/             # This folder contains all of the scripts and data files to be used for the test, which will be copied to the working directory, while some of the files may also be modified for a specified test.
│   └── ...
├── 
└── mrsystem.conf           # global config variables


Usage
-----

In summary, if you start a new test, you may want to clean the folder first:

    ./cleanall.sh

and then, run all of the tests:

    ./runall.sh

To check if all of the tests were finished correctly, you may run the following command to show the failed tests:

    ./checkall.sh

if you want to plot all of figures again, type:

    ./plotall.sh



After run the script runall.sh, all of sub-folders in mapreduce-results/dataconf, such as verifyd30_tcp_DRR_1, will contains the data files mixed with NS2 TCL scripts and ploted figures.
For example, the folder mapreduce-results/dataconf/verifyd30_tcp_DRR_1/ will contains all of the TCL scripts and output data in it;
The folder name verifyd30_tcp_DRR_1 means the prefix "verifyd30", and use FTP("tcp") as application, using down-stream scheduler DRR, and with 1 FTP flow.
If you want re-run the test, you may try:

    cd mapreduce-results/dataconf/verifyd30_tcp_DRR_1
    ns main.tcl 1


To run this software in Hadoop environment, you need pack two tar files, the ns2 binary and this folder.
You can tar this folder by:
    ./autogen.sh
    configure
    make dist-gzip

