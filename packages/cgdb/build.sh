# Not in the book: the newest upstream release, built as its INSTALL says.
# configure picks the system's ncursesw and readline by itself; its
# --with-* options only add search paths.
prepare() {
    # configure's readline version test declares "main()" without a return
    # type, which GCC 14 and later reject, so the test fails and configure
    # reports readline as missing.
    sed -i 's/^main()$/int main(void)/' configure
    grep -q '^int main(void)$' configure
}

build() {
    ./configure --prefix=/usr
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
