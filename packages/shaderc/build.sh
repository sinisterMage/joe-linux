# Following the book's glslc page, which builds against the system glslang
# and SPIRV-Tools rather than the copies shaderc expects in third_party/.
# The book builds and installs only glslc; this also installs libshaderc
# (libshaderc_shared.so and shaderc.pc), as distributions do, since
# libplacebo and other Vulkan programs compile shaders through it.
prepare() {
    sed '/build-version/d'   -i glslc/CMakeLists.txt
    sed '/third_party/d'     -i CMakeLists.txt
    # The examples directory is not built (SHADERC_SKIP_EXAMPLES), but
    # take it out with third_party as distributions do.
    sed '/add_subdirectory(examples)/d' -i CMakeLists.txt
    sed 's|SPIRV|glslang/&|' -i libshaderc_util/src/compiler.cc
    # What glslc --version prints; upstream generates it from git.
    echo "\"$PKG_VERSION\"" > glslc/src/build-version.inc
}

build() {
    mkdir build
    cd build
    # -Werror is upstream's default; a newer GCC's new warnings should not
    # fail the build. The copyright check is a lint for developers.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D SHADERC_SKIP_TESTS=ON \
        -D SHADERC_SKIP_EXAMPLES=ON \
        -D SHADERC_SKIP_COPYRIGHT_CHECK=ON \
        -D SHADERC_ENABLE_WERROR_COMPILE=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # Static libraries and their pkg-config files: nothing in joe links
    # shaderc statically.
    rm -f "$DESTDIR"/usr/lib/libshaderc.a \
        "$DESTDIR"/usr/lib/libshaderc_combined.a \
        "$DESTDIR"/usr/lib/pkgconfig/shaderc_static.pc \
        "$DESTDIR"/usr/lib/pkgconfig/shaderc_combined.pc
}
