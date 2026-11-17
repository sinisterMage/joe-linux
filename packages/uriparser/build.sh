# Not in the book: the newest upstream release, built with CMake as its
# README.md says.
build() {
    # The shared library (char and wchar_t interfaces) and the uriparse
    # program. No API documentation (Doxygen, Graphviz), tests (googletest)
    # or fuzzers.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D URIPARSER_SHARED_LIBS=ON \
        -D URIPARSER_BUILD_DOCS=OFF \
        -D URIPARSER_BUILD_TESTS=OFF \
        -D URIPARSER_BUILD_FUZZERS=OFF \
        -D URIPARSER_BUILD_TOOLS=ON \
        -D URIPARSER_BUILD_CHAR=ON \
        -D URIPARSER_BUILD_WCHAR_T=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
