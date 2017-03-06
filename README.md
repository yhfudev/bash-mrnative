mrnative
========

This folder contains the scripts to run native software in an Hadoop/HPC environment.

The example applications including:

  * an test app to collect the information of the hosts in the cluster
  * an transcoding application which convert a multimedia content to MPD/segments files for Dynamic Adaptive Streaming over HTTP
  * an hashcat distribution framework
  * an NS-2 distribution simulation framework


Introduction
------------

One of method to speed-up a CPU-intense application is to parallel the internal processing flows.
There're many solutions to get it done, such as
[GNU Parallel](https://www.gnu.org/software/parallel/),
[Hadoop](http://hadoop.apache.org/).
Though GNU Parallel can run jobs over one or more computers,
it need user to specify how the work is dispatched to the hosts.



Directory Structure
-------------------

    ├── bin/
    │   ├── run-sh1.sh          # single host version, to check and run all of the un-finished test cases
    │   ├── run-hadoop.sh       # hadoop version, to check and run all of the un-finished test cases
    │   ├── run-hadooppbs.sh    # hadoop for HPC version, to check and run all of the un-finished test cases
    │   ├── mod-hadooppbs-jobmain.sh # main entry for HPC Hadoop
    │   ├── mod-hadooppbs-setenv.sh  # environment variables for HPC Hadoop
    │   ├── mod-share-worker.sh # Hadoop main flow for both run-hadoop.sh and run-hadooppbs.sh
    │   └── ...
    ├── lib/
    │   ├── libconfig.sh        # bash lib for read configure file
    │   ├── libplot.sh          # bash lib for plotting
    │   ├── libns2figures.sh    # bash lib for plotting ns2 figures
    │   ├── libbash.sh          # bash lib misc functions
    │   └── libshrt.sh          # bash lib for multi-process support
    ├── app-test/               # the test script that can generate a list of the configuration of your Hadoop system
    │   ├── input/              # input/ directory contains the configure files for the test.
    │   ├── libapp.sh           # help functions for the tool
    │   ├── e1map.sh            # map-reduce function, map() for stage 1
    │   ├── e2map.sh            # map-reduce function, map() for stage 2
    │   └── ...
    ├── app-conv2dash/          # the media converting tools for Dynamic Adaptive Streaming over HTTP
    │   ├── input/              # input/ directory contains the configure files for the DASH MPD trans-codes.
    │   ├── input-examples/     # some example files for input/ directory
    │   ├── libapp.sh           # help functions for the tool
    │   ├── e1map.sh            # map-reduce function, map() for stage 1, reads the configure files from input/ folder and generates the file name list
    │   ├── e1red.sh            # map-reduce function, reduce() for stage 1, get a sorted list of file names grouped by the key for stage 2 map()
    │   ├── e2map.sh            # map-reduce function, map() for stage 2, trans-code the media segments
    │   ├── e2red.sh            # map-reduce function, reduce() for stage 2, output concated media files, generate the metric values for the media files/segments
    │   ├── e3map.sh            # map-reduce function, map() for stage 3, generates DASH MPD files
    │   └── ...
    ├── app-ns2/                # the NS-2 simulation application directory
    │   ├── input/              # input/ directory contains the configure files for the NS2 simulations.
    │   ├── input-examples/     # some example files for input/ directory
    │   │   ├── config-baseh2l.sh   # configure file for test case: 1.9 Gbps channel, with 2 profiles, change from high profile to low profile
    │   │   ├── config-basel2h.sh   # test case: 1.9 Gbps channel, with 2 profiles, change from low profile to high profile
    │   │   ├── config-verifyd30.sh # test case: DOCSIS 3.0 42.88 Mbps channel, various flows
    │   │   └── config-verifyd31.sh # test case: DOCSIS 3.1 1.9 Gbps channel, various flows
    │   ├── libapp.sh           # help functions for NS2
    │   ├── e1map.sh            # map-reduce function, map() for stage 1, reads the configure files from input/ folder and generates the input data stream for stage 2 map()
    │   ├── e2map.sh            # map-reduce function, map() for stage 2, run the simulations
    │   ├── e2red.sh            # map-reduce function, reduce() for stage 2, plot figures
    │   ├── main.tcl            # a template file for the TCL entry function of NS2
    │   ├── checkall.sh         # run from current dir, to check if all test cases are finished
    │   ├── cleanall.sh         # run from current dir, to clean all of the temperately files
    │   ├── plotall.sh          # run from current dir, to plot all of figures of all test cases
    │   ├── plotfigns2.sh       # called by e2red.sh, to plot all kinds of figures
    │   ├── runall.sh           # run from current dir, to check and run all of the un-finished test cases
    │   ├── run-conf.tcl        # TCL configure variables
    │   ├── common/             # This folder contains all of the scripts and data files to be used for the test, which will be copied to the working directory, while some of the files may also be modified for a specified test.
    │   └── ...
    ├── 
    └── mrsystem.conf           # global configure variables


Run your code in HPC environment
--------------------------------

Install [myhadoop](https://github.com/yhfudev/myhadoop.git):

    cd
    mkdir -p software/src/
    cd software/src/
    git clone https://github.com/yhfudev/myhadoop.git myhadoop-yhfudev-git

If you install the myhadoop to other folder, please change the path variable MY_HADOOP_HOME in the file bin/mod-setenv-hadoop.sh.



Usage for app-test
------------------

This is to test if the environment and softwares are installed correctly.
The hardware and package list are printed out after run this script.

    cd app-test
    ../run-sh1.sh


Usage for app-conv2dash
-----------------------

The scripts in the folder app-conv2dash is to convert a multimedia content to MPD/segments files for Dynamic Adaptive Streaming over HTTP.
You need the following softwares installed in your system:

  * [ffmpeg](https://ffmpeg.org/),
  * [mediametrics](https://github.com/yhfudev/mediametrics.git),
  * [MP4Box](https://github.com/gpac/gpac.git) (gpac)


To prepare the data, the user should create a config-* file in the folder app-conv2dash/input/
and put the following in the file:

    # if generate the snapshot picture, set it to 1
    HDFF_SNAPSHOT=1

    # the resolutions for transcoding
    # video resolution + video bitrate + audio bitrate
    #HDFF_TRANSCODE_RESOLUTIONS=320x180+315k+64k,640x360+500k+64k,853x480+1000k+192k,1280x720+1500k+256k,1280x720+2600k+256k,1920x1080+3800k+256k,1920x1080+4800k+256k,3840x1714+9000k+256k,3840x1714+12000k+256k
    #HDFF_TRANSCODE_RESOLUTIONS=320x180+315k+64k,640x360+500k+64k,853x480+1000k+192k
    HDFF_TRANSCODE_RESOLUTIONS=320x180+315k+64k,640x360+500k+64k

    # the screen size for mmetrics
    # http://en.wikipedia.org/wiki/File:Vector_Video_Standards2.svg
    # HD 1.78:1(16:9), ?,?,?,720p,1080p(2k),4k,8k
    #HDFF_SCREEN_RESOLUTIONS=320x180,640x360,854x480,1280x720,1920x1080,3840x2160,7680x4320
    #HDFF_SCREEN_RESOLUTIONS=320x180,640x360
    HDFF_SCREEN_RESOLUTIONS=320x180

    # WHXGA 1.60:1 (16:10), 4k
    #HDFF_SCREEN_RESOLUTIONS=320x200,1280x800,1680x1050,1920x1200,2560x1600,5120x3200

    # VGA 1.33:1 (4:3); QVGA,VGA,PAL,SVGA,XGA,?,SXGA+,UXGA,QXGA
    #HDFF_SCREEN_RESOLUTIONS=320x240,640x480,768x576,800x600,1024x786,1280x960,1400x1050,1600x1200,2048x1536


    # global options for ffmpeg
    #OPTIONS_FFM_GLOBAL="-threads 0"
    OPTIONS_FFM_GLOBAL=
    OPTIONS_FFM_ASYNC="-async 2286 -vsync 2"
    OPTIONS_FFM_AUDIO=
    #OPTIONS_FFM_VIDEO="-keyint_min 48 -g 48"
    # -keyint_min <Minimum GOP length, the minimum distance between I-frames. Recommended default: 25>
    # -g <Keyframe interval, GOP length>
    OPTIONS_FFM_VIDEO="-keyint_min 150 -g 150 -sc_threshold 0"

    # the transcode codec for the ffmpeg -- using mpeg4
    #OPTIONS_FFM_VCODEC="-vcodec mpeg4"
    #OPTIONS_FFM_ACODEC="-c:a aac -strict -2"
    #OPTIONS_FFM_VCODEC_SUFFIX="mp4"

    # the transcode codec for the ffmpeg -- using webm
    #OPTIONS_FFM_VCODEC="-vcodec libvpx-vp9 -strict experimental"
    OPTIONS_FFM_VCODEC="-vcodec libvpx"
    OPTIONS_FFM_ACODEC="-c:a libvorbis"
    OPTIONS_FFM_VCODEC_SUFFIX="webm"


And then place the input-* files in which contains the lines that specify the media input files, such as

    origvid	"trailer/sintel_trailer-audio.flac"	"trailer/sintel_trailer-lossless-1080p.mkv"	10


To run the transcoding, user should make sure the directory of the binary should in your PATH environment,
and run following commands:

    cd app-conv2dash
    ../run-sh1.sh


Usage for app-wpapw
-------------------

The scripts in the folder app-wpapw is to crack the WPA password with hashcap.
You need the following softwares installed in your system:

  * [hashcap](https://github.com/hashcat/hashcat.git),
  * [aircrack-ng](https://www.aircrack-ng.org/)

To prepare the data, the user should create a config-* file in the folder app-wpapw/input/
and put the following in the file:

    # the word list
    HDFF_WORDLISTS=wl1.txt:wl2.txt

    # the rule list for the hashcat
    HDFF_RULELISTS=best64:combinator

    # the number of entries for each segment of wordlist/pattern
    # default: 10000000
    HDFF_SIZE_SEGMENT=10000000

    # if we use mask, such as ?d?d?d?d?d for hashcat
    HDFF_USE_MASK=1

And then place the input-* files in which contains the lines that specify the media input files, such as

    wpa	"wpahome/ATT749-hs.hccap"
    wpa	"wpahome/ATT103-hs.hccap"

To run the cracking, user should make sure the directory of the binary should in your PATH environment,
and run following commands for single host cracking:

    cd app-wpapw
    ../run-sh1.sh





Usage for app-ns2
-----------------

In summary, if you start a new test, you may want to clean the folder first:

    ./cleanall.sh

and then, run all of the tests:

    ./runall.sh

To check if all of the tests were finished correctly, you may run the following command to show the failed tests:

    ./checkall.sh

if you want to plot all of figures again, type:

    ./plotall.sh



After run the script runall.sh, all of sub-folders in mapreduce-results/dataconf, such as verifyd30_tcp_DRR_1, will contains the data files mixed with NS2 TCL scripts and plotted figures.
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

