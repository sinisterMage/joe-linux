build() {
    # --disable-protoc: only the runtime library, libprotobuf-c, is built.
    # The code generator (protoc-gen-c) is a C++ program that needs Protobuf
    # and Abseil, neither of which exists here, and nothing needs it:
    # libshumate, the one user, ships its generated vector_tile.pb-c.[ch].
    # The book's protobuf34_fix patch only touches the generator, so it is
    # not applied, and its -std=c++20 has nothing to act on.
    ./configure --prefix=/usr --disable-static --disable-protoc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
