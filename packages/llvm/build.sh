prepare() {
    # Many scripts say "#!/usr/bin/env python"; there is only python3.
    grep -rl '#!.*python$' | xargs sed -i '1s/python$/python3/'

    # Install FileCheck, which the test suites of other packages (rust) want.
    sed 's/utility/tool/' -i llvm/utils/FileCheck/CMakeLists.txt
}

build() {
    mkdir -p llvm/build
    cd llvm/build

    # The book makes clang and clang++ default to -fstack-protector-strong,
    # like gcc, with two configuration files in /etc/clang, and creates them
    # before building so that compiler-rt, which is compiled by the clang
    # just built, is built with that default too. A build must not write to
    # /etc, but clang also reads its configuration files from the directory
    # its own executable is in, so put them next to the just-built clang.
    # They are not installed from here; package() ships the real ones.
    mkdir -p bin
    local i
    for i in clang clang++; do
        echo -fstack-protector-strong > "bin/$i.cfg"
    done

    # The book's options, plus:
    # - CMAKE_INSTALL_LIBDIR, so that nothing can pick lib64;
    # - the optional libraries named explicitly instead of auto-detected:
    #   zlib and zstd are required (FORCE_ON); libxml2 (only used by llvm-mt
    #   and c-index-test), libedit, libpfm and Z3 are not used.
    CC=gcc CXX=g++ \
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D LLVM_ENABLE_FFI=ON \
        -D CMAKE_BUILD_TYPE=Release \
        -D LLVM_BUILD_LLVM_DYLIB=ON \
        -D LLVM_LINK_LLVM_DYLIB=ON \
        -D LLVM_ENABLE_RTTI=ON \
        -D LLVM_TARGETS_TO_BUILD="host;AMDGPU" \
        -D LLVM_ENABLE_PROJECTS=clang \
        -D LLVM_ENABLE_RUNTIMES=compiler-rt \
        -D LLVM_BINUTILS_INCDIR=/usr/include \
        -D LLVM_INCLUDE_BENCHMARKS=OFF \
        -D CLANG_DEFAULT_PIE_ON_LINUX=ON \
        -D CLANG_CONFIG_FILE_SYSTEM_DIR=/etc/clang \
        -D LLVM_ENABLE_ZLIB=FORCE_ON \
        -D LLVM_ENABLE_ZSTD=FORCE_ON \
        -D LLVM_ENABLE_LIBXML2=OFF \
        -D LLVM_ENABLE_LIBEDIT=OFF \
        -D LLVM_ENABLE_LIBPFM=OFF \
        -D LLVM_ENABLE_Z3_SOLVER=OFF \
        -W no-author -G Ninja ..
    ninja
}

package() {
    cd llvm/build
    DESTDIR="$DESTDIR" ninja install

    # Stack protection on by default, consistent with gcc.
    install -d "$DESTDIR/etc/clang"
    local i
    for i in clang clang++; do
        echo -fstack-protector-strong > "$DESTDIR/etc/clang/$i.cfg"
    done
}
