build() {
    # libXdmcp is found by pkg-config and used for XDM-AUTHORIZATION-1 (Mesa needs
    # libxcb built with it). No doxygen: no API documentation.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir='${datadir}'/doc/libxcb-$PKG_VERSION \
        --without-doxygen
    LC_ALL=en_US.UTF-8 make
}

package() {
    make DESTDIR="$DESTDIR" install
}
