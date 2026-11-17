# Not in the book: the newest upstream release (1.8.0, from 2022). Upstream
# builds only static libraries with plain Makefiles, so the C and C++
# libraries are built as shared libraries (soname 1) with the CMake files of
# EasyCoding's qrcodegen-cmake, as Fedora and Arch Linux do. That also
# installs the CMake package and pkg-config files (qrcodegen,
# qrcodegencpp) that OBS Studio's WebSocket server looks for. The headers
# go to /usr/include/qrcodegen and /usr/include/qrcodegencpp.

prepare() {
    tar -xf "$SOURCES/qrcodegen-cmake-1.8.0-cmake5.tar.gz" --strip-components=1 \
        qrcodegen-cmake-1.8.0-cmake5/CMakeLists.txt \
        qrcodegen-cmake-1.8.0-cmake5/cmake
}

build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D QRCODEGEN_BUILD_EXAMPLES=OFF \
        -D QRCODEGEN_BUILD_TESTS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
