# Not in the book: the newest upstream release, built with CMake against
# the system's libraries as BUILDING.md describes ("package" providers).
prepare() {
    tar -xf "$SOURCES/grpc-proto-dd549fc4ed04b60b0fdd3866b82ef0a7c87c6e4f.tar.gz" \
        -C third_party/grpc-proto --strip-components=1 \
        --no-same-owner --no-same-permissions
}

build() {
    # - Every third-party library comes from the system ("package"); upb,
    #   utf8_range, xxhash and address_sorting are the copies inside the
    #   archive (gRPC has no switch for them), built as gRPC's own libraries
    #   (libupb_*_lib, libutf8_range_lib, libaddress_sorting).
    # - gRPC_DOWNLOAD_ARCHIVES=OFF: never fetch anything; the only empty
    #   submodule configuring needs is grpc-proto, unpacked above.
    # - Code generation is on for grpc_cpp_plugin and the libraries built
    #   with it (grpc++_reflection, grpcpp_channelz); the plugins for other
    #   languages are off, as are the tests and the OpenTelemetry plugin
    #   (opentelemetry-cpp has no recipe).
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D gRPC_INSTALL=ON \
        -D gRPC_INSTALL_LIBDIR=lib \
        -D gRPC_BUILD_TESTS=OFF \
        -D gRPC_DOWNLOAD_ARCHIVES=OFF \
        -D gRPC_ABSL_PROVIDER=package \
        -D gRPC_CARES_PROVIDER=package \
        -D gRPC_PROTOBUF_PROVIDER=package \
        -D gRPC_RE2_PROVIDER=package \
        -D gRPC_SSL_PROVIDER=package \
        -D gRPC_ZLIB_PROVIDER=package \
        -D gRPC_USE_SYSTEMD=ON \
        -D gRPC_BUILD_CODEGEN=ON \
        -D gRPC_BUILD_GRPC_CPP_PLUGIN=ON \
        -D gRPC_BUILD_GRPC_CSHARP_PLUGIN=OFF \
        -D gRPC_BUILD_GRPC_NODE_PLUGIN=OFF \
        -D gRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF \
        -D gRPC_BUILD_GRPC_PHP_PLUGIN=OFF \
        -D gRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF \
        -D gRPC_BUILD_GRPC_RUBY_PLUGIN=OFF \
        -D gRPC_BUILD_GRPCPP_OTEL_PLUGIN=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
