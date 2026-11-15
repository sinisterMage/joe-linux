# Not in the book: the newest release (0.16.4) of libid3tag as maintained
# by the Tenacity project, which took it over from Underbit (whose last
# release was 0.15.1b in 2004). Built with CMake as its README says.
build() {
    mkdir build
    cd build
    cmake -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D BUILD_SHARED_LIBS=ON \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
