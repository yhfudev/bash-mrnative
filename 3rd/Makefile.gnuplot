# Auto-Build gnuplot from source

# Prerequist:
# 1. basic compiler
#  1) RedHat/CentOS:
#     yum -y groupinstall "Development Tools"
#     yum -y install gcc-c++ rpm-build rpmdevtools binutils-devel autoconf automake libtool autogen intltool bison flex gdb make cvs subversion git mercurial patch gawk
#  2) Debian/Ubuntu
#     sudo apt-get install -y build-essential g++ autoconf automake libtool autogen intltool bison flex gdb make cvs subversion subversion-tools git mercurial patch gawk

######################################################################
# define the directory stores all of the source code packages
DN_SRC=$(PWD)/../sources
DN_TOP=$(PWD)
DN_PATCH=$(PWD)/../sources
PREFIX=$(PWD)/target
STRLOGO=yhfudev

######################################################################
all: get-sources gawk gnuplot

######################################################################
include Makefile.common

########################################
LIBXPM=libXpm
LIBXPM_VERSION=3.5.11
LIBXPM_SRC=$(LIBXPM)-$(LIBXPM_VERSION).tar.gz
LIBXPM_URL="http://xorg.freedesktop.org/releases/individual/lib/$(LIBXPM_SRC)"

$(DN_SRC)/$(LIBXPM_SRC): $(DN_SRC)/created
	$(WGET) -O $@ -c $(LIBXPM_URL)
	touch $@
$(LIBXPM)-$(LIBXPM_VERSION)/configure: $(DN_SRC)/$(LIBXPM_SRC)
	tar -xf $(DN_SRC)/$(LIBXPM_SRC)
	#mv $(LIBXPM)-$(LIBXPM_VERSION) $(LIBXPM)-$(LIBXPM_VERSION)/
	touch $@
$(LIBXPM)-$(LIBXPM_VERSION)/Makefile: $(LIBXPM)-$(LIBXPM_VERSION)/configure $(FL_DEP_LIBXPM)
	cd $(LIBXPM)-$(LIBXPM_VERSION)/ && ./configure --prefix=$(PREFIX) --enable-static --disable-shared
$(LIBXPM)-$(LIBXPM_VERSION)/libxpm.a: $(LIBXPM)-$(LIBXPM_VERSION)/Makefile
	cd $(LIBXPM)-$(LIBXPM_VERSION)/ && make $(MAKE_ARG)
$(PREFIX)/lib/libxpm.a: $(LIBXPM)-$(LIBXPM_VERSION)/libxpm.a
	cd $(LIBXPM)-$(LIBXPM_VERSION)/ && make install

$(LIBXPM)-uninstall: $(LIBXPM)-$(LIBXPM_VERSION)/LIBXPM
	cd $(LIBXPM)-$(LIBXPM_VERSION)/ && make uninstall
$(LIBXPM)-install: $(PREFIX)/lib/libxpm.a
	touch $@

FL_SOURCES+=$(DN_SRC)/$(LIBXPM_SRC)
#FL_DEP_GNUPLOT+=$(LIBXPM)-install
FL_UNINSTALL+=$(LIBXPM)-uninstall


########################################
LIBTIFF=libtiff
LIBTIFF_VERSION=4.0.6
LIBTIFF_SRC=$(LIBTIFF)-$(LIBTIFF_VERSION).tar.gz
LIBTIFF_URL="http://download.osgeo.org/libtiff/tiff-$(LIBTIFF_VERSION).tar.gz"

$(DN_SRC)/$(LIBTIFF_SRC): $(DN_SRC)/created
	$(WGET) -O $@ -c $(LIBTIFF_URL)
	touch $@
$(LIBTIFF)-$(LIBTIFF_VERSION)/configure: $(DN_SRC)/$(LIBTIFF_SRC)
	tar -xf $(DN_SRC)/$(LIBTIFF_SRC)
	mv tiff-$(LIBTIFF_VERSION) $(LIBTIFF)-$(LIBTIFF_VERSION)/
	touch $@
$(LIBTIFF)-$(LIBTIFF_VERSION)/Makefile: $(LIBTIFF)-$(LIBTIFF_VERSION)/configure $(FL_DEP_LIBTIFF)
	cd $(LIBTIFF)-$(LIBTIFF_VERSION)/ && ./configure --prefix=$(PREFIX) --enable-static --disable-shared
$(LIBTIFF)-$(LIBTIFF_VERSION)/libtiff.a: $(LIBTIFF)-$(LIBTIFF_VERSION)/Makefile
	cd $(LIBTIFF)-$(LIBTIFF_VERSION)/ && make $(MAKE_ARG)
$(PREFIX)/lib/libtiff.a: $(LIBTIFF)-$(LIBTIFF_VERSION)/libtiff.a
	cd $(LIBTIFF)-$(LIBTIFF_VERSION)/ && make install

$(LIBTIFF)-uninstall: $(LIBTIFF)-$(LIBTIFF_VERSION)/libtiff.a
	cd $(LIBTIFF)-$(LIBTIFF_VERSION)/ && make uninstall
$(LIBTIFF)-install: $(PREFIX)/lib/libtiff.a
	touch $@

FL_SOURCES+=$(DN_SRC)/$(LIBTIFF_SRC)
#FL_DEP_GNUPLOT+=$(LIBTIFF)-install
FL_UNINSTALL+=$(LIBTIFF)-uninstall

########################################
LUA=lua
LUA_VERSION=5.3.1
LUA_SRC=$(LUA)-$(LUA_VERSION).tar.gz
LUA_URL="http://www.lua.org/ftp/$(LUA_SRC)"

$(DN_SRC)/$(LUA_SRC): $(DN_SRC)/created
	$(WGET) -O $@ -c $(LUA_URL)
	touch $@
$(LUA)-$(LUA_VERSION)/Makefile: $(DN_SRC)/$(LUA_SRC)
	tar -xf $(DN_SRC)/$(LUA_SRC)
	touch $@
$(LUA)-$(LUA_VERSION)/lua: $(LUA)-$(LUA_VERSION)/Makefile $(FL_DEP_LUA)
	cd $(LUA)-$(LUA_VERSION)/ \
	    && make $(MAKE_ARG) MYCFLAGS="$$CFLAGS -DLUA_COMPAT_5_2 -DLUA_COMPAT_5_1" MYLDFLAGS="$$LDFLAGS" linux
$(PREFIX)/bin/lua: $(LUA)-$(LUA_VERSION)/lua
	cd $(LUA)-$(LUA_VERSION)/ && make TO_LIB="liblua.a" INSTALL_DATA='cp -d' INSTALL_TOP=$(PREFIX) INSTALL_MAN=$(PREFIX)/usr/share/man/man1 install

$(LUA)-uninstall: $(LUA)-$(LUA_VERSION)/lua
	cd $(LUA)-$(LUA_VERSION)/ && make uninstall
$(LUA)-install: $(PREFIX)/bin/lua
	touch $@

FL_SOURCES+=$(DN_SRC)/$(LUA_SRC)
#FL_DEP_GNUPLOT+=$(LUA)-install
FL_UNINSTALL+=$(LUA)-uninstall

########################################
GD=gd
GD_VERSION=2.1.1
GD_SRC=$(GD)-$(GD_VERSION).tar.gz
GD_URL="https://github.com/libgd/libgd/archive/$(GD_SRC)"

LIBGD=libgd
LIBGD_VERSION=2.1.1
LIBGD_SRC=$(LIBGD)-$(LIBGD_VERSION).tar.gz
LIBGD_URL="https://github.com/libgd/libgd/releases/download/gd-$(LIBGD_VERSION)/$(GD_SRC)"

FL_DEP_GD= \
	$(LUA)-install \
	$(LIBXPM)-install \
	$(LIBTIFF)-install \
	$(LVPX)-install \
	$(NULL)

$(DN_SRC)/$(GD_SRC): $(DN_SRC)/created
	$(WGET) -O $@ -c $(GD_URL)
	touch $@
$(GD)-$(GD_VERSION)/configure: $(DN_SRC)/$(GD_SRC)
	tar -xf $(DN_SRC)/$(GD_SRC)
	mv libgd-gd-$(GD_VERSION) $(GD)-$(GD_VERSION)/
	cd $(GD)-$(GD_VERSION)/ && ./bootstrap.sh
	touch $@
$(GD)-$(GD_VERSION)/mypatched: $(DN_PATCH)/pbs-libgd-libvpx.patch $(GD)-$(GD_VERSION)/configure
	cd $(GD)-$(GD_VERSION)/ && patch -p1 < $(DN_PATCH)/pbs-libgd-libvpx.patch
	touch $@
$(GD)-$(GD_VERSION)/Makefile: $(GD)-$(GD_VERSION)/configure $(GD)-$(GD_VERSION)/mypatched $(FL_DEP_GD)
	cd $(GD)-$(GD_VERSION)/ && ./configure --prefix=$(PREFIX) --with-vpx=$(PREFIX)  --enable-static --disable-shared --disable-rpath --without-tiff #--with-tiff=$(PREFIX)
$(GD)-$(GD_VERSION)/gd: $(GD)-$(GD_VERSION)/Makefile
	cd $(GD)-$(GD_VERSION)/ && make $(MAKE_ARG)
$(PREFIX)/bin/gd: $(GD)-$(GD_VERSION)/gd
	cd $(GD)-$(GD_VERSION)/ && make install

$(GD)-uninstall: $(GD)-$(GD_VERSION)/gd
	cd $(GD)-$(GD_VERSION)/ && make uninstall
$(GD)-install: $(PREFIX)/bin/gd
	touch $@


FL_SOURCES+=$(DN_SRC)/$(GD_SRC)
FL_DEP_GNUPLOT+=$(GD)-install
FL_UNINSTALL+=$(GD)-uninstall

########################################
GNUPLOT=gnuplot
GNUPLOT_VERSION=5.0.1
GNUPLOT_SRC=$(GNUPLOT)-$(GNUPLOT_VERSION).tar.gz
GNUPLOT_URL=http://sourceforge.net/projects/gnuplot/files/gnuplot/$(GNUPLOT_VERSION)/$(GNUPLOT_SRC)

$(DN_SRC)/$(GNUPLOT_SRC): $(DN_SRC)/created
	$(WGET) -O $@ -c $(GNUPLOT_URL)
	touch $@
$(GNUPLOT)-$(GNUPLOT_VERSION)/configure: $(DN_SRC)/$(GNUPLOT_SRC)
	tar -xf $(DN_SRC)/$(GNUPLOT_SRC)
	touch $@

$(GNUPLOT)-$(GNUPLOT_VERSION)/mypatched: $(DN_PATCH)/pbs-gnuplot-lua.patch $(GNUPLOT)-$(GNUPLOT_VERSION)/configure
	cd $(GNUPLOT)-$(GNUPLOT_VERSION)/ && patch -p1 < $(DN_PATCH)/pbs-gnuplot-lua.patch
	touch $@

$(GNUPLOT)-$(GNUPLOT_VERSION)/Makefile: $(GNUPLOT)-$(GNUPLOT_VERSION)/mypatched $(GNUPLOT)-$(GNUPLOT_VERSION)/configure $(FL_DEP_GNUPLOT)
	cd $(GNUPLOT)-$(GNUPLOT_VERSION)/ && ./configure --prefix=$(PREFIX) --with-vpx=$(PREFIX) --with-tiff=$(PREFIX) --disable-rpath --disable-qt
$(GNUPLOT)-$(GNUPLOT_VERSION)/gnuplot: $(GNUPLOT)-$(GNUPLOT_VERSION)/Makefile
	cd $(GNUPLOT)-$(GNUPLOT_VERSION)/ && make $(MAKE_ARG)
$(PREFIX)/bin/gnuplot: $(GNUPLOT)-$(GNUPLOT_VERSION)/gnuplot
	cd $(GNUPLOT)-$(GNUPLOT_VERSION)/ && make install

$(GNUPLOT)-uninstall: $(GNUPLOT)-$(GNUPLOT_VERSION)/gnuplot
	cd $(GNUPLOT)-$(GNUPLOT_VERSION)/ && make uninstall
$(GNUPLOT)-install: $(PREFIX)/bin/gnuplot
	touch $@


FL_SOURCES+=$(DN_SRC)/$(GNUPLOT_SRC)
#FL_DEP_GNUPLOT+=$(GNUPLOT)-install
FL_UNINSTALL+=$(GNUPLOT)-uninstall


########################################
GNUAWK=gawk
GNUAWK_VERSION=4.1.3
GNUAWK_SRC=$(GNUAWK)-$(GNUAWK_VERSION).tar.gz
GNUAWK_URL=http://ftp.gnu.org/gnu/gawk/$(GNUAWK_SRC)

$(DN_SRC)/$(GNUAWK_SRC): $(DN_SRC)/created
	$(WGET) -O $@ -c $(GNUAWK_URL)
	touch $@
$(GNUAWK)-$(GNUAWK_VERSION)/configure: $(DN_SRC)/$(GNUAWK_SRC)
	tar -xf $(DN_SRC)/$(GNUAWK_SRC)
	touch $@

#$(GNUAWK)-$(GNUAWK_VERSION)/mypatched: $(DN_PATCH)/pbs-GNUAWK-lua.patch $(GNUAWK)-$(GNUAWK_VERSION)/configure
#	cd $(GNUAWK)-$(GNUAWK_VERSION)/ && patch -p1 < $(DN_PATCH)/pbs-GNUAWK-lua.patch
#	touch $@

$(GNUAWK)-$(GNUAWK_VERSION)/Makefile: $(GNUAWK)-$(GNUAWK_VERSION)/configure $(FL_DEP_GNUAWK)
	cd $(GNUAWK)-$(GNUAWK_VERSION)/ && ./configure --prefix=$(PREFIX) --libexecdir=$(PREFIX)/lib  --enable-switch --disable-libsigsegv --with-libsigsegv-prefix=no
$(GNUAWK)-$(GNUAWK_VERSION)/gawk: $(GNUAWK)-$(GNUAWK_VERSION)/Makefile
	cd $(GNUAWK)-$(GNUAWK_VERSION)/ && make $(MAKE_ARG)
$(PREFIX)/bin/gawk: $(GNUAWK)-$(GNUAWK_VERSION)/gawk
	cd $(GNUAWK)-$(GNUAWK_VERSION)/ && make install

$(GNUAWK)-uninstall: $(GNUAWK)-$(GNUAWK_VERSION)/gawk
	cd $(GNUAWK)-$(GNUAWK_VERSION)/ && make uninstall
$(GNUAWK)-install: $(PREFIX)/bin/gawk
	touch $@


FL_SOURCES+=$(DN_SRC)/$(GNUAWK_SRC)
#FL_DEP_GNUAWK+=$(GNUAWK)-install
FL_UNINSTALL+=$(GNUAWK)-uninstall

########################################
.PHONY: get-sources

$(DN_SRC)/created:
	make -p $(DN_SRC)
	touch $@

get-sources: $(DN_SRC)/created $(FL_SOURCES) $(FL_SOURCES_OTHERS)

gawk: $(GNUAWK)-install

gnuplot: $(GNUPLOT)-install

uninstall: $(FL_UNINSTALL)

clean:
	@rm -rf target $(FL_DEP_GNUPLOT) $(FL_DEP_GAWK)

distclean: clean
	@mkdir -p target/
	@touch i_should_be_removed
	@(echo "nullname" && ls) | grep -v run.sh | grep -v target | grep -v Makefile | grep -v distclean | grep -v sources | grep -v .patch | xargs sh -c 'mv "$$@" target'
	@rm -rf target
