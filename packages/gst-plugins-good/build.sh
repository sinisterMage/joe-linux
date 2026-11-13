build() {
    mkdir build
    cd build
    # Every plugin with an outside dependency is named.
    #
    # Built: cairo, FLAC, gdk-pixbuf, JPEG, PNG, bzip2 (Matroska), libsoup 3
    # (HTTP source, and with libxml2 and OpenSSL the DASH/HLS/MSS client)
    # and Video4Linux (kernel interface only, device discovery through
    # gudev).
    #
    # Not built, because the library does not exist: aalib, AMR, libcaca,
    # DV and IEEE 1394, JACK, LAME, mpg123, PulseAudio, shout2, Speex,
    # TagLib, TwoLAME, VP8/VP9 (libvpx), WavPack, libv4l2, GTK 3, Qt 5/6,
    # Orc. ximagesrc would need more of the X libraries than this
    # distribution wants here, and OSS is obsolete.
    meson setup .. \
        --prefix=/usr \
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
        -D v4l2-libv4l2=disabled \
        -D aalib=disabled \
        -D amrnb=disabled \
        -D amrwbdec=disabled \
        -D libcaca=disabled \
        -D dv=disabled \
        -D dv1394=disabled \
        -D jack=disabled \
        -D lame=disabled \
        -D mpg123=disabled \
        -D pulse=disabled \
        -D shout2=disabled \
        -D speex=disabled \
        -D taglib=disabled \
        -D twolame=disabled \
        -D vpx=disabled \
        -D wavpack=disabled \
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
