# Not in the book: the newest upstream release (tagged 2025-11-05; dave
# versions cannot contain dashes), built with CMake as its README describes,
# against the system Abseil, which RE2 requires and does not bundle.
build() {
    mkdir build
    cd build
    # RE2_USE_ICU stays off, as upstream and other distributions have it:
    # RE2's own Unicode tables serve \p{...}, and ICU would only widen the
    # set of property names.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_TESTING=OFF \
        -D RE2_BUILD_TESTING=OFF \
        -D RE2_USE_ICU=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
