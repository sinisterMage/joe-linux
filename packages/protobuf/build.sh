build() {
    mkdir build
    cd build
    # The book's options, plus:
    # - CMAKE_INSTALL_LIBDIR, so that nothing can pick lib64;
    # - protobuf_LOCAL_DEPENDENCIES_ONLY: use the system Abseil and never
    #   fetch a copy from GitHub. It replaces protobuf_ABSL_PROVIDER=package,
    #   which this version no longer has;
    # - zlib support, stated rather than detected.
    # libupb is only ever built static; it is installed, as the book does,
    # for code that protoc-gen-upb generates.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D protobuf_BUILD_TESTS=OFF \
        -D protobuf_BUILD_SHARED_LIBS=ON \
        -D protobuf_LOCAL_DEPENDENCIES_ONLY=ON \
        -D protobuf_WITH_ZLIB=ON \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
