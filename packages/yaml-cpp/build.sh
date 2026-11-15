# Not in the book: the newest upstream release, built with CMake as its
# install.txt describes.

# The release tarball has no top-level directory.
unpack() {
    tar -xf "$SOURCES/yaml-cpp-0.9.0.tar.gz" --no-same-owner --no-same-permissions
}

build() {
    mkdir build
    cd build
    # A shared library only. YAML_CPP_FORMAT_SOURCE=OFF: otherwise the
    # build runs clang-format over the sources when it finds it. The
    # sandbox, parse and read test programs and the tests are not built.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TESTING=OFF \
        -D YAML_BUILD_SHARED_LIBS=ON \
        -D YAML_CPP_BUILD_TESTS=OFF \
        -D YAML_CPP_BUILD_TOOLS=OFF \
        -D YAML_CPP_FORMAT_SOURCE=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
