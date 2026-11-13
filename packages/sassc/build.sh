# Second half of the book's general/sassc page; the first half is the
# libsass recipe.

build() {
    # version.sh asks git for the version and falls back to "[na]"; the
    # archive is not a checkout.
    export SASSC_VERSION="$PKG_VERSION"
    autoreconf -fi
    ./configure --prefix=/usr
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
