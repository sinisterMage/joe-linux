# The book builds LLVM without lld, and so does the llvm recipe. This builds
# lld on its own against the installed LLVM, the way Arch does: llvm-tblgen
# and LLVM's CMake files come from the llvm package, and the headers lld
# borrows from libunwind come from the same source tree. The libraries
# (liblldELF.so and the rest) are shared, as zig links them.
build() {
    cmake -S lld -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D LLVM_LINK_LLVM_DYLIB=ON \
        -D LLVM_MAIN_SRC_DIR="$PWD/llvm" \
        -D LLVM_INCLUDE_TESTS=OFF \
        -D LLVM_BUILD_DOCS=OFF \
        -W no-author
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
