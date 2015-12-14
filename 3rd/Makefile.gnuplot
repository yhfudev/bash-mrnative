# Auto-Build gnuplot from source

# Prerequist:
# 1. basic compiler
#  1) RedHat/CentOS:
#     yum -y groupinstall "Development Tools"
#     yum -y install gcc-c++ rpm-build rpmdevtools binutils-devel bison flex gdb make cvs subversion git mercurial patch gawk
#  2) Debian/Ubuntu
#     sudo apt-get install -y build-essential g++ bison flex gdb make cvs subversion subversion-tools git mercurial patch gawk

######################################################################
# define the directory stores all of the source code packages
DN_SRC=$(PWD)/../sources
DN_TOP=$(PWD)
DN_PATCH=$(PWD)/../sources
PREFIX=$(PWD)/target
STRLOGO=yhfudev
USE_GPU=0

######################################################################
all: get-sources gawk gnuplot

######################################################################
include Makefile.common

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
