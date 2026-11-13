build() {
    mkdir build
    cd build
    # The book's options, plus:
    # - CMAKE_INSTALL_LIBDIR, so that nothing can pick lib64;
    # - JPEGXL_FORCE_SYSTEM_*: the archive's third_party directories are
    #   empty git submodules, so the system libraries must be used;
    # - no Doxygen documentation, manual pages (asciidoc), benchmark and
    #   example programs, Java bindings or OpenEXR support.
    # JPEGXL_ENABLE_PLUGINS=OFF: the gdk-pixbuf loader is deprecated; GNOME
    # reads JPEG XL through glycin, which links this library.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TESTING=OFF \
        -D BUILD_SHARED_LIBS=ON \
        -D JPEGXL_ENABLE_SKCMS=OFF \
        -D JPEGXL_ENABLE_SJPEG=OFF \
        -D JPEGXL_ENABLE_PLUGINS=OFF \
        -D JPEGXL_INSTALL_JARDIR=/usr/share/java \
        -D JPEGXL_FORCE_SYSTEM_BROTLI=ON \
        -D JPEGXL_FORCE_SYSTEM_HWY=ON \
        -D JPEGXL_FORCE_SYSTEM_LCMS2=ON \
        -D JPEGXL_ENABLE_DOXYGEN=OFF \
        -D JPEGXL_ENABLE_MANPAGES=OFF \
        -D JPEGXL_ENABLE_BENCHMARK=OFF \
        -D JPEGXL_ENABLE_EXAMPLES=OFF \
        -D JPEGXL_ENABLE_JNI=OFF \
        -D JPEGXL_ENABLE_OPENEXR=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
