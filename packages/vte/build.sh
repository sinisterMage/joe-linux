build() {
    mkdir build
    cd build
    # gnutls is on by default; its option is deprecated and not passed.
    # glade: a catalogue for the Glade designer, which does not exist here.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D gtk3=true \
        -D gtk4=true \
        -D fribidi=true \
        -D icu=true \
        -D _systemd=true \
        -D a11y=true \
        -D gir=true \
        -D vapi=true \
        -D glade=false \
        -D docs=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # As in the book: the profile scripts have no use here.
    rm -v "$DESTDIR"/etc/profile.d/vte.*
}
