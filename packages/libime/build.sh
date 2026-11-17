# Not in the book: the newest upstream release, built with CMake as its
# README says.
build() {
    # The build compiles the language model and the dictionaries with the
    # tools it has just built. KenLM is the copy upstream carries.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_TEST=OFF \
        -D ENABLE_DOC=OFF \
        -D ENABLE_DATA=ON \
        -D ENABLE_TOOLS=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
