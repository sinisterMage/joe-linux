# Not in the book: the newest upstream release, built as its README says.
prepare() {
    # configure forces C++11 (-std=gnu++11), but the Protocol Buffers
    # headers need C++17 and the Abseil headers they include C++20 (its
    # targets require cxx_std_20). Arch Linux changes the request in
    # configure.ac to 17 and regenerates; here the same line of the
    # generated configure asks for C++20.
    sed -i 's/ax_cxx_compile_alternatives="11 0x"/ax_cxx_compile_alternatives="20 2a"/' configure
    grep -q 'ax_cxx_compile_alternatives="20 2a"' configure
}

build() {
    # OpenSSL's AES-OCB, ncurses' terminfo. The bash completion and the
    # ufw application profile (/etc/ufw/applications.d/mosh) are
    # installed. libutempter, which would record sessions in utmp, is not
    # packaged.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --with-crypto-library=openssl \
        --without-utempter \
        --enable-completion \
        --enable-ufw \
        --disable-syslog \
        --disable-examples
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
