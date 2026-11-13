build() {
    mkdir -p tiff-build
    cd tiff-build
    # The codecs are auto-detected; name every one so that the result does
    # not depend on what happens to be in the build root. No OpenGL/GLUT
    # (tiffgt), sphinx, libdeflate, JBIG-KIT, LERC or libwebp.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D zlib=ON \
        -D lzma=ON \
        -D zstd=ON \
        -D jpeg=ON \
        -D libdeflate=OFF \
        -D jbig=OFF \
        -D lerc=OFF \
        -D webp=OFF \
        -D tiff-opengl=OFF \
        -D sphinx=OFF \
        -D tiff-tests=OFF \
        -W no-author -G Ninja ..
    ninja
}

package() {
    cd tiff-build
    DESTDIR="$DESTDIR" ninja install
}
