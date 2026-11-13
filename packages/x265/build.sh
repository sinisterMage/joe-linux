build() {
    mkdir bld
    cd bld
    # The book's options, plus: lib rather than lib64, assembly required
    # rather than detected, and no libnuma (no recipe).
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D LIB_INSTALL_DIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D GIT_ARCHETYPE=1 \
        -D ENABLE_ASSEMBLY=ON \
        -D ENABLE_LIBNUMA=OFF \
        -W no-author \
        ../source
    make
}

package() {
    cd bld
    make DESTDIR="$DESTDIR" install
    rm -f "$DESTDIR/usr/lib/libx265.a"
}
