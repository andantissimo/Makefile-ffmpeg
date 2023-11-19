## ffmpeg

FFMPEG_VERSION      = 6.1
AOM_VERSION         = 3.7.0
ASS_VERSION         = 0.17.1
DAV1D_VERSION       = 1.3.0
FDK_AAC_VERSION     = 2.0.2
FONTCONFIG_VERSION  = 2.14.2
FREETYPE_VERSION    = 2.13.2
FRIBIDI_VERSION     = 1.0.13
HARFBUZZ_VERSION    = 8.3.0
KVAZAAR_VERSION     = 2.2.0
OPENSSL_VERSION     = 3.1.4
OPUS_VERSION        = 1.4
RAV1E_VERSION       = 0.6.6
RTMPDUMP_VERSION    = 20150114
SOXR_VERSION        = 0.1.3
SVT_AV1_VERSION     = 1.7.0
UTIL_LINUX_VERSION  = 2.39.2
VMAF_VERSION        = 2.3.1
VPX_VERSION         = 1.13.1
X264_VERSION        = 31e19f92
X265_VERSION        = f0c1022b6be1
XML2_VERSION        = 2.11.5
ZIMG_VERSION        = 3.0.5
ifeq ($(shell uname),Darwin)
	ASS_OPTS        = --disable-fontconfig
	HARFBUZZ_OPTS   = -Dcoretext=enabled
	OPENSSL_ARCH    = darwin64-x86_64-cc
	MAKE_ARGS      += -j$(shell sysctl -n hw.ncpu)
else
	ASS_DEPS        = lib/libfontconfig.a
	ASS_LIBS        = -lfontconfig -luuid
endif
ifeq ($(shell uname),FreeBSD)
	FFMPEG_LIBS    += -lm -lomp
	FFMPEG_OPTS    += --extra-libs='$(FFMPEG_LIBS)'
	FONTCONFIG_PATH = /usr/local/etc/fonts
	OPENSSL_ARCH    = BSD-x86_64
	MAKE_ARGS      += -j$(shell sysctl -n hw.ncpu)
else
	FONTCONFIG_PATH = /etc/fonts
endif
ifeq ($(shell uname),Linux)
	FFMPEG_LIBS    += -ldl -lgomp -lm -lpthread
	FFMPEG_OPTS    += --extra-libs='$(FFMPEG_LIBS)'
	OPENSSL_ARCH    = linux-generic64
	MAKE_ARGS      += -j$(shell nproc)
endif
ifneq ($(wildcard /etc/redhat-release),)
	OPENSSL_DIR    ?= /etc/pki/tls
else
	OPENSSL_DIR    ?= /etc/ssl
endif

all: bin/ffmpeg

clean:
	$(RM) -r etc include lib lib64 libdata sbin tmp
	cd share && $(RM) -r aclocal bash-completion doc gtk-doc locale
	cd share/ffmpeg && $(RM) -r examples
	cd share/man && $(RM) -r man3 man5 man7 man8
	find bin -type f -not -name 'ff*' -delete
	find share/man/man1 -not -type d -not -name 'ff*' -delete

bin/ffmpeg: lib/libaom.a \
            lib/libass.a \
            lib/libdav1d.a \
            lib/libfdk-aac.a \
            lib/libfreetype.a \
            lib/libfribidi.a \
            lib/libkvazaar.a \
            lib/libopus.a \
            lib/librav1e.a \
            lib/librtmp.a \
            lib/libsoxr.a \
            lib/libssl.a \
            lib/libSvtAv1Enc.a \
            lib/libvmaf.a \
            lib/libvpx.a \
            lib/libx264.a \
            lib/libx265.a \
            lib/libxml2.a \
            lib/libzimg.a
	cd src/ffmpeg-$(FFMPEG_VERSION) && \
	export CFLAGS=-I$(PWD)/include && \
	export LDFLAGS=-L$(PWD)/lib && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	./configure --prefix=$(PWD) \
		--enable-gpl --enable-version3 --enable-nonfree \
		--enable-static --disable-shared --enable-runtime-cpudetect \
		--disable-ffplay \
		--disable-alsa \
		--disable-bzlib \
		--disable-iconv \
		--enable-libaom \
		--enable-libass \
		--enable-libdav1d \
		--enable-libfdk-aac \
		--enable-libfreetype \
		--enable-libfribidi \
		--enable-libkvazaar \
		--enable-libopus \
		--enable-librav1e \
		--enable-librtmp \
		--enable-libsoxr \
		--enable-libsvtav1 \
		--enable-libvmaf \
		--enable-libvpx \
		--enable-libx264 \
		--enable-libx265 \
		--disable-libxcb \
		--enable-libxml2 \
		--enable-libzimg \
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
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DENABLE_DOCS=OFF -DENABLE_EXAMPLES=OFF \
		-DENABLE_TESTDATA=OFF -DENABLE_TESTS=OFF -DENABLE_TOOLS=OFF \
		$(PWD)/src/aom-$(AOM_VERSION) && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	if [ -f lib64/libaom.a ]; then \
		mkdir -p lib/pkgconfig; \
		install -m 644 lib64/libaom.a lib/libaom.a; \
		cat lib64/pkgconfig/aom.pc | sed -e 's/lib64/lib/g' \
		  > lib/pkgconfig/aom.pc; \
	fi

lib/libass.a: lib/libfribidi.a lib/libharfbuzz.a $(ASS_DEPS)
	cd src/libass-$(ASS_VERSION) && \
	export CFLAGS=-I$(PWD)/include && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared $(ASS_OPTS) && \
	sed -e 's@#define CONFIG_ICONV 1@/* #undef CONFIG_ICONV */@' \
	    -i'.bak' config.h && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	sed -e 's@^\(Libs:.*\)$$@\1 -lfreetype -lfribidi -lharfbuzz $(ASS_LIBS)@' \
	    -i'.bak' lib/pkgconfig/libass.pc

lib/libdav1d.a:
	cd src/dav1d-$(DAV1D_VERSION) && \
	meson --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype release --default-library static \
		-Denable_tools=false -Denable_examples=false -Denable_tests=false \
		build && \
	ninja install -C build
ifeq ($(shell uname),FreeBSD)
	cat libdata/pkgconfig/dav1d.pc | sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	  > lib/pkgconfig/dav1d.pc
endif

lib/libfdk-aac.a:
	cd src/fdk-aac-$(FDK_AAC_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libfreetype.a:
	cd src/freetype-$(FREETYPE_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--without-zlib --without-bzip2 --without-png --without-harfbuzz \
		--without-brotli && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libfontconfig.a: lib/libfreetype.a lib/libuuid.a lib/libxml2.a
	cd src/fontconfig-$(FONTCONFIG_VERSION) && \
	export CFLAGS=-I$(PWD)/include && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	./configure --prefix=$(PWD) --with-baseconfigdir=$(FONTCONFIG_PATH) \
		--disable-dependency-tracking --enable-static --disable-shared \
		--disable-docs --enable-libxml2 && \
	$(MAKE) -C fontconfig install && \
	$(MAKE) -C src $(MAKE_ARGS) && $(MAKE) -C src install
	cat src/fontconfig-$(FONTCONFIG_VERSION)/fontconfig.pc \
	  > lib/pkgconfig/fontconfig.pc

lib/libfribidi.a:
	cd src/fribidi-$(FRIBIDI_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libkvazaar.a:
	cd src/kvazaar-$(KVAZAAR_VERSION) && \
	./autogen.sh && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libharfbuzz.a: lib/libfreetype.a
	cd src/harfbuzz-$(HARFBUZZ_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	meson --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype release --default-library static \
		-Dcairo=disabled -Dchafa=disabled -Ddocs=disabled \
		-Dfreetype=enabled -Dglib=disabled -Dgobject=disabled \
		-Dicu=disabled -Dintrospection=disabled -Dtests=disabled \
		-Dutilities=disabled \
		$(HARFBUZZ_OPTS) build && \
	ninja install -C build
ifeq ($(shell uname),FreeBSD)
	cat libdata/pkgconfig/harfbuzz.pc \
	  > lib/pkgconfig/harfbuzz.pc
endif

lib/libopus.a:
	cd src/opus-$(OPUS_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared \
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
	cd src/rtmpdump-$(RTMPDUMP_VERSION)/librtmp && \
	$(MAKE) prefix=$(PWD) MANDIR=$(PWD)/share/man \
		CRYPTO= \
		SHARED= \
		install

lib/libsoxr.a:
	cd src/soxr-$(SOXR_VERSION)-Source && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libssl.a:
	cd src/openssl-$(OPENSSL_VERSION) && \
	perl ./Configure --prefix=$(PWD) --openssldir=$(OPENSSL_DIR) \
		no-shared \
		no-comp \
		no-ssl2 \
		no-ssl3 \
		no-zlib \
		enable-cms \
		$(OPENSSL_ARCH) && \
	$(MAKE) depend && \
	$(MAKE) $(MAKE_ARGS) && \
	$(MAKE) install_dev

lib/libSvtAv1Enc.a:
	cd src/SVT-AV1-v$(SVT_AV1_VERSION)/Build && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_APPS=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF \
		.. && \
	$(MAKE) $(MAKE_ARGS) && \
	$(MAKE) install
	if [ -f lib64/libSvtAv1Enc.a ]; then \
		mkdir -p lib/pkgconfig; \
		install -m 644 lib64/libSvtAv1Dec.a lib/libSvtAv1Dec.a; \
		install -m 644 lib64/libSvtAv1Enc.a lib/libSvtAv1Enc.a; \
		cat lib64/pkgconfig/SvtAv1Dec.pc | sed -e 's/lib64/lib/g' \
		  > lib/pkgconfig/SvtAv1Dec.pc; \
		cat lib64/pkgconfig/SvtAv1Enc.pc | sed -e 's/lib64/lib/g' \
		  > lib/pkgconfig/SvtAv1Enc.pc; \
	fi
ifeq ($(shell uname),FreeBSD)
	sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	    -i'.bak' lib/pkgconfig/SvtAv1Enc.pc
endif

lib/libuuid.a:
	cd src/util-linux-$(UTIL_LINUX_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared \
		--disable-all-programs --disable-asciidoc --disable-libblkid \
		--disable-libmount --disable-libsmartcols --disable-libfdisks \
		--disable-bash-completion --disable-use-tty-group \
		--disable-makeinstall-chown --disable-makeinstall-setuid \
		--without-util --without-udev --without-ncursesw --without-tinfo \
		--without-readline --without-cap-ng --without-libz --without-libmagic \
		--without-user --without-btrfs --without-systemd --without-econf \
		--without-python \
		--enable-libuuid && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libvmaf.a:
ifeq ($(shell uname),FreeBSD)
	sed -e 's@_POSIX_C_SOURCE=200112L@_XOPEN_SOURCE=600@' \
	    -i'.bak' src/vmaf-$(VMAF_VERSION)/libvmaf/meson.build
endif
	cd src/vmaf-$(VMAF_VERSION)/libvmaf && \
	meson --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype=release --default-library=static \
		-Denable_tests=false -Denable_docs=false \
		build && \
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
	cat libdata/pkgconfig/libvmaf.pc | \
	sed -e 's@^\(Libs:.*\)$$@\1 -lc++ -lm -lpthread@' \
	  > lib/pkgconfig/libvmaf.pc
endif

lib/libvpx.a:
ifeq ($(shell uname),FreeBSD)
	sed -e 's@diff --version@hash diff@' \
	    -i'.bak' src/libvpx-$(VPX_VERSION)/configure
endif
	cd src/libvpx-$(VPX_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared \
		--disable-examples --disable-docs --disable-unit-tests \
		--disable-decode-perf-tests --disable-encode-perf-tests \
		--enable-vp9-highbitdepth --enable-runtime-cpu-detect && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	    -i'.bak' lib/pkgconfig/vpx.pc

lib/libx264.a:
	cd src/x264-$(X264_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--enable-strip --enable-pic --disable-cli && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libx265_main10.a:
	mkdir -p lib tmp/x265/main10 && cd tmp/x265/main10 && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DENABLE_CLI=OFF -DENABLE_SHARED=OFF -DEXPORT_C_API=OFF \
		-DHIGH_BIT_DEPTH=ON -DENABLE_HDR10_PLUS=ON \
		$(PWD)/src/multicoreware-x265_git-$(X265_VERSION)/source && \
	$(MAKE) $(MAKE_ARGS) && \
	install -m 644 libx265.a $(PWD)/lib/libx265_main10.a

lib/libx265_main12.a:
	mkdir -p lib tmp/x265/main12 && cd tmp/x265/main12 && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DENABLE_CLI=OFF -DENABLE_SHARED=OFF -DEXPORT_C_API=OFF \
		-DHIGH_BIT_DEPTH=ON -DMAIN12=ON \
		$(PWD)/src/multicoreware-x265_git-$(X265_VERSION)/source && \
	$(MAKE) $(MAKE_ARGS) && \
	install -m 644 libx265.a $(PWD)/lib/libx265_main12.a

lib/libx265_main.a: lib/libx265_main10.a lib/libx265_main12.a
	mkdir -p lib tmp/x265/main && cd tmp/x265/main && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DENABLE_CLI=OFF -DENABLE_SHARED=OFF \
		-DEXTRA_LIB="x265_main10.a;x265_main12.a" \
		-DEXTRA_LINK_FLAGS="-L$(PWD)/lib" \
		-DLINKED_10BIT=ON -DLINKED_12BIT=ON \
		$(PWD)/src/multicoreware-x265_git-$(X265_VERSION)/source && \
	$(MAKE) $(MAKE_ARGS) && \
	install -m 644 libx265.a $(PWD)/lib/libx265_main.a

tmp/x265.ar: lib/libx265_main.a lib/libx265_main10.a lib/libx265_main12.a
	echo CREATE lib/libx265.a > $@
	echo ADDLIB lib/libx265_main.a >> $@
	echo ADDLIB lib/libx265_main10.a >> $@
	echo ADDLIB lib/libx265_main12.a >> $@
	echo SAVE >> $@
	echo END >> $@

lib/libx265.a: tmp/x265.ar
	mkdir -p include lib/pkgconfig
	install -m 644 src/multicoreware-x265_git-$(X265_VERSION)/source/x265.h include/x265.h
	install -m 644 tmp/x265/main/x265_config.h include/x265_config.h
ifeq ($(shell uname),Darwin)
	libtool -static -o lib/libx265.a \
		lib/libx265_main.a lib/libx265_main10.a lib/libx265_main12.a
else
	ar -M < tmp/x265.ar
	ranlib lib/libx265.a
endif
ifeq ($(shell uname),Linux)
	cat tmp/x265/main/x265.pc | \
	sed -e 's@^\(Libs:.*\)$$@\1 -lstdc++ -lm -ldl -lpthread@' \
	  > lib/pkgconfig/x265.pc
else
	cat tmp/x265/main/x265.pc | \
	sed -e 's@^\(Libs:.*\)$$@\1 -lc++ -lm -ldl -lpthread@' \
	  > lib/pkgconfig/x265.pc
endif

lib/libxml2.a:
	cd src/libxml2-$(XML2_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared \
		--without-c14n --without-catalog --without-debug \
		--without-fexceptions --without-ftp --without-history --without-html \
		--without-http --without-iconv --without-icu --without-iso8859x \
		--without-legacy --without-mem-debug --with-minimum --without-output \
		--without-pattern --with-push --without-python --without-reader \
		--without-readline --without-regexps --without-run-debug --with-sax1 \
		--without-schemas --without-schematron --without-threads --with-tree \
		--without-valid --without-writer --without-xinclude --without-xpath \
		--without-xptr --without-modules --without-zlib --without-lzma \
		--without-coverage && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libzimg.a:
	cd src/zimg-release-$(ZIMG_VERSION) && \
	./autogen.sh && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	sed -e 's@^\(Libs:.*\)$$@\1 -lstdc++ -lm@' \
	    -i'.bak' lib/pkgconfig/zimg.pc
