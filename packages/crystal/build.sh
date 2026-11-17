# Not in the book: newest upstream release, following its Makefile and
# https://crystal-lang.org/reference/installation/from_source.html.
# Crystal 1.22.3 supports the system LLVM 23 without a backport:
# src/llvm/ext/llvm-versions.txt lists 23.1, and src/llvm/lib_llvm.cr has the
# LLVM 23 API conditionals. Do not substitute the stage0's bundled LLVM.

prepare() {
    mkdir .stage0
    tar -xf "$SOURCES/crystal-1.22.2-1-linux-x86_64-bundled.tar.gz" -C .stage0 \
        --no-same-owner --no-same-permissions
}

build() {
    # The wrapper reads the new source tree, not the bootstrap's stdlib.
    # Prevent the bundled stage0 GC/PCRE archives from entering the compiler
    # we ship: both the compiler and its users link joe's system libraries.
    export CRYSTAL="$PWD/.stage0/crystal-1.22.2-1/bin/crystal"
    export CRYSTAL_CACHE_DIR="$PWD/.crystal-cache"
    export CRYSTAL_LIBRARY_PATH=/usr/lib
    export LLVM_CONFIG=/usr/bin/llvm-config
    # Crystal inserts this value into a shell command, so it must be one line.
    export LLVM_LDFLAGS="$(llvm-config --link-shared --libs --system-libs --ldflags | tr '\n' ' ')"
    # Both upstream Makefiles reuse SOURCES for their complete file list.
    export -n SOURCES
    env -u DESTDIR make build release=1 interpreter=1 docs_sanitizer=1 \
        CRYSTAL_CONFIG_LIBRARY_PATH="'/usr/lib'" EXPORT_CC='CC=gcc'
}

package() {
    export -n SOURCES
    make PREFIX=/usr DESTDIR="$DESTDIR" interpreter=1 docs_sanitizer=1 \
        CRYSTAL_CONFIG_LIBRARY_PATH="'/usr/lib'" EXPORT_CC='CC=gcc' install
}
