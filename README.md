dpp-test
========


This folder contains the scripts to run various NS2 DOCSIS 3.1 tests.


Directory Structure
-------------------

├── lib/
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
│   ├── checkproj.sh        # run from each test case dir, to check if a test case is finished
│   ├── plotall.sh          # run from current dir, to plot all of figures of all test cases
│   ├── plotproj.sh         # run from each test case dir, to plot all of figures of a test case
│   ├── runall.sh           # run from current dir, to check and run all of the un-finshed test cases
│   ├── runproj.sh          # run from each test case dir, to check and run the un-finshed task of the test case
│   ├── main.tcl            # a template file for the TCL entry function of NS2
│   ├── run-conf.tcl        # TCL config variables
│   ├── common/             # This folder contains all of the scripts and data files to be used for the test, which will be copied to the working directory, while some of the files may also be modified for a specified test.
│   └── ...
├── 
└── config-sys.sh


Usage
-----

In summary, if you start a new test, you may want to clean the folder first:

    ./cleanall.sh

and then, run all of the tests:

    ./runall.sh

To check if all of the tests were finished correct, you may run the following commands and the file testfailed.txt contains the failed tests:

    ./checkall.sh

if you want to plot all of figures, type:

    ./plotall.sh



After run the script runall.sh, all of sub-folders, such as proj-base-prof-high2low, will contains the data files mixed with NS2 TCL scripts and ploted figures.
For example, the folder proj-base-prof-high2low/baseh2l_has_DRR_1/ will contains all of the TCL scripts and output data in it;
The folder name baseh2l_has_DRR_1 means the prefix "baseh2l", and use HAS("has") as application, using down-stream scheduler DRR, and with 1 HAS(TCP) flow.
If you want re-run the test, you may try:

    cd proj-base-prof-high2low/baseh2l_has_DRR_1/
    ../../../../ns main.tcl 1


