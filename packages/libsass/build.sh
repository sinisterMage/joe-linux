# The book builds libsass and sassc on one page (general/sassc), installing
# the library before compiling the program. Staged installs cannot do that,
# so the library is a recipe of its own and sassc depends on it.

build() {
    # version.sh asks git for the version and falls back to "[na]"; the
    # archive is not a checkout.
    export LIBSASS_VERSION="$PKG_VERSION"
    autoreconf -fi
    ./configure --prefix=/usr --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
