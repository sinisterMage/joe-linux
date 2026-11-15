# Not in the book: the newest release of bats-core, installed with its
# install.sh as README.md says. bats finds its libexec and lib files
# relative to its own location, so staging under $DESTDIR changes nothing.
package() {
    ./install.sh "$DESTDIR/usr" lib
}
