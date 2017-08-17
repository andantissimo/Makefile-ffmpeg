## ffmpeg

FFMPEG_VERSION   = 3.3.3
X264_VERSION     = snapshot-20170522-2245-stable
X265_VERSION     = 2.5
VPX_VERSION      = 1.6.1
OPUS_VERSION     = 1.2.1
LAME_VERSION     = 3.99.5
FREETYPE_VERSION = 2.8
RTMPDUMP_VERSION = 20150114

all: bin/ffmpeg

bin/ffmpeg: lib/libx264.a \
            lib/libx265.a \
            lib/libvpx.a \
            lib/libopus.a \
            lib/libmp3lame.a \
            lib/libfreetype.a \
            lib/librtmp.a
	cd src/ffmpeg-$(FFMPEG_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	export CFLAGS=-I$(PWD)/include && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-debug --disable-ffplay --disable-ffserver \
		--enable-runtime-cpudetect \
		--enable-gpl \
		--enable-libx264 \
		--enable-libx265 \
		--enable-libvpx \
		--enable-libopus \
		--enable-libmp3lame \
		--enable-libfreetype \
		--enable-librtmp \
		$(FFMPEG_OPTIONS) && \
	$(MAKE) install clean

lib/libx264.a:
	cd src/x264-$(X264_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--enable-strip --disable-cli && \
	$(MAKE) install clean

lib/libx265.a:
	cd src/x265_$(X265_VERSION) && \
	cmake source -DCMAKE_INSTALL_PREFIX=$(PWD) -DCMAKE_BUILD_TYPE=Release \
		-DENABLE_SHARED=OFF -DENABLE_CLI=OFF && \
	$(MAKE) install clean
	sed -e 's@^\(Libs:.*\)$$@\1 -lstdc++@' \
	    -i'.bak' lib/pkgconfig/x265.pc

lib/libvpx.a:
	cd src/libvpx-$(VPX_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-dependency-tracking \
		--disable-examples --disable-docs \
		--enable-runtime-cpu-detect && \
	$(MAKE) install clean

lib/libopus.a:
	cd src/opus-$(OPUS_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-dependency-tracking \
		--disable-doc --disable-extra-programs && \
	$(MAKE) install clean

lib/libmp3lame.a:
	cd src/lame-$(LAME_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-dependency-tracking \
		--enable-nasm --disable-frontend && \
	$(MAKE) install clean

lib/libfreetype.a:
	cd src/freetype-$(FREETYPE_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--without-png --without-harfbuzz && \
	$(MAKE) install clean

lib/librtmp.a:
	cd src/rtmpdump-$(RTMPDUMP_VERSION) && \
	$(MAKE) prefix=$(PWD) MANDIR=$(PWD)/share/man \
		CRYPTO= \
		SHARED= \
		install && \
	$(MAKE) clean
