# Not in the book: the setuptools project in py/ of the nftables release,
# which the nftables recipe leaves out; distributions package it on its own
# (python-nftables in Arch Linux, python3-nftables in Fedora).
build() {
    cd py
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    cd py
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist nftables
}
