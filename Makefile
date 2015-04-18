## ffmpeg

ARCH ?= $(shell uname -m)

FFMPEG_VERSION       = 2.2.3
LAME_VERSION         = 3.99.5
X264_VERSION         = snapshot-20130703-2245-stable
VO_AACENC_VERSION    = 0.1.3
VO_AMRWBENC_VERSION  = 0.1.3
OPENCORE_AMR_VERSION = 0.1.3
LIBOGG_VERSION       = 1.3.1
LIBVORBIS_VERSION    = 1.3.4
LIBTHEORA_VERSION    = 1.1.1
SPEEX_VERSION        = 1.2rc1
OPUS_VERSION         = 1.1
LIBVPX_VERSION       = 1.3.0

FFMPEG_OPTIONS ?=
ifeq ($(shell uname), FreeBSD)
	FFMPEG_OPTIONS += --disable-asm
endif

ifeq ($(shell uname), Darwin)
	EXTRA_CFLAGS = -Wno-error=unused-command-line-argument-hard-error-in-future
endif

all: bin/ffmpeg

clean:
	$(RM) -r bin/ffmpeg \
		include/libavcodec  lib/pkgconfig/libavcodec.pc  lib/libavcodec.a \
		include/libavdevice lib/pkgconfig/libavdevice.pc lib/libavdevice.a \
		include/libavfilter lib/pkgconfig/libavfilter.pc lib/libavfilter.a \
		include/libavformat lib/pkgconfig/libavformat.pc lib/libavformat.a \
		include/libavutil   lib/pkgconfig/libavutil.pc   lib/libavutil.a \
		include/libpostproc lib/pkgconfig/libpostproc.pc lib/libpostproc.a \
		include/libswscale  lib/pkgconfig/libswscale.pc  lib/libswscale.a \
		include/libswresample lib/pkgconfig/libswresample.pc \
			lib/libswresample.a \
		share/ffmpeg
	$(RM) -r bin/lame \
		include/lame lib/libmp3lame.a lib/libmp3lame.la \
		share/doc/lame share/man/man1/lame.1
	$(RM) -r \
		include/x264.h include/x264_config.h \
		lib/pkgconfig/x264.pc lib/libx264.a
	$(RM) -r \
		include/vo-aacenc lib/pkgconfig/vo-aacenc.pc \
		lib/libvo-aacenc.a lib/libvo-aacenc.la
	$(RM) -r \
		include/vo-amrwbenc lib/pkgconfig/vo-amrwbenc.pc \
		lib/libvo-amrwbenc.a lib/libvo-amrwbenc.la
	$(RM) -r \
		include/opencore-amrnb lib/pkgconfig/opencore-amrnb.pc \
		lib/libopencore-amrnb.a lib/libopencore-amrnb.la \
		include/opencore-amrwb lib/pkgconfig/opencore-amrwb.pc \
		lib/libopencore-amrwb.a lib/libopencore-amrwb.la
	$(RM) -r \
		include/ogg lib/pkgconfig/ogg.pc lib/libogg.a lib/libogg.la \
		share/aclocal/ogg.m4 share/doc/libogg*
	$(RM) -r \
		include/vorbis \
		lib/pkgconfig/vorbis.pc lib/libvorbis.a lib/libvorbis.la \
		lib/pkgconfig/vorbisenc.pc lib/libvorbisenc.a lib/libvorbisenc.la \
		lib/pkgconfig/vorbisfile.pc lib/libvorbisfile.a lib/libvorbisfile.la \
		share/aclocal/vorbis.m4 share/doc/libvorbis-*
	$(RM) -r \
		include/theora \
		lib/pkgconfig/theora.pc lib/libtheora.a lib/libtheora.la \
		lib/pkgconfig/theoradec.pc lib/libtheoradec.a lib/libtheoradec.la \
		lib/pkgconfig/theoraenc.pc lib/libtheoraenc.a lib/libtheoraenc.la \
		share/doc/libtheora-*
	$(RM) -r bin/speexdec bin/speexenc \
		include/speex \
		lib/pkgconfig/speex.pc lib/libspeex.a lib/libspeex.la \
		lib/pkgconfig/speexdsp.pc lib/libspeexdsp.a lib/libspeexdsp.la \
		share/aclocal/speex.m4 share/doc/speex \
		share/man/man1/speexdec.1 share/man/man1/speexenc.1
	$(RM) -r \
		include/opus \
		lib/pkgconfig/opus.pc lib/libopus.a lib/libopus.la \
		share/aclocal/opus.m4 \
	$(RM) -r \
		include/vpx lib/pkgconfig/vpx.pc lib/libvpx.a

bin/ffmpeg: lib/libmp3lame.a lib/libx264.a lib/libvo-aacenc.a \
			lib/libopencore-amrnb.a lib/libvo-amrwbenc.a  \
			lib/libogg.a lib/libvorbis.a lib/libtheora.a lib/libspeex.a \
			lib/libopus.a lib/libvpx.a
	cd src/ffmpeg-$(FFMPEG_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	export CFLAGS=-I$(PWD)/include && \
	export LDFLAGS=-L$(PWD)/lib && \
	./configure --prefix=$(PWD) --extra-version=andantissimo \
		--enable-static --disable-shared --enable-runtime-cpudetect \
		--disable-debug --disable-doc --disable-network \
		--disable-ffplay --disable-ffprobe --disable-ffserver \
		--enable-gpl --enable-version3 \
		--enable-libmp3lame --enable-libx264 \
		--enable-libvo-aacenc --enable-libvo-amrwbenc \
		--enable-libopencore-amrnb --enable-libopencore-amrwb \
		--enable-libvorbis --enable-libtheora --enable-libspeex \
		--enable-libopus --enable-libvpx \
		--enable-zlib \
		$(FFMPEG_OPTIONS) && \
	$(MAKE) install clean

lib/libmp3lame.a:
	cd src/lame-$(LAME_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--enable-nasm && \
	$(MAKE) install clean

lib/libx264.a:
ifeq ($(shell uname), Darwin)
	if [ ! -f src/x264-$(X264_VERSION)/configure.original ]; then \
		sed -i '.original' \
			-e 's/^\(.*CFLAGS -falign-loops=.*\)/#\1/' \
			src/x264-$(X264_VERSION)/configure; \
	fi
endif
	cd src/x264-$(X264_VERSION) && \
	./configure --prefix=$(PWD) --enable-static \
		--disable-cli --enable-strip --extra-cflags=$(EXTRA_CFLAGS) && \
	$(MAKE) install clean

lib/libvo-aacenc.a:
	cd src/vo-aacenc-$(VO_AACENC_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean

lib/libvo-amrwbenc.a:
	cd src/vo-amrwbenc-$(VO_AMRWBENC_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean

lib/libopencore-amrnb.a:
	cd src/opencore-amr-$(OPENCORE_AMR_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean

lib/libogg.a:
	cd src/libogg-$(LIBOGG_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean

lib/libvorbis.a: lib/libogg.a
	cd src/libvorbis-$(LIBVORBIS_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean

lib/libtheora.a: lib/libogg.a
	cd src/libtheora-$(LIBTHEORA_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	export CFLAGS=$(EXTRA_CFLAGS) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean

lib/libspeex.a: lib/libogg.a
	cd src/speex-$(SPEEX_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	./configure --prefix=$(PWD) --enable-static --disable-shared \
		--enable-sse && \
	$(MAKE) install clean

lib/libopus.a:
	cd src/opus-$(OPUS_VERSION) && \
	./configure --prefix=$(PWD) --enable-static --disable-shared && \
	$(MAKE) install clean

lib/libvpx.a:
	cd src/libvpx-v$(LIBVPX_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	export CXXFLAGS=-DGTEST_USE_OWN_TR1_TUPLE=1 && \
	./configure --prefix=$(PWD) --enable-static --disable-shared --enable-vp8 \
		--disable-examples --disable-install-bins && \
	$(MAKE) && $(MAKE) install clean
