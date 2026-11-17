# Following the book's seahorse page.
prepare() {
    # gpgme 2 no longer has the trust-item event.
    sed -i "/GPGME_EVENT_NEXT_TRUSTITEM/d" pgp/seahorse-gpgme.c
    # Settings schemas under /org/gnome/, as the book does.
    sed -i -r 's:"(/apps):"/org/gnome\1:' data/*.xml
}

build() {
    mkdir build
    cd build
    # The book uses the defaults, stated here. Options it leaves at their
    # defaults that have recipes here are turned on: key-sharing (Avahi,
    # which the book lists as optional) and the manual page (xsltproc and
    # the installed DocBook stylesheets).
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D help=true \
        -D pgp-support=true \
        -D check-compatible-gpg=true \
        -D pkcs11-support=true \
        -D keyservers-support=true \
        -D hkp-support=true \
        -D ldap-support=true \
        -D key-sharing=true \
        -D manpage=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
