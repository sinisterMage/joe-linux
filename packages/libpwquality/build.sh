build() {
    # The Python module (a wheel built with pip in the book) is not built.
    ./configure --prefix=/usr \
        --disable-static \
        --enable-pam \
        --with-securedir=/usr/lib/security \
        --disable-python-bindings
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # The book goes on to put pam_pwquality.so into
    # /etc/pam.d/system-password. That file belongs to linux-pam, so the
    # module is installed but not switched on here.
}
