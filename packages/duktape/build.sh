prepare() {
    sed -i 's/-Os/-O2/' Makefile.sharedlibrary
}

build() {
    make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr
}

package() {
    make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr DESTDIR="$DESTDIR" install
}
