prepare() {
    patch -Np1 -i "$SOURCES/protobuf-c-1.5.2-protobuf34_fix-1.patch"
}

build() {
    # The generator uses the system Protobuf and Abseil; rsyslog's native
    # statistics push support generates its wire messages at build time.
    CXXFLAGS="${CXXFLAGS:--O2 -g} -std=c++20" \
        ./configure --prefix=/usr --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
