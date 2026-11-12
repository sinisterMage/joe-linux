build() {
    make mrproper
    make headers
    find usr/include -type f ! -name '*.h' -delete
}

package() {
    install -d "$DESTDIR/usr"
    cp -r usr/include "$DESTDIR/usr"
}
