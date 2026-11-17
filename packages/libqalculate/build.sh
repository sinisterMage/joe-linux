# Not in the book: the newest upstream release, built as its INSTALL says
# and as Arch Linux builds it. The API reference is not generated
# (ac_cv_prog_DOXYGEN= hides doxygen from configure); the driver would
# remove it anyway.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --with-libcurl \
        --with-icu \
        --with-readline \
        ac_cv_prog_DOXYGEN=
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
