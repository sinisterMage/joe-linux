prepare() {
    # The book's required patch: an accessor Chromium-based browsers expect
    # when built against the system's ffmpeg.
    patch -Np1 -i "$SOURCES/ffmpeg-9.0.2-chromium_method-1.patch"
}

build() {
    # --disable-autodetect: nothing is taken from the build root unless it
    # is named below.
    #
    # From the book: GPL and version 3 licensing, shared libraries only,
    # libaom, dav1d, FreeType, LAME, Opus, Vorbis, libvpx, x264, x265,
    # OpenSSL. Of the book's optional libraries: HarfBuzz (without it
    # FreeType alone no longer gives the drawtext filter), Fontconfig,
    # FriBidi, libwebp, PulseAudio and libdrm (kmsgrab), and the ALSA, zlib,
    # bzip2, xz and iconv support that configure would otherwise detect.
    #
    # Tier-2 integrations: ASS subtitles, SVT-AV1, Theora, Speex, MP2,
    # DVD-Video, SRT/RIST, libv4l2, Vulkan and SDL2 ffplay. Vulkan shaders
    # are compiled by the explicitly selected glslang executable.
    #
    # Left out: nonfree codecs (the result must remain distributable),
    # VDPAU and proprietary GPU interfaces, X11 capture and sndio.
    # - HTML and text documentation (needs Texinfo); the manual pages are
    #   built.
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --shlibdir=/usr/lib \
        --enable-gpl \
        --enable-version3 \
        --disable-static \
        --enable-shared \
        --disable-debug \
        --disable-autodetect \
        --enable-libaom \
        --enable-libdav1d \
        --enable-libass \
        --enable-libsvtav1 \
        --enable-libtheora \
        --enable-libspeex \
        --enable-libtwolame \
        --enable-libdvdnav \
        --enable-libdvdread \
        --enable-libsrt \
        --enable-librist \
        --enable-libv4l2 \
        --enable-v4l2-m2m \
        --enable-libfreetype \
        --enable-libharfbuzz \
        --enable-libfontconfig \
        --enable-libfribidi \
        --enable-libmp3lame \
        --enable-libopus \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libwebp \
        --enable-libx264 \
        --enable-libx265 \
        --enable-openssl \
        --enable-alsa \
        --enable-libpulse \
        --enable-libdrm \
        --enable-vaapi \
        --enable-vulkan \
        --glslc=glslang \
        --enable-zlib \
        --enable-bzlib \
        --enable-lzma \
        --enable-iconv \
        --enable-sdl2 \
        --enable-ffplay \
        --disable-htmlpages \
        --disable-txtpages \
        --docdir=/usr/share/doc/ffmpeg-9.0.2
    make
    gcc tools/qt-faststart.c -o tools/qt-faststart
}

package() {
    make DESTDIR="$DESTDIR" install
    install -m755 tools/qt-faststart "$DESTDIR/usr/bin"
}
