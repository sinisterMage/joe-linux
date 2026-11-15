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
    # Left out:
    # - --enable-nonfree, libfdk-aac, libass and SVT-AV1: no recipes, and
    #   "nonfree" (needed only for fdk-aac) would make the result
    #   undistributable. AAC is covered by ffmpeg's own encoder and decoder,
    #   AV1 encoding by libaom.
    # - VDPAU, Vulkan, the NVIDIA and AMD interfaces and V4L2 mem2mem: no
    #   recipes for libvdpau and the Vulkan loader. (VA-API is on: it is how
    #   Firefox and other ffmpeg users decode video on the GPU.)
    # - ffplay (SDL has no recipe), X11 screen grabbing (the session is
    #   Wayland), sndio.
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
        --enable-zlib \
        --enable-bzlib \
        --enable-lzma \
        --enable-iconv \
        --disable-ffplay \
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
