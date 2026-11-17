# Not in the book: the newest upstream release, built as its README says.
# Upstream publishes no checksum, only a detached signature: the tarball's
# signature by Timo Kokkonen (DSA key 9168CD7A2F0AAB0679D09BBA9D08A80CED908D6A)
# was checked before its SHA-256 was recorded. Curtail runs it.
build() {
    # --with-arith: libjpeg-turbo supports arithmetic coding.
    ./configure \
        --prefix=/usr \
        --mandir=/usr/share/man \
        --with-arith
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
