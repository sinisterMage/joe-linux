# Not in the book: the newest upstream release, built as its README says
# (the release tarball carries a generated configure).
build() {
    # inotify lets clients notice usbmuxd's socket appearing.
    ./configure --prefix=/usr --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
