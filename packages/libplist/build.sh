# Not in the book: the newest upstream release, built as its README says
# (the release tarball carries a generated configure).
prepare() {
    patch -Np1 -i /recipe/python3-bindings.patch
}

build() {
    # The Python bindings (the plist module) are built with Cython, which
    # configure finds by itself: it has no switch to insist on them, and
    # passing --with-cython actually turns them off. libimobiledevice's
    # bindings build on their .pxd file. The upstream C test suite is not built.
    ./configure --prefix=/usr \
        --disable-static \
        --without-tests \
        PYTHON=/usr/bin/python3
    make
    PYTHONPATH="$PWD/cython/.libs" LD_LIBRARY_PATH="$PWD/src/.libs" \
        python3 /recipe/test-bindings.py
}

package() {
    make DESTDIR="$DESTDIR" install
    # Fail rather than ship without the bindings if Cython was not found.
    compgen -G "$DESTDIR/usr/lib/python3*/site-packages/plist*.so" >/dev/null
}
