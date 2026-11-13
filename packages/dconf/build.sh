# Only dconf itself: dconf-editor, the second half of the book's page, needs
# GTK 3 and libhandy.

build() {
    mkdir build
    cd build
    # No bash-completion in joe Linux. The unit directory is given so that
    # it does not depend on systemd.pc being found.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D bash_completion=false \
        -D man=true \
        -D vapi=true \
        -D gtk_doc=false \
        -D systemduserunitdir=/usr/lib/systemd/user
    ninja
}

package() {
    cd build
    # With DESTDIR set meson does not run gio-querymodules for the dconf
    # GSettings backend in usr/lib/gio/modules; glib's trigger does.
    DESTDIR="$DESTDIR" ninja install

    # System databases are compiled from the key files that packages (GDM)
    # and administrators put in /etc/dconf/db/NAME.d.
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/36-dconf.zon" <<'EOT'
.{
    .name = "dconf system databases",
    .paths = .{"etc/dconf/db/"},
    .exec = .{ "/usr/bin/dconf", "update" },
}
EOT
}
