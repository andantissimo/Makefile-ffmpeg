## ffmpeg

FFMPEG_VERSION    = 2.6.2
LAME_VERSION      = 3.99.5
X264_VERSION      = stable
X265_VERSION      = 9f0324125f53
VO_AACENC_VERSION = 0.1.3
LIBOGG_VERSION    = 1.3.2
LIBVORBIS_VERSION = 1.3.5
LIBTHEORA_VERSION = 1.1.1
OPUS_VERSION      = 1.1
LIBVPX_VERSION    = 1.4.0

all: bin/ffmpeg

bin/ffmpeg: lib/libx264.a lib/libx265.a lib/libvpx.a \
			lib/libvo-aacenc.a lib/libmp3lame.a lib/libopus.a \
			lib/libtheora.a lib/libvorbis.a lib/libogg.a
	cd src/ffmpeg-$(FFMPEG_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	export CFLAGS=-I$(PWD)/include && \
	export LDFLAGS=-L$(PWD)/lib && \
	./configure --prefix=$(PWD) \
		--enable-static --disable-shared --enable-runtime-cpudetect \
		--disable-debug --disable-doc --disable-network \
		--disable-ffplay --disable-ffprobe --disable-ffserver \
		--enable-gpl --enable-version3 \
		--enable-libx264 --enable-libx265 --enable-libvpx \
		--enable-libvo-aacenc --enable-libmp3lame --enable-libopus \
		--enable-libtheora --enable-libvorbis \
		--enable-zlib \
		$(FFMPEG_OPTIONS) && \
	$(MAKE) install clean

lib/libx264.a:
	cd src/x264-$(X264_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --enable-strip \
		--disable-cli && \
	$(MAKE) install clean

lib/libx265.a:
	cd src/multicoreware-x265-$(X265_VERSION) && \
	cmake source -DCMAKE_INSTALL_PREFIX=$(PWD) -DCMAKE_BUILD_TYPE=Release \
		-DENABLE_CLI=OFF -DENABLE_SHARED=OFF && \
	$(MAKE) install clean
	sed -i'.bak' -e 's/^\(Libs:.*\)$$/\1 -lstdc++/' lib/pkgconfig/x265.pc

lib/libvpx.a:
	cd src/libvpx-$(LIBVPX_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-install-bins --disable-examples --disable-docs && \
	$(MAKE) && $(MAKE) install clean

lib/libvo-aacenc.a:
	cd src/vo-aacenc-$(VO_AACENC_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean

lib/libmp3lame.a:
	cd src/lame-$(LAME_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--enable-nasm && \
	$(MAKE) install clean

lib/libopus.a:
	cd src/opus-$(OPUS_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean

lib/libtheora.a: lib/libogg.a
	cd src/libtheora-$(LIBTHEORA_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-oggtest --disable-vorbistest --disable-examples && \
	$(MAKE) install clean

lib/libvorbis.a: lib/libogg.a
	cd src/libvorbis-$(LIBVORBIS_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--disable-oggtest && \
	$(MAKE) install clean

lib/libogg.a:
	cd src/libogg-$(LIBOGG_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean
