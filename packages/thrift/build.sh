# Not in the book: the newest upstream release, built with CMake as
# build/cmake/README.md describes.
build() {
    # The compiler (which generates code for every language) and the C++
    # and C (GLib) libraries, shared, with OpenSSL, libevent and zlib
    # support. Every other language library (Java, JavaScript, Node.js,
    # Python, Kotlin) and Qt5 (not packaged) are off, as are the tests and
    # tutorials. LIB_INSTALL_DIR keeps its default, lib under the prefix: it is
    # a PATH cache variable, so CMake would make a relative value given on
    # the command line absolute against the source directory.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_COMPILER=ON \
        -D BUILD_LIBRARIES=ON \
        -D BUILD_TESTING=OFF \
        -D BUILD_TUTORIALS=OFF \
        -D WITH_CPP=ON \
        -D WITH_OPENSSL=ON \
        -D WITH_LIBEVENT=ON \
        -D WITH_ZLIB=ON \
        -D WITH_QT5=OFF \
        -D WITH_C_GLIB=ON \
        -D WITH_JAVA=OFF \
        -D WITH_JAVASCRIPT=OFF \
        -D WITH_NODEJS=OFF \
        -D WITH_PYTHON=OFF \
        -D BUILD_KOTLIN=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
