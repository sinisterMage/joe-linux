prepare() {
    # Compatibility with gcc 15 and later.
    sed -i '/long long t1;/,+1s/()/(...)/' configure
}

build() {
    # --host=none-linux-gnu: by default GMP is tuned for, and may only run on,
    # the processor of the machine it is built on. A package has to run
    # anywhere, so build the generic code (the option LFS gives for this).
    ./configure --prefix=/usr \
        --enable-cxx \
        --disable-static \
        --docdir=/usr/share/doc/gmp-6.3.0 \
        --host=none-linux-gnu
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
