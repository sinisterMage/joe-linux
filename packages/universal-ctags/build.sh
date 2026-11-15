# Not in the book: the newest upstream release, built as docs/autotools.rst
# describes. The manual pages come ready-made in the tarball.
build() {
    # etags links are not made: Emacs has its own etags.
    ./configure --prefix=/usr \
        --enable-xml \
        --enable-json \
        --enable-seccomp \
        --enable-yaml \
        --enable-pcre2 \
        --enable-iconv \
        --disable-etags
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
