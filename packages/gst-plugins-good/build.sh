build() {
    mkdir build
    cd build
    # Every plugin with an outside dependency is named.
    #
    # Built: cairo, FLAC, gdk-pixbuf, JPEG, PNG, bzip2 (Matroska), LAME (MP3
    # encoding), mpg123 (MP3 decoding), libvpx (VP8 and VP9), libsoup 3
    # (HTTP source, and with libxml2 and OpenSSL the DASH/HLS/MSS client)
    # and Video4Linux (libv4l2 conversions and gudev discovery). Tier-2
    # adds Speex, TagLib, TwoLAME, WavPack and PulseAudio client output;
    # PipeWire supplies the PulseAudio-compatible server.
    #
    # No libraries for aalib, AMR, libcaca, DV/IEEE 1394, JACK or shout2.
    # GTK/Qt sinks, X11 capture, Orc and obsolete OSS stay off.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D nls=enabled \
        -D asm=enabled \
        -D cairo=enabled \
        -D flac=enabled \
        -D gdk-pixbuf=enabled \
        -D jpeg=enabled \
        -D png=enabled \
        -D bz2=enabled \
        -D soup=enabled \
        -D soup-version=3 \
        -D soup-lookup-dep=true \
        -D adaptivedemux2=enabled \
        -D hls-crypto=openssl \
        -D v4l2=enabled \
        -D v4l2-probe=true \
        -D v4l2-gudev=enabled \
        -D v4l2-libv4l2=enabled \
        -D aalib=disabled \
        -D amrnb=disabled \
        -D amrwbdec=disabled \
        -D libcaca=disabled \
        -D dv=disabled \
        -D dv1394=disabled \
        -D jack=disabled \
        -D lame=enabled \
        -D mpg123=enabled \
        -D pulse=enabled \
        -D shout2=disabled \
        -D speex=enabled \
        -D taglib=enabled \
        -D twolame=enabled \
        -D vpx=enabled \
        -D wavpack=enabled \
        -D gtk3=disabled \
        -D qt5=disabled \
        -D qt6=disabled \
        -D ximagesrc=disabled \
        -D oss=disabled \
        -D oss4=disabled \
        -D directsound=disabled \
        -D waveform=disabled \
        -D osxaudio=disabled \
        -D osxvideo=disabled \
        -D rpicamsrc=disabled \
        -D orc=disabled \
        -D examples=disabled \
        -D tests=disabled \
        -D doc=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
