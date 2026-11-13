prepare() {
    sed -i 's/python/&3/' event_rpcgen.py
}

build() {
    ./configure --prefix=/usr --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
