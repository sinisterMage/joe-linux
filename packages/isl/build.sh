# Not in the book: the newest upstream release, built as its README says.
# Integers are GMP's (--with-int=gmp, the default). The Python interface is
# only used by the test suite, and the C++ interface generator needs clang's
# libraries (--with-clang=system); it is not needed for the installed C++
# headers, which come pre-generated.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --with-int=gmp \
        --with-gmp=system \
        --with-clang=no
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # isl installs its GDB pretty-printers next to the library; GDB loads
    # them automatically from its auto-load directory instead.
    install -d "$DESTDIR/usr/share/gdb/auto-load/usr/lib"
    mv "$DESTDIR"/usr/lib/libisl.so.*-gdb.py "$DESTDIR/usr/share/gdb/auto-load/usr/lib/"
}
