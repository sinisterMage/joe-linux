# Not in the book: the newest upstream release (3.1.0, from 2009 and still
# the last), built as its INSTALL says. Its configure script is from 2009,
# so it is regenerated, as distributions do; automake no longer knows the
# dist-lzma option configure.ac asks for, which only affects "make dist".

prepare() {
    sed -i 's/dist-lzma/dist-xz/' configure.ac
    # A printf with a non-literal format (-Wformat-security), as Arch fixes it.
    sed -i 's/printf( sf_strerror( NULL ) );/printf( "%s", sf_strerror( NULL ) );/' src/bs2bconvert.c
    autoreconf -fi
}

build() {
    ./configure --prefix=/usr \
        --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
