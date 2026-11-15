build() {
    mkdir build
    cd build
    # As the book configures, with Python. Off because joe Linux does not
    # have what they need: debuginfod (elfutils is built without
    # libdebuginfod), Guile, GNU Source-highlight, Intel Processor Trace
    # (libipt) and the AMD GPU debugger API.
    #
    # gmp and mpfr are not named: the top-level configure takes
    # --with-mpfr as an install prefix, and both are found in /usr.
    ../configure --prefix=/usr \
        --with-system-readline \
        --with-system-zlib \
        --with-python=/usr/bin/python3 \
        --with-expat \
        --with-lzma \
        --with-zstd \
        --with-xxhash \
        --enable-tui \
        --without-debuginfod \
        --without-guile \
        --disable-source-highlight \
        --without-intel-pt \
        --without-amd-dbgapi
    make
}

package() {
    cd build
    # Only gdb and gdbserver: the libraries (bfd, opcodes, sframe, ctf) in
    # the same tree belong to binutils.
    make -C gdb DESTDIR="$DESTDIR" install
    make -C gdbserver DESTDIR="$DESTDIR" install
}
