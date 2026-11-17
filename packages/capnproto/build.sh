# Not in the book: the newest upstream release, built with its configure
# script as capnproto.org's installation page says.
build() {
    # All libraries (kj, kj-async, kj-http, kj-tls, kj-gzip, capnp,
    # capnp-rpc, capnp-json, capnp-websocket, capnpc) and the capnp,
    # capnpc-c++ and capnpc-capnp programs, with the optional zlib, OpenSSL
    # and fibre (ucontext) support stated rather than detected.
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --disable-static \
        --with-zlib \
        --with-openssl \
        --with-fibers
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
