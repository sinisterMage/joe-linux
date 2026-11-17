# Following the book's Vulkan-Headers page. The tests (which only compile
# the headers) and the C++20 module files are off; the modules need a
# compiler and CMake with "import std", which is experimental.
build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D VULKAN_HEADERS_ENABLE_TESTS=OFF \
        -D VULKAN_HEADERS_ENABLE_MODULE=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
