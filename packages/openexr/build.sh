# Not in the book: the newest upstream release, built with CMake as its
# install documentation describes.
build() {
    mkdir build
    cd build
    # The system Imath, libdeflate and zstd; never fetch Imath with git.
    # OpenJPH (the HTJ2K codec) has no recipe and is built in from the
    # copy in external/. The tools are installed; the examples, the
    # Python bindings and the tests are not. Their manual pages are made
    # with help2man and are left out.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TESTING=OFF \
        -D OPENEXR_FORCE_INTERNAL_IMATH=OFF \
        -D OPENEXR_FORCE_INTERNAL_DEFLATE=OFF \
        -D OPENEXR_FORCE_INTERNAL_ZSTD=OFF \
        -D OPENEXR_FORCE_INTERNAL_OPENJPH=ON \
        -D OPENEXR_BUILD_TOOLS=ON \
        -D OPENEXR_INSTALL_TOOLS=ON \
        -D OPENEXR_BUILD_EXAMPLES=OFF \
        -D OPENEXR_BUILD_PYTHON=OFF \
        -D OPENEXR_INSTALL_DOCS=OFF \
        -D FETCHCONTENT_FULLY_DISCONNECTED=ON \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
