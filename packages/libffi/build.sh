build() {
    # x86-64 rather than native: the package must run on any x86_64 CPU.
    # Without --disable-multi-os-directory the library can land in lib64.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-multi-os-directory \
        --with-gcc-arch=x86-64
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
