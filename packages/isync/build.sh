# Not in the book: the newest upstream release, built as its INSTALL says.
prepare() {
    patch -Np1 -i /recipe/openssl4.patch
}

build() {
    # TLS, SASL and zlib. Berkeley DB, which only mdconvert (the converter
    # from the old database UID scheme) needs, has no recipe, so its check
    # is answered "no" and mdconvert is not built.
    ac_cv_berkdb4=no ./configure --prefix=/usr \
        --with-ssl=/usr \
        --with-sasl=/usr \
        --with-zlib
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
