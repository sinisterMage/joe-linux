# Beyond LFS's libqrencode page, named qrencode as other distributions name
# it. The reference manual would need Doxygen and the tests SDL, so neither
# is built.
prepare() {
    sh autogen.sh
}

build() {
    ./configure --prefix=/usr \
        --disable-static \
        --with-png \
        --with-tools \
        --without-tests
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
