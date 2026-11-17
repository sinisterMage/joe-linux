# Not in the book: upstream's latest release, with the one upstream commit
# Arch Linux also applies to it.
prepare() {
    # Upstream commit 3b2441b8 ("Removed non-compiling assignment
    # operator"): GCC 14 and later reject GenericStringRef's operator=,
    # which assigns to const members, in every program that includes
    # document.h.
    patch -Np1 -i /recipe/remove-const-assignment.patch
}

build() {
    # Header-only: with the documentation, examples and tests off nothing is
    # compiled (they would also use -march=native and -Werror). The CMake
    # minimum is 2.8, so CMake 4 needs CMAKE_POLICY_VERSION_MINIMUM; with
    # those old policies export(PACKAGE) would write to root's ~/.cmake
    # unless CMAKE_EXPORT_NO_PACKAGE_REGISTRY says not to.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -D CMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON \
        -D LIB_INSTALL_DIR=/usr/lib \
        -D RAPIDJSON_BUILD_DOC=OFF \
        -D RAPIDJSON_BUILD_EXAMPLES=OFF \
        -D RAPIDJSON_BUILD_TESTS=OFF
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
