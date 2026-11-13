build() {
    mkdir build
    cd build
    # The book's options (TESTDATADIR only silences a warning), plus:
    # - CMAKE_INSTALL_LIBDIR, so that nothing can pick lib64;
    # - ENABLE_QT6=OFF: Qt does not exist here;
    # - ENABLE_BOOST=OFF: Boost has no recipe. It only speeds up the Splash
    #   backend; the GLib binding, which Evince uses, renders with Cairo;
    # - ENABLE_GPGME=OFF: gpgmepp has no recipe; signatures use NSS;
    # - everything found in the build root stated explicitly, and neither
    #   the test programs nor the GTK-Doc reference.
    cmake -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D TESTDATADIR="$PWD/testfiles" \
        -D ENABLE_UNSTABLE_API_ABI_HEADERS=ON \
        -D ENABLE_QT5=OFF \
        -D ENABLE_QT6=OFF \
        -D ENABLE_BOOST=OFF \
        -D ENABLE_GPGME=OFF \
        -D ENABLE_NSS3=ON \
        -D ENABLE_UTILS=ON \
        -D ENABLE_CPP=ON \
        -D ENABLE_GLIB=ON \
        -D ENABLE_GOBJECT_INTROSPECTION=ON \
        -D ENABLE_GTK_DOC=OFF \
        -D ENABLE_BROTLI=ON \
        -D ENABLE_HARFBUZZ=ON \
        -D ENABLE_LIBOPENJPEG=ON \
        -D ENABLE_LIBJPEG=ON \
        -D ENABLE_LCMS=ON \
        -D ENABLE_LIBCURL=ON \
        -D ENABLE_LIBTIFF=ON \
        -D BUILD_GTK_TESTS=OFF \
        -D BUILD_CPP_TESTS=OFF \
        -D BUILD_MANUAL_TESTS=OFF \
        -D INSTALL_GLIB_DEMO=OFF \
        -D RUN_GPERF_IF_PRESENT=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # poppler-data, as on the book's page.
    tar --no-same-owner --no-same-permissions -xf "$SOURCES/poppler-data-0.4.12.tar.gz"
    cd poppler-data-0.4.12
    make prefix=/usr DESTDIR="$DESTDIR" install
}
