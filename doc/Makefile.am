if ENABLE_DOXYGEN_DOC

EXTRA_DIST=genfooter.tex genheader.tex doxygen-bash.sed

all-local: doxygen.stamp

DOCSOURCES := Doxyfile.in $(top_srcdir)/README.md \
    $(wildcard $(top_srcdir)/src/*.c) \
    $(wildcard $(top_srcdir)/src/*.cc) \
    $(wildcard $(top_srcdir)/src/*.cpp) \
    $(wildcard $(top_srcdir)/src/*.h) \
    $(wildcard $(top_srcdir)/bin/*.sh) \
    $(wildcard $(top_srcdir)/lib/*.sh) \
    $(wildcard $(top_srcdir)/app-conv2dash/*.sh) \
    $(wildcard $(top_srcdir)/app-ns2/*.sh) \
    $(wildcard $(top_srcdir)/app-test/*.sh) \
    $(wildcard $(top_srcdir)/app-wpapw/*.sh) \
    $(NULL)

doxygen.stamp: $(DOCSOURCES)
	$(DOXYGEN)
	touch doxygen.stamp

install-data-local: install-html

install-html:
	$(INSTALL) -d $(DESTDIR)$(htmldocdir)
	$(INSTALL_DATA) html/* $(DESTDIR)$(htmldocdir)

uninstall-local:
	rm -rf $(DESTDIR)$(htmldocdir)

clean-local:
	rm -rf html man latex
	rm -f doxygen.stamp

else

install-data-local:
uninstall-local:
clean-local:

endif

