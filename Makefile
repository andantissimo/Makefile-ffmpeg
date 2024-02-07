## ffmpeg

FFMPEG_VERSION      = 6.1.1
AOM_VERSION         = 3.8.1
ASS_VERSION         = 0.17.1
DAV1D_VERSION       = 1.3.0
FDK_AAC_VERSION     = 2.0.3
FONTCONFIG_VERSION  = 2.15.0
FREETYPE_VERSION    = 2.13.2
FRIBIDI_VERSION     = 1.0.13
HARFBUZZ_VERSION    = 8.3.0
KVAZAAR_VERSION     = 2.3.0
OPENSSL_VERSION     = 3.1.4
OPUS_VERSION        = 1.4
RAV1E_VERSION       = 0.7.1
RTMPDUMP_VERSION    = 20150114
SOXR_VERSION        = 0.1.3
SVT_AV1_VERSION     = 1.8.0
UTIL_LINUX_VERSION  = 2.39.3
VMAF_VERSION        = 3.0.0
VPX_VERSION         = 1.13.1
X264_VERSION        = 31e19f92
X265_VERSION        = ce8642f22123
XML2_VERSION        = 2.12.4
ZIMG_VERSION        = 3.0.5

OS   := $(shell uname -s)
ARCH := $(shell uname -m)

ifeq ($(OS),Darwin)
	ASS_OPTS        = --disable-fontconfig
	HARFBUZZ_OPTS   = -Dcoretext=enabled
	MAKE_ARGS      += -j$(shell sysctl -n hw.ncpu)
ifeq ($(ARCH),arm64)
	OPENSSL_ARCH    = darwin64-arm64-cc
	SOXR_OPTS       = -DWITH_CR32S=OFF -DWITH_CR64S=OFF
	VPX_OPTS        = --disable-runtime-cpu-detect
else
	OPENSSL_ARCH    = darwin64-x86_64-cc
	VPX_OPTS        = --enable-runtime-cpu-detect
endif
else
	ASS_DEPS        = lib/libfontconfig.a
	ASS_LIBS        = -lfontconfig -luuid
	VPX_OPTS        = --enable-runtime-cpu-detect
endif
ifeq ($(OS),FreeBSD)
	FFMPEG_LIBS    += -lm -lomp
	FFMPEG_OPTS    += --extra-libs='$(FFMPEG_LIBS)'
	FONTCONFIG_PATH = /usr/local/etc/fonts
	OPENSSL_ARCH    = BSD-x86_64
	MAKE_ARGS      += -j$(shell sysctl -n hw.ncpu)
else
	FONTCONFIG_PATH = /etc/fonts
endif
ifeq ($(OS),Linux)
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
	$(RM) -r build include lib lib64 libdata sbin
	cd share && $(RM) -r aclocal doc ffmpeg/examples locale
	cd share/man && $(RM) -r man3 man5 man8
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
	mkdir -p build/ffmpeg && cd build/ffmpeg && \
	export CFLAGS=-I$(PWD)/include && \
	export LDFLAGS=-L$(PWD)/lib && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	$(PWD)/src/ffmpeg-$(FFMPEG_VERSION)/configure \
		--prefix=$(PWD) \
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
	mkdir -p build/aom && cd build/aom && \
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
	mkdir -p build/libass && cd build/libass && \
	export CFLAGS=-I$(PWD)/include && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	$(PWD)/src/libass-$(ASS_VERSION)/configure \
		--prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared $(ASS_OPTS) && \
	sed -e 's@#define CONFIG_ICONV 1@/* #undef CONFIG_ICONV */@' \
	    -i'.bak' config.h && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	sed -e 's@^\(Libs:.*\)$$@\1 -lfreetype -lfribidi -lharfbuzz $(ASS_LIBS)@' \
	    -i'.bak' lib/pkgconfig/libass.pc

lib/libdav1d.a:
	mkdir -p build/dav1d && cd build/dav1d && \
	meson setup --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype release --default-library static \
		-Denable_tools=false -Denable_examples=false -Denable_tests=false \
		-Denable_docs=false -Dxxhash_muxer=disabled \
		. $(PWD)/src/dav1d-$(DAV1D_VERSION) && \
	ninja install
ifeq ($(OS),FreeBSD)
	mkdir -p lib/pkgconfig
	cat libdata/pkgconfig/dav1d.pc | sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	  > lib/pkgconfig/dav1d.pc
endif

lib/libfdk-aac.a:
	mkdir -p build/fdk-aac && cd build/fdk-aac && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_PROGRAMS=OFF -DBUILD_SHARED_LIBS=OFF \
		-DFDK_AAC_INSTALL_CMAKE_CONFIG_MODULE=OFF \
		$(PWD)/src/fdk-aac-$(FDK_AAC_VERSION) && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	if [ -f lib64/libfdk-aac.a ]; then \
		mkdir -p lib/pkgconfig; \
		install -m 644 lib64/libfdk-aac.a lib/libfdk-aac.a; \
		cat lib64/pkgconfig/fdk-aac.pc | sed -e 's/lib64/lib/g' \
		  > lib/pkgconfig/fdk-aac.pc; \
	fi

lib/libfreetype.a: lib/libxml2.a
	mkdir -p build/freetype && cd build/freetype && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_SHARED_LIBS=OFF \
		-DFT_DISABLE_BROTLI=ON \
		-DFT_DISABLE_BZIP2=ON \
		-DFT_DISABLE_HARFBUZZ=ON \
		-DFT_DISABLE_PNG=ON \
		-DFT_DISABLE_ZLIB=ON \
		$(PWD)/src/freetype-$(FREETYPE_VERSION) && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	if [ -f lib64/libfreetype.a ]; then \
		mkdir -p lib/pkgconfig; \
		install -m 644 lib64/libfreetype.a lib/libfreetype.a; \
		cat lib64/pkgconfig/freetype2.pc | sed -e 's/lib64/lib/g' \
		  > lib/pkgconfig/freetype2.pc; \
	fi

lib/libfontconfig.a: lib/libfreetype.a lib/libuuid.a lib/libxml2.a
	mkdir -p build/fontconfig && cd build/fontconfig && \
	export CFLAGS=-I$(PWD)/include && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	$(PWD)/src/fontconfig-$(FONTCONFIG_VERSION)/configure \
		--prefix=$(PWD) --with-baseconfigdir=$(FONTCONFIG_PATH) \
		--disable-dependency-tracking --enable-static --disable-shared \
		--disable-docs --enable-libxml2 && \
	$(MAKE) -C fontconfig install && \
	$(MAKE) -C src $(MAKE_ARGS) && $(MAKE) -C src install && \
	$(MAKE) install-pkgconfigDATA

lib/libfribidi.a:
	mkdir -p build/fribidi && cd build/fribidi && \
	meson setup --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype release --default-library static \
		-Ddeprecated=false -Ddocs=false -Dbin=false -Dtests=false \
		. $(PWD)/src/fribidi-$(FRIBIDI_VERSION) && \
	ninja install
ifeq ($(OS),FreeBSD)
	mkdir -p lib/pkgconfig
	cat libdata/pkgconfig/fribidi.pc \
	  > lib/pkgconfig/fribidi.pc
endif

lib/libkvazaar.a:
	mkdir -p include lib/pkgconfig
	cd src/kvazaar-$(KVAZAAR_VERSION) && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF \
		. && \
	$(MAKE) $(MAKE_ARGS) && \
	install -m 644 src/kvazaar.h $(PWD)/include/kvazaar.h && \
	install -m 644 src/kvazaar.pc $(PWD)/lib/pkgconfig/kvazaar.pc && \
	install -m 644 libkvazaar.a $(PWD)/lib/libkvazaar.a
ifeq ($(OS),FreeBSD)
	sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	    -i'.bak' lib/pkgconfig/kvazaar.pc
endif

lib/libharfbuzz.a: lib/libfreetype.a
	mkdir -p build/harfbuzz && cd build/harfbuzz && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	meson setup --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype release --default-library static \
		-Dcairo=disabled -Dchafa=disabled -Ddocs=disabled \
		-Dfreetype=enabled -Dglib=disabled -Dgobject=disabled \
		-Dicu=disabled -Dintrospection=disabled -Dtests=disabled \
		-Dutilities=disabled $(HARFBUZZ_OPTS) \
		. $(PWD)/src/harfbuzz-$(HARFBUZZ_VERSION) && \
	ninja install
ifeq ($(OS),FreeBSD)
	mkdir -p lib/pkgconfig
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
	mkdir -p build/soxr && cd build/soxr && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF $(SOXR_OPTS) \
		$(PWD)/src/soxr-$(SOXR_VERSION)-Source && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libssl.a:
	mkdir -p build/openssl && cd build/openssl && \
	perl $(PWD)/src/openssl-$(OPENSSL_VERSION)/Configure \
		--prefix=$(PWD) --openssldir=$(OPENSSL_DIR) \
		no-shared \
		no-comp \
		no-ssl3 \
		no-zlib \
		enable-cms \
		$(OPENSSL_ARCH) && \
	$(MAKE) depend && \
	$(MAKE) $(MAKE_ARGS) && \
	$(MAKE) install_dev

lib/libSvtAv1Enc.a:
	mkdir -p build/SVT-AV1 && cd build/SVT-AV1 && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_APPS=OFF -DBUILD_DEC=OFF -DBUILD_SHARED_LIBS=OFF \
		$(PWD)/src/SVT-AV1-v$(SVT_AV1_VERSION) && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	if [ -f lib64/libSvtAv1Enc.a ]; then \
		mkdir -p lib/pkgconfig; \
		install -m 644 lib64/libSvtAv1Enc.a lib/libSvtAv1Enc.a; \
		cat lib64/pkgconfig/SvtAv1Enc.pc | sed -e 's/lib64/lib/g' \
		  > lib/pkgconfig/SvtAv1Enc.pc; \
	fi
ifeq ($(OS),FreeBSD)
	sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	    -i'.bak' lib/pkgconfig/SvtAv1Enc.pc
endif

lib/libuuid.a:
	mkdir -p build/util-linux && cd build/util-linux && \
	$(PWD)/src/util-linux-$(UTIL_LINUX_VERSION)/configure \
		--prefix=$(PWD) --disable-dependency-tracking \
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
ifeq ($(OS),FreeBSD)
	sed -e 's@_POSIX_C_SOURCE=200112L@_XOPEN_SOURCE=600@' \
	    -i'.bak' src/vmaf-$(VMAF_VERSION)/libvmaf/meson.build
endif
	mkdir -p build/vmaf && cd build/vmaf && \
	meson setup --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype=release --default-library=static \
		-Denable_tests=false -Denable_docs=false \
		. $(PWD)/src/vmaf-$(VMAF_VERSION)/libvmaf && \
	ninja install
	$(RM) lib/libvmaf.*dylib
	$(RM) lib/libvmaf.so*
ifeq ($(OS),Darwin)
	sed -e 's@^\(Libs:.*\)$$@\1 -lc++ -lc++abi@' \
	    -i'.bak' lib/pkgconfig/libvmaf.pc
endif
ifeq ($(OS),Linux)
	sed -e 's@^\(Libs:.*\)$$@\1 -lstdc++ -lm@' \
	    -i'.bak' lib/pkgconfig/libvmaf.pc
endif
ifeq ($(OS),FreeBSD)
	mkdir -p lib/pkgconfig
	cat libdata/pkgconfig/libvmaf.pc | \
	sed -e 's@^\(Libs:.*\)$$@\1 -lc++ -lm -lpthread@' \
	  > lib/pkgconfig/libvmaf.pc
endif

lib/libvpx.a:
ifeq ($(OS),FreeBSD)
	sed -e 's@diff --version@hash diff@' \
	    -i'.bak' src/libvpx-$(VPX_VERSION)/configure
endif
	mkdir -p build/libvpx && cd build/libvpx && \
	$(PWD)/src/libvpx-$(VPX_VERSION)/configure \
		--prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared \
		--disable-examples --disable-docs --disable-unit-tests \
		--disable-decode-perf-tests --disable-encode-perf-tests \
		--enable-vp9-highbitdepth $(VPX_OPTS) && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	    -i'.bak' lib/pkgconfig/vpx.pc

lib/libx264.a:
	mkdir -p build/x264 && cd build/x264 && \
	$(PWD)/src/x264-$(X264_VERSION)/configure \
		--prefix=$(PWD) --enable-static --disable-shared \
		--enable-strip --enable-pic --disable-cli && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install

lib/libx265_main10.a:
	mkdir -p lib build/x265/main10 && cd build/x265/main10 && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DENABLE_CLI=OFF -DENABLE_SHARED=OFF -DEXPORT_C_API=OFF \
		-DHIGH_BIT_DEPTH=ON -DENABLE_HDR10_PLUS=ON \
		$(PWD)/src/multicoreware-x265_git-$(X265_VERSION)/source && \
	$(MAKE) $(MAKE_ARGS) && \
	install -m 644 libx265.a $(PWD)/lib/libx265_main10.a

lib/libx265_main12.a:
	mkdir -p lib build/x265/main12 && cd build/x265/main12 && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DENABLE_CLI=OFF -DENABLE_SHARED=OFF -DEXPORT_C_API=OFF \
		-DHIGH_BIT_DEPTH=ON -DMAIN12=ON \
		$(PWD)/src/multicoreware-x265_git-$(X265_VERSION)/source && \
	$(MAKE) $(MAKE_ARGS) && \
	install -m 644 libx265.a $(PWD)/lib/libx265_main12.a

lib/libx265_main.a: lib/libx265_main10.a lib/libx265_main12.a
	mkdir -p lib build/x265/main && cd build/x265/main && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DENABLE_CLI=OFF -DENABLE_SHARED=OFF \
		-DEXTRA_LIB="x265_main10.a;x265_main12.a" \
		-DEXTRA_LINK_FLAGS="-L$(PWD)/lib" \
		-DLINKED_10BIT=ON -DLINKED_12BIT=ON \
		$(PWD)/src/multicoreware-x265_git-$(X265_VERSION)/source && \
	$(MAKE) $(MAKE_ARGS) && \
	install -m 644 libx265.a $(PWD)/lib/libx265_main.a

build/x265.ar: lib/libx265_main.a lib/libx265_main10.a lib/libx265_main12.a
	echo CREATE lib/libx265.a > $@
	echo ADDLIB lib/libx265_main.a >> $@
	echo ADDLIB lib/libx265_main10.a >> $@
	echo ADDLIB lib/libx265_main12.a >> $@
	echo SAVE >> $@
	echo END >> $@

lib/libx265.a: build/x265.ar
	mkdir -p include lib/pkgconfig
	install -m 644 src/multicoreware-x265_git-$(X265_VERSION)/source/x265.h include/x265.h
	install -m 644 build/x265/main/x265_config.h include/x265_config.h
ifeq ($(OS),Darwin)
	libtool -static -o lib/libx265.a \
		lib/libx265_main.a lib/libx265_main10.a lib/libx265_main12.a
else
	ar -M < build/x265.ar
	ranlib lib/libx265.a
endif
ifeq ($(OS),Linux)
	cat build/x265/main/x265.pc | \
	sed -e 's@^\(Libs:.*\)$$@\1 -lstdc++ -lm -ldl -lpthread@' \
	  > lib/pkgconfig/x265.pc
else
	cat build/x265/main/x265.pc | \
	sed -e 's@^\(Libs:.*\)$$@\1 -lc++ -lm -ldl -lpthread@' \
	  > lib/pkgconfig/x265.pc
endif

lib/libxml2.a:
	mkdir -p build/libxml2 && cd build/libxml2 && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_SHARED_LIBS=OFF \
		-DLIBXML2_WITH_C14N=OFF \
		-DLIBXML2_WITH_CATALOG=OFF \
		-DLIBXML2_WITH_DEBUG=OFF \
		-DLIBXML2_WITH_HTML=OFF \
		-DLIBXML2_WITH_HTTP=OFF \
		-DLIBXML2_WITH_ICONV=OFF \
		-DLIBXML2_WITH_ISO8859X=OFF \
		-DLIBXML2_WITH_LZMA=OFF \
		-DLIBXML2_WITH_MODULES=OFF \
		-DLIBXML2_WITH_OUTPUT=OFF \
		-DLIBXML2_WITH_PATTERN=OFF \
		-DLIBXML2_WITH_PROGRAMS=OFF \
		-DLIBXML2_WITH_PYTHON=OFF \
		-DLIBXML2_WITH_READER=OFF \
		-DLIBXML2_WITH_REGEXPS=OFF \
		-DLIBXML2_WITH_SCHEMAS=OFF \
		-DLIBXML2_WITH_SCHEMATRON=OFF \
		-DLIBXML2_WITH_TESTS=OFF \
		-DLIBXML2_WITH_THREADS=OFF \
		-DLIBXML2_WITH_VALID=OFF \
		-DLIBXML2_WITH_WRITER=OFF \
		-DLIBXML2_WITH_XINCLUDE=OFF \
		-DLIBXML2_WITH_XPATH=OFF \
		-DLIBXML2_WITH_XPTR=OFF \
		-DLIBXML2_WITH_ZLIB=OFF \
		$(PWD)/src/libxml2-$(XML2_VERSION) && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	if [ -f lib64/libxml2.a ]; then \
		mkdir -p lib/pkgconfig; \
		install -m 644 lib64/libxml2.a lib/libxml2.a; \
		cat lib64/pkgconfig/libxml-2.0.pc | sed -e 's/lib64/lib/g' \
		  > lib/pkgconfig/libxml-2.0.pc; \
	fi

lib/libzimg.a:
	cd src/zimg-release-$(ZIMG_VERSION) && \
	./autogen.sh && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared && \
	$(MAKE) $(MAKE_ARGS) && $(MAKE) install
	sed -e 's@^\(Libs:.*\)$$@\1 -lstdc++ -lm@' \
	    -i'.bak' lib/pkgconfig/zimg.pc
