# Not in the book. Zig 0.17 is written for LLVM 22, and joe's llvm is 23 and
# built only for the host and AMDGPU, while Zig cross-compiles to every LLVM
# target. So this builds from upstream's zig-bootstrap tarball, which carries
# the LLVM, Clang and LLD Zig needs, and does the first half of its `build`
# script: LLVM for all targets with the system compiler (into a private
# prefix that is not installed), then Zig linked statically against it. The
# second half only exists to make portable static binaries for other systems.

_zig_env() {
    # Keep Zig's caches in the build directory, not in the build root's /root.
    export ZIG_GLOBAL_CACHE_DIR="$PWD/.zig-cache/global"
    export ZIG_LOCAL_CACHE_DIR="$PWD/.zig-cache/local"
}

build() {
    _zig_env
    local host="$PWD/out/host"

    # zig-bootstrap's own LLVM configuration, built with ninja.
    cmake -S llvm -B out/build-llvm-host -G Ninja \
        -D CMAKE_INSTALL_PREFIX="$host" \
        -D CMAKE_PREFIX_PATH="$host" \
        -D CMAKE_BUILD_TYPE=Release \
        -D LLVM_APPEND_VC_REV=OFF \
        -D LLVM_ENABLE_BINDINGS=OFF \
        -D LLVM_ENABLE_LIBEDIT=OFF \
        -D LLVM_ENABLE_LIBPFM=OFF \
        -D LLVM_ENABLE_LIBXML2=OFF \
        -D LLVM_ENABLE_OCAMLDOC=OFF \
        -D LLVM_ENABLE_PLUGINS=OFF \
        -D LLVM_ENABLE_PROJECTS="lld;clang" \
        -D LLVM_ENABLE_Z3_SOLVER=OFF \
        -D LLVM_ENABLE_ZSTD=OFF \
        -D LLVM_INCLUDE_UTILS=OFF \
        -D LLVM_INCLUDE_TESTS=OFF \
        -D LLVM_INCLUDE_EXAMPLES=OFF \
        -D LLVM_INCLUDE_BENCHMARKS=OFF \
        -D LLVM_INCLUDE_DOCS=OFF \
        -D LLVM_TOOL_LLVM_LTO2_BUILD=OFF \
        -D LLVM_TOOL_LLVM_LTO_BUILD=OFF \
        -D LLVM_TOOL_LTO_BUILD=OFF \
        -D LLVM_TOOL_REMARKS_SHLIB_BUILD=OFF \
        -D CLANG_BUILD_TOOLS=OFF \
        -D CLANG_INCLUDE_DOCS=OFF \
        -D CLANG_INCLUDE_TESTS=OFF \
        -D CLANG_TOOL_CLANG_IMPORT_TEST_BUILD=OFF \
        -D CLANG_TOOL_CLANG_LINKER_WRAPPER_BUILD=OFF \
        -D CLANG_TOOL_C_INDEX_TEST_BUILD=OFF \
        -D CLANG_TOOL_LIBCLANG_BUILD=OFF \
        -W no-dev
    # The build environment exports DESTDIR. It must not apply here: this
    # installs into the private prefix, and Zig's own build system (run by
    # the second ninja) would also stage into it.
    env -u DESTDIR ninja -C out/build-llvm-host install

    # Zig itself, for any x86_64 processor (the default is the build
    # machine's), installed under /usr: bin/zig and lib/zig/.
    cmake -S zig -B out/build-zig -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_PREFIX_PATH="$host" \
        -D CMAKE_BUILD_TYPE=Release \
        -D ZIG_VERSION=0.17.1 \
        -D ZIG_TARGET_MCPU=baseline \
        -D ZIG_STATIC_LLVM=ON \
        -W no-dev
    env -u DESTDIR ninja -C out/build-zig
}

package() {
    _zig_env
    DESTDIR="$DESTDIR" cmake --install out/build-zig
}
