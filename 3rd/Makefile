#MAKE=make

all: dist-gzip #ffmpeg gnuplot ns2
#all:
	echo "?=$?, @=$@, <=$<, #"

DN_PWD=$(shell pwd)
DN_SRC=sources
DN_TARGET_PREFIX=ffmpeg
TARGET=all
#USE_GPU=GPU_OPENCL
USE_GPU=GPU_CUDA

OPENGL_INCLUDES_DETECT=-I/usr/include

# $(call compile,"$(DN_PWD)","$(DN_SRC)","$(DN_TARGET_PREFIX)","$(TARGET)")
compile = mkdir -p "$(1)/$(2)" && mkdir -p "$(1)/$(3)-bin" && mkdir -p "$(1)/$(3)-compile" && cd "$(1)/$(3)-compile" \
            && cp "$(1)/Makefile.$(3)" Makefile \
            && sed -i "s|^PREFIX=.*$$|PREFIX=$(1)/$(3)-bin|g"  Makefile \
            && sed -i "s|^DN_SRC=.*$$|DN_SRC=$(1)/$(2)|g" Makefile \
            && sed -i "s|^DN_PATCH=.*$$|DN_PATCH=$(1)|g"  Makefile \
            && sed -i "s|^USE_GPU=.*$$|USE_GPU=$(USE_GPU)|g" Makefile \
            && cat "$(1)/Makefile.$(3)" | grep ^include | awk '{print $$2; }' | while read a ; do cp "$(1)/$$a" .; done \
            && if [ "$(USE_GPU)" = "GPU_CUDA" ]; then \
                sed -i 's|^DEPENDS_GL=.*$$|DEPENDS_GL=$$(CUDASDK)-install|g' Makefile ; \
              elif [ "$(USE_GPU)" = "GPU_OPENCL" ]; then \
                echo -e "\#include <GL/gl.h>\nint main() {return 0;}" > /tmp/a.c ; \
                cc $(OPENGL_INCLUDES_DETECT) /tmp/a.c; \
                if [ $$? = 0 ]; then \
                  sed -i 's|^DEPENDS_GL=.*$$|DEPENDS_GL=$$(OPENCL)-install|g' Makefile ; \
                fi ; \
              fi \
            && $(MAKE) get-sources \
            && $(MAKE) $(4) \
            $(NULL)

# $(call disttar,"$(DN_PWD)","$(DN_TARGET_PREFIX)","FN_LIST_INPUT")
disttar = cd $(1) && rm -f $(3) && ln -s $(2)-bin $(3) && ./striptarbar.sh $(4) $(3) $(3).tar.gz #&& rm -f $(3)

get-sources:
	$(call compile,$(DN_PWD),$(DN_SRC),ffmpeg,get-sources)
	$(call compile,$(DN_PWD),$(DN_SRC),bitcoin,get-sources)
	$(call compile,$(DN_PWD),$(DN_SRC),aircrack,get-sources)
	$(call compile,$(DN_PWD),$(DN_SRC),gnuplot,get-sources)
	$(call compile,$(DN_PWD),$(DN_SRC),ns2,get-sources)
	#$(call compile,$(DN_PWD),$(DN_SRC),ns2docsis,get-sources)

ffmpeg:
	$(call compile,$(DN_PWD),$(DN_SRC),$@,all)

bitcoin:
	$(call compile,$(DN_PWD),$(DN_SRC),$@,all)

aircrack:
	$(call compile,$(DN_PWD),$(DN_SRC),$@,all)

gnuplot:
	$(call compile,$(DN_PWD),$(DN_SRC),$@,all)

ns2:
	rm -f ns2-compile/ns-install
	$(call compile,$(DN_PWD),$(DN_SRC),$@,ns2)

ns2docsis:
	rm -f ns2-compile/ns-docsis-install
	$(call compile,$(DN_PWD),$(DN_SRC),ns2,ns2docsis)

dist-gzip: dist-gzip-aircrack dist-gzip-gnuplot dist-gzip-ffmpeg dist-gzip-ns2

dist-gzip-ffmpeg: ffmpeg
	echo "$<-git-$(shell uname -m)/usr/bin/ffmpeg"        >  fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/MP4Box"        >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/mediametrics"  >> fnl-$<.txt
	$(call disttar,$(DN_PWD),$<,$<-git-$(shell uname -m),fnl-$<.txt)

dist-gzip-bitcoin: bitcoin
	echo "$<-git-$(shell uname -m)/usr/bin/cpuminer-multi" >  fnl-$<.txt
	$(call disttar,$(DN_PWD),$<,$<-git-$(shell uname -m),fnl-$<.txt)

dist-gzip-aircrack: aircrack
	echo "$<-git-$(shell uname -m)/usr/bin/airbase-ng"    >  fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/aircrack-ng"   >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/airdecap-ng"   >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/airdecloak-ng" >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/aireplay-ng"   >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/airmon-ng"     >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/airodump-ng"   >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/airodump-ng-oui-update" >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/airolib-ng"    >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/airserv-ng"    >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/airtun-ng"     >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/hashcat"       >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/oclhashcat"    >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/bin/pyrit"         >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/lib/python2.7/"    >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/share/awk/"        >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/share/oclHashcat/" >> fnl-$<.txt
	echo "$<-git-$(shell uname -m)/usr/etc/hatcat/"       >> fnl-$<.txt
	$(call disttar,$(DN_PWD),$<,$<-git-$(shell uname -m),fnl-$<.txt)

dist-gzip-gnuplot: gnuplot
	echo "$<-5.0-$(shell uname -m)/usr/bin/gnuplot"      >  fnl-$<.txt
	echo "$<-5.0-$(shell uname -m)/usr/libexec/gnuplot/" >> fnl-$<.txt
	echo "$<-5.0-$(shell uname -m)/usr/share/gnuplot/"   >> fnl-$<.txt
	echo "$<-5.0-$(shell uname -m)/usr/bin/gawk"         >> fnl-$<.txt
	echo "$<-5.0-$(shell uname -m)/usr/lib/awk/"         >> fnl-$<.txt
	echo "$<-5.0-$(shell uname -m)/usr/lib/gawk/"        >> fnl-$<.txt
	echo "$<-5.0-$(shell uname -m)/usr/share/awk/"       >> fnl-$<.txt
	$(call disttar,$(DN_PWD),$<,$<-5.0-$(shell uname -m),fnl-$<.txt)

dist-gzip-ns2: ns2
	echo "ns-2.35-$(shell uname -m)/usr/bin/gnuplot"      >  fnl-$<.txt
	echo "ns-2.35-$(shell uname -m)/usr/libexec/gnuplot/" >> fnl-$<.txt
	echo "ns-2.35-$(shell uname -m)/usr/share/gnuplot/"   >> fnl-$<.txt
	echo "ns-2.35-$(shell uname -m)/usr/bin/gawk"         >> fnl-$<.txt
	echo "ns-2.35-$(shell uname -m)/usr/lib/awk/"         >> fnl-$<.txt
	echo "ns-2.35-$(shell uname -m)/usr/lib/gawk/"        >> fnl-$<.txt
	echo "ns-2.35-$(shell uname -m)/usr/share/awk/"       >> fnl-$<.txt
	echo "ns-2.35-$(shell uname -m)/usr/bin/ns"           >> fnl-$<.txt
	$(call disttar,$(DN_PWD),$<,ns-2.35-$(shell uname -m),fnl-$<.txt)

dist-gzip-ns2docsis: ns2docsis
	echo "ns-docsis-$(shell uname -m)/usr/bin/gnuplot"      >  fnl-$<.txt
	echo "ns-docsis-$(shell uname -m)/usr/libexec/gnuplot/" >> fnl-$<.txt
	echo "ns-docsis-$(shell uname -m)/usr/share/gnuplot/"   >> fnl-$<.txt
	echo "ns-docsis-$(shell uname -m)/usr/bin/gawk"         >> fnl-$<.txt
	echo "ns-docsis-$(shell uname -m)/usr/lib/awk/"         >> fnl-$<.txt
	echo "ns-docsis-$(shell uname -m)/usr/lib/gawk/"        >> fnl-$<.txt
	echo "ns-docsis-$(shell uname -m)/usr/share/awk/"       >> fnl-$<.txt
	echo "ns-docsis-$(shell uname -m)/usr/bin/ns"           >> fnl-$<.txt
	#echo "ns-docsis-$(shell uname -m)/usr/lib/tcl8/"        >> fnl-$<.txt
	#echo "ns-docsis-$(shell uname -m)/usr/lib/tcl8.6/"      >> fnl-$<.txt
	#echo "ns-docsis-$(shell uname -m)/usr/lib/tclcl/"       >> fnl-$<.txt
	#echo "ns-docsis-$(shell uname -m)/usr/lib/tk8.6/"       >> fnl-$<.txt
	$(call disttar,$(DN_PWD),ns2,ns-docsis-$(shell uname -m),fnl-$<.txt)
