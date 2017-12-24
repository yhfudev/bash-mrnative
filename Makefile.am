SUBDIRS= doc

DOC_FILES0= \
    $(top_srcdir)/doc/mrns2fig-manual.tex \
    $(top_srcdir)/doc/cndoc.tex \
    $(top_srcdir)/doc/chap-design.tex \
    $(top_srcdir)/doc/figures/flowchart-1-ns2figures.dia \
    $(top_srcdir)/doc/figures/flowchart-1-ns2figures.eps \
    $(NULL)

#DOC_FILES= \
#    $(top_srcdir)/doc/attrtype.htm \
#    $(NULL)

EXTRA_DIST=autogen.sh autoclean.sh AUTHORS README.md ChangeLog \
    $(DOC_FILES) \
    $(NULL)

include_HEADERS = \
    $(top_srcdir)/bin/mod-hadooppbs-jobmain.sh \
    $(top_srcdir)/bin/mod-setenv-hadoop.sh \
    $(top_srcdir)/bin/mod-share-worker.sh \
    $(top_srcdir)/bin/run-hadoop.sh \
    $(top_srcdir)/bin/run-sh1.sh \
    $(top_srcdir)/lib/libbash.sh \
    $(top_srcdir)/lib/libconfig.sh \
    $(top_srcdir)/lib/libfs.sh \
    $(top_srcdir)/lib/libplot.sh \
    $(top_srcdir)/lib/libshrt.sh \
    $(top_srcdir)/lib/libhadoop.sh \
    $(top_srcdir)/app-conv2dash/e1map.sh \
    $(top_srcdir)/app-conv2dash/e1red.sh \
    $(top_srcdir)/app-conv2dash/e2map.sh \
    $(top_srcdir)/app-conv2dash/e2red.sh \
    $(top_srcdir)/app-conv2dash/e3red.sh \
    $(top_srcdir)/app-conv2dash/liball.sh \
    $(top_srcdir)/app-conv2dash/libapp.sh \
    $(top_srcdir)/app-conv2dash/README.md \
    $(top_srcdir)/app-conv2dash/input-examples/* \
    $(top_srcdir)/app-wpapw/e1map.sh \
    $(top_srcdir)/app-wpapw/e2map.sh \
    $(top_srcdir)/app-wpapw/liball.sh \
    $(top_srcdir)/app-wpapw/libapp.sh \
    $(top_srcdir)/app-test/e1map.sh \
    $(top_srcdir)/app-test/e2map.sh \
    $(top_srcdir)/app-test/liball.sh \
    $(top_srcdir)/app-test/libapp.sh \
    $(top_srcdir)/app-test/README.md \
    $(top_srcdir)/app-test/input/config-test.conf \
    $(top_srcdir)/app-ns2/e1map.sh \
    $(top_srcdir)/app-ns2/e2map.sh \
    $(top_srcdir)/app-ns2/e2red.sh \
    $(top_srcdir)/app-ns2/e3map.sh \
    $(top_srcdir)/app-ns2/liball.sh \
    $(top_srcdir)/app-ns2/libapp.sh \
    $(top_srcdir)/app-ns2/libns2figures.sh \
    $(top_srcdir)/app-ns2/checkall.sh \
    $(top_srcdir)/app-ns2/cleanall.sh \
    $(top_srcdir)/app-ns2/plotall.sh \
    $(top_srcdir)/app-ns2/runall.sh \
    $(top_srcdir)/app-ns2/main.tcl \
    $(top_srcdir)/app-ns2/run-conf.tcl \
    $(top_srcdir)/app-ns2/common/BG.dat \
    $(top_srcdir)/app-ns2/common/channels.dat \
    $(top_srcdir)/app-ns2/common/channels1G6.dat \
    $(top_srcdir)/app-ns2/common/cleanup.tcl \
    $(top_srcdir)/app-ns2/common/CMBGDS.dat \
    $(top_srcdir)/app-ns2/common/CMBGUS.dat \
    $(top_srcdir)/app-ns2/common/dash.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.ared.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.bbaqm.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.codel.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.drr.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.fcfs.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.fs.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.fsaqm.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.fsaqmdc.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.pb2codel.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.pb3codel.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.pb4codel.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.pf.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.pie.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.red.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.sfqcodel.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.tsfq.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.wtbbaqm.tcl \
    $(top_srcdir)/app-ns2/common/docsis-conf.wtfsaqmdc.tcl \
    $(top_srcdir)/app-ns2/common/docsis-util.tcl \
    $(top_srcdir)/app-ns2/common/flows-util.tcl \
    $(top_srcdir)/app-ns2/common/getall.sh \
    $(top_srcdir)/app-ns2/common/lossmon-util.tcl \
    $(top_srcdir)/app-ns2/common/networks.tcl \
    $(top_srcdir)/app-ns2/common/ping-util.tcl \
    $(top_srcdir)/app-ns2/common/profile.tcl \
    $(top_srcdir)/app-ns2/common/sched-defs.tcl \
    $(top_srcdir)/app-ns2/common/tcpudp-util.tcl \
    $(NULL)

noinst_HEADERS= \
    $(top_srcdir)/install-sh \
    $(top_srcdir)/mrsystem.conf \
    $(top_srcdir)/app-ns2/input-examples/config-jjmbase.sh \
    $(top_srcdir)/app-ns2/input-examples/config-jjmprof192m1p.sh \
    $(top_srcdir)/app-ns2/input-examples/config-jjmprof192m2p.sh \
    $(top_srcdir)/app-ns2/input-examples/config-jjmprof192m4p.sh \
    $(top_srcdir)/app-ns2/input-examples/config-jjmprof24m1p.sh \
    $(top_srcdir)/app-ns2/input-examples/config-jjmprof24m2p.sh \
    $(top_srcdir)/app-ns2/input-examples/config-jjmprof24m4p.sh \
    $(top_srcdir)/app-ns2/input-examples/config-proj-baseh2l.sh \
    $(top_srcdir)/app-ns2/input-examples/config-proj-basel2h.sh \
    $(top_srcdir)/app-ns2/input-examples/config-proj-verifyd30.sh \
    $(top_srcdir)/app-ns2/input-examples/config-proj-verifyd31.sh \
    $(top_srcdir)/app-ns2/input/* \
    $(NULL)


ChangeLog: .git
	if test -d $(srcdir)/.git; then                         \
      if test -f $(srcdir)/.last-cl-gen; then               \
        git log --no-merges --date-order --date=short       \
          $$(cat $(srcdir)/.last-cl-gen)..                  \
          | sed -e  '/^commit.*$$/d'                        \
          | awk '/^Author/ {sub(/\\$$/,""); getline t; print $$0 t; next}; 1' \
          | sed -e 's/^Author: //g'                         \
          | sed -e 's/>Date:   \([0-9]*-[0-9]*-[0-9]*\)/>\t\1/g' \
          | sed -e 's/^\(.*\) \(\)\t\(.*\)/\3    \1    \2/g' \
          > ChangeLog.tmp;                                  \
      else                                                  \
        git log --no-merges --date-order --date=short       \
          | sed -e  '/^commit.*$$/d'                        \
          | awk '/^Author/ {sub(/\\$$/,""); getline t; print $$0 t; next}; 1' \
          | sed -e 's/^Author: //g'                         \
          | sed -e 's/>Date:   \([0-9]*-[0-9]*-[0-9]*\)/>\t\1/g' \
          | sed -e 's/^\(.*\) \(\)\t\(.*\)/\3    \1    \2/g' \
          > ChangeLog.tmp;                                  \
      fi;                                                   \
      touch ChangeLog                                       \
        && git rev-list -n 1 HEAD >.last-cl-gen.tmp         \
        && (echo; cat $(srcdir)/ChangeLog) >>ChangeLog.tmp  \
        && mv -f ChangeLog.tmp $(srcdir)/ChangeLog          \
        && mv -f .last-cl-gen.tmp $(srcdir)/.last-cl-gen    \
        && rm -f ChangeLog.tmp;                             \
    fi
	if test -d $(srcdir)/.hg; then                          \
        hg log --template changelog > ChangeLog;            \
        touch $(srcdir)/.last-cl-gen;                       \
    fi
