prepare() {
    # Never choose lib64 for the packages cmake configures.
    sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake
}

build() {
    # --system-libs: curl, libarchive, libuv, nghttp2, expat, zlib, bzip2,
    # liblzma and zstd come from the system; jsoncpp, cppdap and librhash do
    # not exist here and are built from the bundled copies. ccmake is built
    # because ncurses is there.
    ./bootstrap --prefix=/usr \
        --system-libs \
        --mandir=/share/man \
        --no-system-jsoncpp \
        --no-system-cppdap \
        --no-system-librhash \
        --docdir=/share/doc/cmake-4.4.5
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
