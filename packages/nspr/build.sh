prepare() {
    cd nspr
    # Do not install two unneeded scripts, nor the static libraries.
    sed -i '/^RELEASE/s|^|#|' pr/src/misc/Makefile.in
    sed -i 's|$(LIBRARY) ||' config/rules.mk
}

build() {
    cd nspr
    ./configure --prefix=/usr \
        --with-mozilla \
        --with-pthreads \
        $([ $(uname -m) = x86_64 ] && echo --enable-64bit)
    make
}

package() {
    cd nspr
    make DESTDIR="$DESTDIR" install
}
