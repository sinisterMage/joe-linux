# Not a separate book page: Qt submodule matching joe's base Qt build.
build() {
    cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DQT_GENERATE_SBOM=OFF \
        -DFEATURE_libudev=ON
    cmake --build build -j"$JOBS"
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
