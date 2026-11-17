# Not in the book: the newest release of Anthy Unicode, built with meson as
# its INSTALL says. Anthy itself has been unmaintained since 2009; Anthy
# Unicode (libanthy-unicode, anthy-unicode.pc) works in UTF-8 and keeps the
# user's dictionary in $XDG_CONFIG_HOME/anthy. ibus-anthy prefers it, as
# Fedora and Arch build it.
prepare() {
    # meson.build makes the version from the date of the build; use the
    # release's.
    sed -i "s/'1.0.0.@0@'.format(run_command('date', '+%Y%m%d',/'$PKG_VERSION',/;/^ *check: true).stdout().strip()),/d" meson.build
    grep -q "version: '$PKG_VERSION'," meson.build
}

build() {
    # Emacs is not packaged: its Lisp files are installed, uncompiled, as
    # upstream does without Emacs.
    meson setup build \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D emacs=disabled
    ninja -C build
}

package() {
    # The library, the dictionary (/usr/share/anthy-unicode/anthy.dic),
    # the dictionary tools and /etc/anthy-unicode.conf.
    DESTDIR="$DESTDIR" ninja -C build install
}
