# Not in the book: the newest upstream release (0.8.2, from 2020; upstream
# has made none since), built with CMake as its readme says. Only the
# headers and the CMake package files are installed; examples and tests
# (which need Boost) are not built.

prepare() {
    # asio-io-context.patch: upstream pull request 1164 (seven commits),
    # as Arch Linux backported it to 0.8.2. The Asio that Boost 1.87 and
    # later carry, and current standalone asio, removed io_service,
    # deadline_timer, strand::wrap and the other long-deprecated interfaces
    # 0.8.2 uses; the patch moves to io_context and its successors.
    patch -Np1 -i /recipe/asio-io-context.patch
    # cmake-4.patch: upstream commit deb0a33, which raises
    # cmake_minimum_required to 3.10 for CMake 4.
    patch -Np1 -i /recipe/cmake-4.patch
}

build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_CPP11=ON \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_TESTS=OFF
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
