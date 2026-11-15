# Not in the book: the newest upstream release, built with CMake as its
# INSTALL.md describes. Upstream publishes no checksum for the archive.
build() {
    mkdir build
    cd build
    # No hwloc: tbbbind (NUMA and hybrid-core awareness) and the Thread
    # Composability Manager need it, so they are not built, and hwloc is not
    # looked for. TBB_STRICT=OFF: warnings are not errors with a newer
    # compiler than upstream tested. tbb, tbbmalloc and tbbmalloc_proxy
    # are built; the tests, examples and Python module (tbb4py) are not.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D TBB_TEST=OFF \
        -D TBB_EXAMPLES=OFF \
        -D TBB_STRICT=OFF \
        -D TBB4PY_BUILD=OFF \
        -D TBB_DISABLE_HWLOC_AUTOMATIC_SEARCH=ON \
        -D TCM_BUILD=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
