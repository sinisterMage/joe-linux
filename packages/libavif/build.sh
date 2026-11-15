prepare() {
    # avifgainmaputil needs libargparse, which CMake would fetch with git.
    # FetchContent builds it from ext/libargparse instead.
    mkdir ext/libargparse
    tar -xf "$SOURCES/libargparse-ee74d1b53bd680748af14e737378de57e2a0a954.tar.gz" \
        -C ext/libargparse --strip-components=1 --no-same-owner --no-same-permissions
}

build() {
    mkdir build
    cd build
    # The book's options, except:
    # - SVT-AV1 is off (no recipe), so libaom is the encoder, which the
    #   book only recommends; dav1d stays the preferred decoder. libyuv,
    #   rav1e and libgav1 are off too.
    # - libsharpyuv, which libwebp installs, for sharper RGB to YUV
    #   conversion.
    # - The avifenc, avifdec and avifgainmaputil tools, with PNG and JPEG
    #   via the system libpng and libjpeg-turbo, and libxml2 for JPEG gain
    #   maps. Their manual pages need pandoc and are not built.
    #   FETCHCONTENT_FULLY_DISCONNECTED: nothing may be downloaded.
    # - CMAKE_INSTALL_LIBDIR, so that nothing can pick lib64; no tests.
    # The gdk-pixbuf loader stays off as in the book: GNOME reads images
    # through glycin.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D AVIF_CODEC_AOM=SYSTEM \
        -D AVIF_CODEC_DAV1D=SYSTEM \
        -D AVIF_CODEC_SVT=OFF \
        -D AVIF_CODEC_RAV1E=OFF \
        -D AVIF_CODEC_LIBGAV1=OFF \
        -D AVIF_CODEC_AVM=OFF \
        -D AVIF_LIBYUV=OFF \
        -D AVIF_LIBSHARPYUV=SYSTEM \
        -D AVIF_LIBXML2=SYSTEM \
        -D AVIF_ZLIBPNG=SYSTEM \
        -D AVIF_JPEG=SYSTEM \
        -D AVIF_BUILD_APPS=ON \
        -D AVIF_BUILD_MAN_PAGES=OFF \
        -D AVIF_BUILD_GDK_PIXBUF=OFF \
        -D AVIF_BUILD_TESTS=OFF \
        -D FETCHCONTENT_FULLY_DISCONNECTED=ON \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # libargparse is only linked into avifgainmaputil; its own install
    # rule must not leave the static library or its headers behind.
    rm -f "$DESTDIR/usr/lib/libargparse.a" "$DESTDIR"/usr/include/argparse*
}
