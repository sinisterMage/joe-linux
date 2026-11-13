prepare() {
    # Fixes a warning caused by perl-5.22 and later.
    sed -i 's:\\\${:\\\$\\{:' intltool-update.in
}

build() {
    ./configure --prefix=/usr
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
