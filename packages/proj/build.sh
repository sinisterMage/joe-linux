# Not in the book: the newest upstream release, built with CMake as its
# installation guide says: with TIFF grids and network (curl) access, the
# system's nlohmann/json, proj.db installed as a file in /usr/share/proj
# rather than embedded in the library, and without the tests (they would
# download GoogleTest). The datum grids (proj-data) are a separate download
# that PROJ fetches on demand from its CDN when networking is enabled.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D ENABLE_TIFF=ON \
        -D ENABLE_CURL=ON \
        -D NLOHMANN_JSON_ORIGIN=external \
        -D EMBED_RESOURCE_FILES=OFF \
        -D BUILD_TESTING=OFF \
        -D BUILD_EXAMPLES=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
