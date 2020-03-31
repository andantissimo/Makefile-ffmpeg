## ffmpeg

FFMPEG_VERSION   = 4.2.2-rav1e
AOM_VERSION      = 1.0.0-errata1
DAV1D_VERSION    = 0.6.0
FDK_AAC_VERSION  = 2.0.1
FREETYPE_VERSION = 2.10.1
OPUS_VERSION     = 1.3.1
RAV1E_VERSION    = 0.3.1
RTMPDUMP_VERSION = 20150114
VMAF_VERSION     = 1.5.1
VPX_VERSION      = 1.8.2
X264_VERSION     = stable
X265_VERSION     = 3.3
XML2_VERSION     = 2.9.10
OPENSSL_VERSION  = 1.1.1c
OPENSSL_ARCH     = linux-generic64
ifeq ($(shell uname),Darwin)
	OPENSSL_ARCH = darwin64-x86_64-cc
endif
ifeq ($(shell uname),FreeBSD)
	OPENSSL_ARCH = BSD-x86_64
endif
ifeq ($(shell uname),Linux)
	FFMPEG_OPTIONS += --extra-libs='-ldl -lpthread'
endif

all: bin/ffmpeg

clean:
	$(RM) -r include lib sbin tmp
	(cd share && $(RM) -r aclocal doc ffmpeg/examples ffmpeg/ffprobe.xsd)
	(cd share/man && $(RM) -r man3 man5 man7 man8)
	find bin -type f -not -name ffmpeg -delete
	find share/man/man1 -not -type d -not -name 'ffmpeg*' -delete

bin/ffmpeg: lib/libaom.a \
            lib/libdav1d.a \
            lib/libfdk-aac.a \
            lib/libfreetype.a \
            lib/libopus.a \
            lib/librav1e.a \
            lib/librtmp.a \
            lib/libvmaf.a \
            lib/libvpx.a \
            lib/libx264.a \
            lib/libx265.a \
            lib/libxml2.a \
            lib/libssl.a
	mkdir -p tmp/ffmpeg
	cd tmp/ffmpeg && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	export CFLAGS=-I$(PWD)/include && \
	export LDFLAGS=-L$(PWD)/lib && \
	$(PWD)/src/ffmpeg-$(FFMPEG_VERSION)/configure --prefix=$(PWD) \
		--enable-gpl --enable-version3 --enable-nonfree \
		--enable-static --disable-shared --enable-runtime-cpudetect \
		--disable-ffplay --disable-ffprobe \
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
		$(FFMPEG_OPTIONS) && \
	$(MAKE) install clean

lib/libaom.a:
	mkdir -p tmp/libaom
	cd tmp/libaom && \
	cmake $(PWD)/src/libaom-$(AOM_VERSION) -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DINCLUDE_INSTALL_DIR=$(PWD)/include -DLIB_INSTALL_DIR=$(PWD)/lib \
		-DENABLE_DOCS=OFF -DENABLE_EXAMPLES=OFF -DENABLE_TESTS=OFF && \
	$(MAKE) install clean

lib/libdav1d.a:
	cd src/dav1d-$(DAV1D_VERSION) && \
	meson --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype release --default-library static build && \
	ninja install -C build

lib/libfdk-aac.a:
	cd src/fdk-aac-$(FDK_AAC_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean

lib/libfreetype.a:
	cd src/freetype-$(FREETYPE_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--without-zlib --without-bzip2 --without-png --without-harfbuzz && \
	$(MAKE) install clean

lib/libopus.a:
	cd src/opus-$(OPUS_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-dependency-tracking \
		--disable-doc --disable-extra-programs && \
	$(MAKE) install clean
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
		install && \
	$(MAKE) clean

lib/libvmaf.a:
	cd src/vmaf-$(VMAF_VERSION)/libvmaf && \
	meson --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype release --default-library static build && \
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
	sed -e 's@^\(Libs:.*\)$$@\1 -lc++ -lm -lpthread@' \
	    -i'.bak' lib/pkgconfig/libvmaf.pc
endif

lib/libvpx.a:
	cd src/libvpx-$(VPX_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-dependency-tracking \
		--disable-examples --disable-docs \
		--enable-runtime-cpu-detect && \
	$(MAKE) install clean
	sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	    -i'.bak' lib/pkgconfig/vpx.pc

lib/libx264.a:
	cd src/x264-$(X264_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--enable-strip --enable-pic --disable-cli && \
	$(MAKE) install clean

lib/libx265.a:
	cd src/x265_$(X265_VERSION) && \
	cmake source -DCMAKE_INSTALL_PREFIX=$(PWD) -DCMAKE_BUILD_TYPE=Release \
		-DENABLE_SHARED=OFF -DENABLE_CLI=OFF && \
	$(MAKE) install clean
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
	$(MAKE) install clean

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
	$(MAKE) && \
	$(MAKE) install MANDIR=$(PWD)/share/man && \
	$(MAKE) clean
