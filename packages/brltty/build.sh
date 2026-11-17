# Not in the book: the newest upstream release, built as its README says,
# with the layout other distributions use (tables in /usr/share/brltty).
prepare() {
    patch -Np1 -i /recipe/flat-curses-headers.patch
    # joe uses PipeWire, which has no pulse-access group; a supplementary
    # group that does not exist would stop the service from starting.
    sed -i '/pulse-access/d;/Pulse Audio/d' Autostart/Systemd/brltty@.service.in
}

build() {
    # Switched off:
    # - X11 (--disable-x): xbrlapi, the XWindow virtual display and the
    #   AT-SPI 2 screen reader driver work only in X sessions. In GNOME on
    #   Wayland, Orca drives the display through BrlAPI.
    # - GPM, Libbraille, and the speech engines without recipes (eSpeak,
    #   which eSpeak NG's compatibility header would make configure think
    #   is installed; Flite, Mikropuhe, Swift, Theta).
    # - The FileViewer screen driver (-fv), which links libtinfo, a library
    #   joe's ncurses does not build separately.
    # - Bindings other than Python's: Orca needs only those (brlapi).
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --libdir=/usr/lib \
        --mandir=/usr/share/man \
        --with-tables-directory=/usr/share/brltty \
        --with-writable-directory=/run/brltty \
        --with-updatable-directory=/var/lib/brltty \
        --with-curses=ncursesw \
        --with-screen-driver=-fv \
        --with-espeak_ng \
        --with-speechd \
        --without-espeak \
        --without-flite \
        --without-mikropuhe \
        --without-swift \
        --without-theta \
        --without-libbraille \
        --enable-i18n \
        --enable-icu \
        --enable-iconv \
        --enable-polkit \
        --enable-expat \
        --enable-liblouis \
        --enable-speech-support \
        --enable-python-bindings \
        --disable-x \
        --disable-gpm \
        --disable-emacs-bindings \
        --disable-java-bindings \
        --disable-lisp-bindings \
        --disable-lua-bindings \
        --disable-ocaml-bindings \
        --disable-tcl-bindings \
        --disable-stripping \
        PYTHON=python3
    make
}

package() {
    # brltty installs into INSTALL_ROOT rather than DESTDIR. "install"
    # covers the programs, drivers, tables, translations, headers, BrlAPI
    # and its Python module (setup.py install --root).
    make INSTALL_ROOT="$DESTDIR" install install-appstream install-polkit install-systemd

    # The udev rules that start brltty (brltty-device@.service) when a
    # braille display is plugged in, and that let the brltty user open
    # HID braille devices, uinput and the PC speaker. Upstream's
    # usb-generic rules, which match common USB-to-serial adapters that
    # are also used by much else (Arduino boards and the like), are left
    # out, as Fedora leaves them out of its main package.
    make -C Autostart/Udev INSTALL_ROOT="$DESTDIR" install-wrapper \
        install-rules-beeper install-rules-hid install-rules-uinput install-rules-usb-customized

    # The example configuration, every setting commented out. brltty.path
    # starts the default instance when /etc/brltty.conf exists, but none
    # of the units is enabled: the udev rules above start brltty for a
    # display that is plugged in.
    install -Dm644 Documents/brltty.conf "$DESTDIR/etc/brltty.conf"

    # The account brltty runs as, with fixed ids. Upstream's sysusers file
    # gives none. BrlAPI clients are authorized by Polkit (the active
    # session) or by membership of the brlapi group; brltty-genkey makes
    # the optional key file /etc/brlapi.key. The supplementary groups are
    # those of brltty@.service. The tmpfiles.d file is upstream's: /run/brltty,
    # /var/lib/brltty and BrlAPI's socket directory /var/lib/BrlAPI.
    cat > "$DESTDIR/usr/lib/sysusers.d/brltty.conf" << "EOF2"
g brltty 90
u brltty 90:90 "Braille Device Daemon" /var/lib/brltty
g brlapi 91
m brltty tty
m brltty dialout
m brltty root
m brltty audio
m brltty input
m brltty brlapi
EOF2
}
