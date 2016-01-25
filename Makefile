## ffmpeg

FFMPEG_VERSION   = 2.8.5
LAME_VERSION     = 3.99.5
X264_VERSION     = snapshot-20160103-2245-stable
X265_VERSION     = 11047
FDK_AAC_VERSION  = 0.1.4
RTMPDUMP_VERSION = 20150114

all: bin/ffmpeg

bin/ffmpeg: lib/libx264.a \
            lib/libx265.a \
            lib/libfdk-aac.a \
            lib/libmp3lame.a \
            lib/librtmp.a
	cd src/ffmpeg-$(FFMPEG_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	export CFLAGS=-I$(PWD)/include && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-debug --disable-ffplay --disable-ffserver \
		--enable-runtime-cpudetect \
		--enable-gpl --enable-nonfree \
		--enable-libx264 \
		--enable-libx265 \
		--enable-libfdk-aac \
		--enable-libmp3lame \
		--enable-librtmp \
		$(FFMPEG_OPTIONS) && \
	$(MAKE) install clean

lib/libx264.a:
	cd src/x264-$(X264_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --enable-strip && \
	$(MAKE) install clean

lib/libx265.a:
	cd src/x265_$(X265_VERSION) && \
	cmake source -DCMAKE_INSTALL_PREFIX=$(PWD) -DCMAKE_BUILD_TYPE=Release \
		-DENABLE_SHARED=OFF && \
	$(MAKE) install clean
	sed -e 's@^\(Libs:.*\)$$@\1 -lstdc++@' \
	    -i'.bak' lib/pkgconfig/x265.pc

lib/libfdk-aac.a:
	cd src/fdk-aac-$(FDK_AAC_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean

lib/libmp3lame.a:
	cd src/lame-$(LAME_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--enable-nasm && \
	$(MAKE) install clean

lib/librtmp.a:
	cd src/rtmpdump-$(RTMPDUMP_VERSION) && \
	$(MAKE) prefix=$(PWD) MANDIR=$(PWD)/share/man \
		CRYPTO= \
		SHARED= \
		install && \
	$(MAKE) clean
