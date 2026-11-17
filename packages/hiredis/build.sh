# Not in the book: the newest upstream release, built with its Makefile as
# its README describes. The Makefile is used rather than CMakeLists.txt
# because it gives the libraries upstream's soname, which changes with every
# minor release (libhiredis.so.1.5.0); the CMake build would name them only
# by the major version. So no CMake package files are installed, only the
# pkg-config files.
build() {
    # USE_WERROR=0: upstream builds with -Werror, which a newer compiler's
    # new warnings would turn into failures. The test program the default
    # target also builds is not installed.
    make PREFIX=/usr LIBRARY_PATH=lib USE_SSL=1 USE_WERROR=0
}

package() {
    make PREFIX=/usr LIBRARY_PATH=lib USE_SSL=1 USE_WERROR=0 \
        DESTDIR="$DESTDIR" install
    # make install always installs the static libraries too.
    rm "$DESTDIR/usr/lib/libhiredis.a" "$DESTDIR/usr/lib/libhiredis_ssl.a"
}
