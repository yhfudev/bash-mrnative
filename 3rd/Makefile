
all: ffmpeg gnuplot ns2
	echo "?=$?, @=$@, <=$<"

DN_PWD=$(shell pwd)
DN_SRC=sources
DN_TARGET=ffmpeg
TARGET=all
# $(call compile,"$(DN_PWD)","$(DN_SRC)","$(DN_TARGET)","$(TARGET)")
compile = mkdir -p "$(1)/$(2)" && mkdir -p "$(1)/$(3)-bin" && mkdir -p "$(1)/$(3)-compile" && cd "$(1)/$(3)-compile" \
            && cp "$(1)/Makefile.$(3)" Makefile \
            && sed -i "s|^PREFIX=.*$$|PREFIX=$(1)/$(3)-bin|g"  Makefile \
            && sed -i "s|^DN_SRC=.*$$|DN_SRC=$(1)/$(2)|g" Makefile \
            && sed -i "s|^DN_PATCH=.*$$|DN_PATCH=$(1)|g"  Makefile \
            && sed -i "s|^USE_GPU=.*$$|USE_GPU=1|g" Makefile \
            && cat "$(1)/Makefile.$(3)" | grep ^include | awk '{print $$2; }' | while read a ; do cp "$(1)/$$a" .; done \
            && $(MAKE) get-sources && $(MAKE) $(4) \
            $(NULL)

ffmpeg:
	$(call compile,$(DN_PWD),$(DN_SRC),$@,all)

gnuplot:
	$(call compile,$(DN_PWD),$(DN_SRC),$@,all)

ns2:
	$(call compile,$(DN_PWD),$(DN_SRC),$@,all)
