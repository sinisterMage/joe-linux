build() {
    ./configure --prefix=/usr \
        --without-bash-malloc \
        --with-installed-readline \
        --docdir=/usr/share/doc/bash-5.3
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # bash is the system's /bin/sh.
    ln -sf bash "$DESTDIR/usr/bin/sh"
}
