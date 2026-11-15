build() {
    mkdir build
    cd build
    # The book's options, except:
    # - DOCBOOKXSL_DIR is left out: this release assembles its manual pages
    #   from text templates and no longer runs the DocBook stylesheets.
    # - Smart cards are on (WITH_PCSC), as pcsc-lite has a recipe.
    # - CMAKE_INSTALL_LIBDIR, so that nothing can pick lib64.
    # What the build root would otherwise decide is stated: X11 and Wayland
    # clients, PulseAudio and ALSA, CUPS printers, Kerberos, the journal,
    # FUSE, json-c, and ICU for Unicode conversion.
    # Off: the SDL client (no SDL), OSS and sndio, uriparser, OpenH264, GSM,
    # FAAD2 and FAAC (no recipes); LAME, Opus and soxr, because FFmpeg
    # already encodes, decodes and resamples the audio. AV1 for the graphics
    # channel is experimental.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D CMAKE_BUILD_TYPE=Release \
        -D WITH_CAIRO=ON \
        -D WITH_CLIENT_SDL=OFF \
        -D WITH_DSP_FFMPEG=ON \
        -D WITH_FFMPEG=ON \
        -D WITH_SWSCALE=ON \
        -D WITH_PCSC=ON \
        -D WITH_SERVER=ON \
        -D WITH_SERVER_CHANNELS=ON \
        -D WITH_X11=ON \
        -D WITH_WAYLAND=ON \
        -D WITH_PULSE=ON \
        -D WITH_ALSA=ON \
        -D WITH_OSS=OFF \
        -D WITH_SNDIO=OFF \
        -D WITH_CUPS=ON \
        -D WITH_KRB5=ON \
        -D WITH_SYSTEMD=ON \
        -D WITH_FUSE=ON \
        -D WITH_JSONC_REQUIRED=ON \
        -D WITH_URIPARSER=OFF \
        -D WITH_OPENH264=OFF \
        -D WITH_GSM=OFF \
        -D WITH_LAME=OFF \
        -D WITH_FAAD2=OFF \
        -D WITH_FAAC=OFF \
        -D WITH_SOXR=OFF \
        -D WITH_OPUS=OFF \
        -D WITH_AOM=OFF \
        -D WITH_DAV1D=OFF \
        -D WITH_YUV=OFF \
        -D WITH_MANPAGES=ON \
        -W no-author \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
