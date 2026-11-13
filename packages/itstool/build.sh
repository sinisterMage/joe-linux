prepare() {
    patch -Np1 -i "$SOURCES/itstool-2.0.7-lxml-1.patch"
}

build() {
    PYTHON=/usr/bin/python3 ./autogen.sh --prefix=/usr
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
