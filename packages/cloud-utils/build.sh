# Not in the book: the newest upstream release, installed with its Makefile.
prepare() {
    # cloud-localds makes the NoCloud seed ISO with genisoimage, which is
    # not packaged; xorrisofs takes the same options (-output, -volid,
    # -joliet, -rock).
    sed -i 's/genisoimage/xorrisofs/g' bin/cloud-localds
}

package() {
    make DESTDIR="$DESTDIR" install
}
