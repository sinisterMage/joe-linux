# Not in the book: the newest upstream release, built as its INSTALL says.
prepare() {
    # The release ships Automake's 2016 py-compile, which imports the imp
    # module Python 3.12 removed; use the installed Automake's current one.
    cp /usr/share/automake-*/py-compile py-compile
}

build() {
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --with-python=python3 \
        --disable-installed-tests
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
