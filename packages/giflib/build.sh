build() {
    make
}

package() {
    # The book runs "make install" and then deletes the static library; the
    # targets are named here instead, leaving out the static library and
    # the HTML documentation (whose installation would call xmlto).
    make PREFIX=/usr DESTDIR="$DESTDIR" \
        install-bin install-include install-shared-lib install-man
}
