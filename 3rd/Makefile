
all: dist-gzip #ffmpeg gnuplot ns2
#all:
	echo "?=$?, @=$@, <=$<, #"

DN_PWD=$(shell pwd)
DN_SRC=sources
DN_TARGET_PREFIX=ffmpeg
TARGET=all
USE_GPU=1

OPENGL_INCLUDES_DETECT=-I/usr/include

# $(call compile,"$(DN_PWD)","$(DN_SRC)","$(DN_TARGET_PREFIX)","$(TARGET)")
compile = mkdir -p "$(1)/$(2)" && mkdir -p "$(1)/$(3)-bin" && mkdir -p "$(1)/$(3)-compile" && cd "$(1)/$(3)-compile" \
            && cp "$(1)/Makefile.$(3)" Makefile \
            && sed -i "s|^PREFIX=.*$$|PREFIX=$(1)/$(3)-bin|g"  Makefile \
            && sed -i "s|^DN_SRC=.*$$|DN_SRC=$(1)/$(2)|g" Makefile \
            && sed -i "s|^DN_PATCH=.*$$|DN_PATCH=$(1)|g"  Makefile \
            && sed -i "s|^USE_GPU=.*$$|USE_GPU=$(USE_GPU)|g" Makefile \
            && cat "$(1)/Makefile.$(3)" | grep ^include | awk '{print $$2; }' | while read a ; do cp "$(1)/$$a" .; done \
            && if [ "$(USE_GPU)" = "1" ]; then \
                sed -i 's|^DEPENDS_GL=.*$$|DEPENDS_GL=$$(CUDASDK)-install|g' Makefile ; \
              else \
                echo -e "\#include <GL/gl.h>\nint main() {return 0;}" > /tmp/a.c ; \
                cc $(OPENGL_INCLUDES_DETECT) a.c; \
                if [ $? = 0 ]; then \
                  sed -i 's|^DEPENDS_GL=.*$$|DEPENDS_GL=$$(MESA)-install|g' Makefile ; \
                fi ; \
              fi \
            && $(MAKE) get-sources && $(MAKE) $(4) \
            $(NULL)

# $(call disttar,"$(DN_PWD)","$(DN_TARGET_PREFIX)","FN_TARGET_PREFIX")
disttar = cd $(1) && rm -f $(3) && ln -s $(2)-bin $(3) && tar -cvzf $(3).tar.gz $(3)/* && rm -f $(3)

ffmpeg:
	$(call compile,$(DN_PWD),$(DN_SRC),$@,all)

gnuplot:
	$(call compile,$(DN_PWD),$(DN_SRC),$@,all)

ns2:
	$(call compile,$(DN_PWD),$(DN_SRC),$@,ns2)

ns2docsis:
	$(call compile,$(DN_PWD),$(DN_SRC),ns2,ns2docsis)

dist-gzip: dist-gzip-gnuplot dist-gzip-ns2 dist-gzip-ffmpeg

dist-gzip-ffmpeg: ffmpeg
	$(call disttar,$(DN_PWD),$<,$<-git-$(shell uname -m))

dist-gzip-gnuplot: gnuplot
	$(call disttar,$(DN_PWD),$<,$<-5.0-$(shell uname -m))

dist-gzip-ns2: ns2
	$(call disttar,$(DN_PWD),$<,ns-2.35-$(shell uname -m))

dist-gzip-ns2docsis: ns2docsis
	$(call disttar,$(DN_PWD),ns2,ns-docsis-$(shell uname -m))

# the size is too huge, >= 60MB
rm_file_list_huge= \
    usr/bin/gdaladdo \
    usr/bin/gdalbuildvrt \
    usr/bin/gdal_contour \
    usr/bin/gdaldem \
    usr/bin/gdalenhance \
    usr/bin/gdal_grid \
    usr/bin/gdalinfo \
    usr/bin/gdallocationinfo \
    usr/bin/gdalmanage \
    usr/bin/gdal_rasterize \
    usr/bin/gdalserver \
    usr/bin/gdalsrsinfo \
    usr/bin/gdaltindex \
    usr/bin/gdaltransform \
    usr/bin/gdal_translate \
    usr/bin/gdalwarp \
    usr/bin/ogr2ogr \
    usr/bin/ogrinfo \
    usr/bin/ogrlineref \
    usr/bin/ogrtindex \
    usr/bin/testepsg \
    $(NULL)

# some doc files
rm_file_list_exclude= \
    usr/doc/ \
    usr/gtk-doc/ \
    usr/man/ \
    usr/share/doc/ \
    usr/share/man/ \
    usr/var/cache/ \
    $(NULL)
