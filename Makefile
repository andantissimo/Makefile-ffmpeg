## ffmpeg

FFMPEG_VERSION   = 4.4.1
AOM_VERSION      = 3.1.2
DAV1D_VERSION    = 0.9.2
FDK_AAC_VERSION  = 2.0.2
FREETYPE_VERSION = 2.11.0
OPUS_VERSION     = 1.3.1
OPENSSL_VERSION  = 1.1.1l
RAV1E_VERSION    = 0.4.1
RTMPDUMP_VERSION = 20150114
VMAF_VERSION     = 2.3.0
VPX_VERSION      = 1.11.0
X264_VERSION     = 5db6aa6c
X265_VERSION     = 3.4
XML2_VERSION     = 2.9.12
ifeq ($(shell uname),Darwin)
	OPENSSL_ARCH = darwin64-x86_64-cc
	MAKE_ARGS   += -j$(shell sysctl -n hw.ncpu)
endif
ifeq ($(shell uname),FreeBSD)
	OPENSSL_ARCH = BSD-x86_64
	MAKE_ARGS   += -j$(shell sysctl -n hw.ncpu)
endif
ifeq ($(shell uname),Linux)
	FFMPEG_OPTS += --extra-libs='-ldl -lpthread'
	OPENSSL_ARCH = linux-generic64
	MAKE_ARGS   += -j$(shell nproc)
endif

all: bin/ffmpeg

clean:
	$(RM) -r include lib lib64 libdata sbin tmp
	cd share && $(RM) -r aclocal doc gtk-doc
	cd share/ffmpeg && $(RM) -r examples
	cd share/man && $(RM) -r man3 man5 man7 man8
	find bin -type f -not -name 'ff*' -delete
	find share/man/man1 -not -type d -not -name 'ff*' -delete

bin/ffmpeg: lib/libaom.a \
            lib/libdav1d.a \
            lib/libfdk-aac.a \
            lib/libfreetype.a \
            lib/libopus.a \
            lib/librav1e.a \
            lib/librtmp.a \
            lib/libssl.a \
            lib/libvmaf.a \
            lib/libvpx.a \
            lib/libx264.a \
            lib/libx265.a \
            lib/libxml2.a
	cd src/ffmpeg-$(FFMPEG_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	export CFLAGS=-I$(PWD)/include && \
	export LDFLAGS=-L$(PWD)/lib && \
	./configure --prefix=$(PWD) \
		--enable-gpl --enable-version3 --enable-nonfree \
		--enable-static --disable-shared --enable-runtime-cpudetect \
		--disable-ffplay \
		--disable-alsa \
		--disable-bzlib \
		--disable-iconv \
		--enable-libaom \
		--enable-libdav1d \
		--enable-libfdk-aac \
		--enable-libfreetype \
		--enable-libopus \
		--enable-librav1e \
		--enable-librtmp \
		--enable-libvmaf \
		--enable-libvpx \
		--enable-libx264 \
		--enable-libx265 \
		--disable-libxcb \
		--enable-libxml2 \
		--disable-lzma \
		--enable-openssl \
		--disable-sndio \
		--disable-sdl2 \
		--disable-xlib \
		--enable-zlib \
		--disable-v4l2-m2m \
		$(FFMPEG_OPTS) && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libaom.a:
	mkdir -p tmp/libaom && cd tmp/libaom && \
	cmake -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DENABLE_DOCS=OFF -DENABLE_EXAMPLES=OFF \
		-DENABLE_TESTDATA=OFF -DENABLE_TESTS=OFF -DENABLE_TOOLS=OFF \
		$(PWD)/src/aom-$(AOM_VERSION) && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	if [ -f $(PWD)/lib64/libaom.a ]; then \
		install -m 644 $(PWD)/lib64/libaom.a $(PWD)/lib/libaom.a; \
		cat $(PWD)/lib64/pkgconfig/aom.pc | \
		sed -e 's/lib64/lib/g' \
		  > $(PWD)/lib/pkgconfig/aom.pc; \
	fi

lib/libdav1d.a:
	cd src/dav1d-$(DAV1D_VERSION) && \
	meson --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype release --default-library static build && \
	ninja install -C build
ifeq ($(shell uname),FreeBSD)
	cat $(PWD)/libdata/pkgconfig/dav1d.pc | \
	sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	  > $(PWD)/lib/pkgconfig/dav1d.pc
endif

lib/libfdk-aac.a:
	cd src/fdk-aac-$(FDK_AAC_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libfreetype.a:
	cd src/freetype-$(FREETYPE_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--without-zlib --without-bzip2 --without-png --without-harfbuzz \
		--without-brotli && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libopus.a:
	cd src/opus-$(OPUS_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-dependency-tracking \
		--disable-doc --disable-extra-programs && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	sed -e 's@^\(Libs:.*\)$$@\1 -lm@' \
	    -i'.bak' lib/pkgconfig/opus.pc

lib/librav1e.a:
	cd src/rav1e-$(RAV1E_VERSION) && \
	cargo cinstall --prefix $(PWD) --pkgconfigdir $(PWD)/lib/pkgconfig --release
	sed -e 's@^\(Libs:.*\)$$@\1 -lm -lpthread@' \
	    -i'.bak' lib/pkgconfig/rav1e.pc
	$(RM) lib/librav1e.*dylib
	$(RM) lib/librav1e.so*

lib/librtmp.a:
	cd src/rtmpdump-$(RTMPDUMP_VERSION) && \
	$(MAKE) prefix=$(PWD) MANDIR=$(PWD)/share/man \
		CRYPTO= \
		SHARED= \
		install

lib/libssl.a:
	cd src/openssl-$(OPENSSL_VERSION) && \
	perl ./Configure --prefix=$(PWD) --openssldir=$(PWD)/etc/ssl \
		no-shared \
		no-comp \
		no-ssl2 \
		no-ssl3 \
		no-zlib \
		enable-cms \
		$(OPENSSL_ARCH) && \
	$(MAKE) depend && \
	$(MAKE) $(MAKE_ARGS) && \
	$(MAKE) install MANDIR=$(PWD)/share/man

lib/libvmaf.a:
ifeq ($(shell uname),FreeBSD)
	sed -e 's@^\(#elif MACOS\)$$@\1 || __FreeBSD__@' \
	    -e 's@HW_AVAILCPU@HW_NCPU@' \
	    -i'.bak' src/vmaf-$(VMAF_VERSION)/libvmaf/src/cpu_info.c
	sed -e 's@_POSIX_C_SOURCE=200112L@_XOPEN_SOURCE=600@' \
	    -i'.bak' src/vmaf-$(VMAF_VERSION)/libvmaf/meson.build
endif
	cd src/vmaf-$(VMAF_VERSION)/libvmaf && \
	meson --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype=release --default-library=static build && \
	ninja install -C build
	$(RM) lib/libvmaf.*dylib
	$(RM) lib/libvmaf.so*
ifeq ($(shell uname),Darwin)
	sed -e 's@^\(Libs:.*\)$$@\1 -lc++ -lc++abi@' \
	    -i'.bak' lib/pkgconfig/libvmaf.pc
endif
ifeq ($(shell uname),Linux)
	sed -e 's@^\(Libs:.*\)$$@\1 -lstdc++ -lm@' \
	    -i'.bak' lib/pkgconfig/libvmaf.pc
endif
ifeq ($(shell uname),FreeBSD)
	cat $(PWD)/libdata/pkgconfig/libvmaf.pc | \
	sed -e 's@^\(Libs:.*\)$$@\1 -lc++ -lm -lpthread@' \
	  > $(PWD)/lib/pkgconfig/libvmaf.pc
endif

lib/libvpx.a:
ifeq ($(shell uname),FreeBSD)
	sed -e 's@diff --version@hash diff@' \
	    -i'.bak' src/libvpx-$(VPX_VERSION)/configure
endif
	cd src/libvpx-$(VPX_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-dependency-tracking \
		--disable-examples --disable-docs \
		--enable-runtime-cpu-detect && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	    -i'.bak' lib/pkgconfig/vpx.pc

lib/libx264.a:
	cd src/x264-$(X264_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--enable-strip --enable-pic --disable-cli && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libx265.a:
	cd src/x265_$(X265_VERSION) && \
	cmake -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DENABLE_CLI=OFF -DENABLE_SHARED=OFF \
		source && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	sed -e 's@^\(Libs:.*\)$$@\1 -lstdc++ -lm -ldl -lpthread@' \
	    -i'.bak' lib/pkgconfig/x265.pc

lib/libxml2.a:
	cd src/libxml2-$(XML2_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared --with-tree \
		--without-c14n --without-catalog --without-debug --without-docbook \
		--without-fexceptions --without-ftp --without-history --without-html \
		--without-http --without-iconv --without-icu --without-iso8859x \
		--without-legacy --without-mem-debug --with-minimum --without-output \
		--without-pattern --without-push --without-python --without-reader \
		--without-readline --without-regexps --without-run-debug \
		--without-sax1 --without-schemas --without-schematron \
		--without-threads --without-valid --without-writer --without-xinclude \
		--without-xpath --without-xptr --without-modules --without-zlib \
		--without-lzma --without-coverage && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
