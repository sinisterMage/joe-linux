# Not in the book: the newest upstream release, built with CMake as its
# own RPM spec (packaging/obs_rpm) builds it. fmt, nlohmann_json, whereami
# and tl-expected come with the source in dependencies/ and are linked
# statically.
build() {
    cmake -B build \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TESTING=OFF \
        -D APP_BUILD_TESTS=OFF \
        -D APP_BUILD_EXAMPLES=OFF
    cmake --build build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
