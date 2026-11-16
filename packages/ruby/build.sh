# Following the book's Ruby page, without its C API documentation (make
# capi) and with no ri/RDoc documentation generated or installed. The gems
# that come with Ruby are installed under /usr/lib/ruby/gems/4.0.0.
build() {
    # The book's options, plus:
    # - YJIT, the JIT compiler, said explicitly (configure turns it on by
    #   itself when it finds rustc). ZJIT, the experimental one, off.
    # - No ri and HTML documentation (--disable-install-doc).
    # - DTrace off: systemtap's sdt.h is not packaged.
    # GMP is used when found and has a recipe; jemalloc is not used unless
    # asked for.
    ./configure --prefix=/usr \
        --disable-rpath \
        --enable-shared \
        --without-valgrind \
        --without-baseruby \
        ac_cv_func_qsort_r=no \
        --docdir=/usr/share/doc/ruby-4.0.9 \
        --enable-yjit \
        --disable-zjit \
        --disable-install-doc \
        --disable-dtrace \
        --with-gmp \
        --without-jemalloc
    make
}

package() {
    # The book points XDG_DATA_HOME away from root's home for the install,
    # which would otherwise leave files there; here into the build tree.
    XDG_DATA_HOME="$PWD/.xdg-data" make DESTDIR="$DESTDIR" install
}
