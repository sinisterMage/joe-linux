build() {
    # The tarball has no configure script. The manual page needs sphinx and
    # is not built.
    sh autogen.sh
    ./configure --prefix=/usr --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
