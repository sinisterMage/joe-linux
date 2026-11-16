# Not in the book: the newest upstream release (from 2020). shunit2 is a
# single shell file with no build system. It goes in /usr/bin, where other
# distributions put it too, so that a test script's ". shunit2" finds it on
# PATH (upstream's examples source a copy next to the script instead).
package() {
    install -Dm755 shunit2 "$DESTDIR/usr/bin/shunit2"
}
