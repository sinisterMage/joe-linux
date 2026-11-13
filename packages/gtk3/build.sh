build() {
    mkdir build
    cd build
    # Everything optional is stated so that the build root cannot change the
    # result:
    # - print_backends: no CUPS here, so only "print to file" and lpr; this
    #   also leaves colord (used by the CUPS backend alone) out.
    # - cloudproviders, tracker3: libcloudproviders and tinysparql exist; the
    #   file chooser gains cloud locations and search.
    # - demos, examples, tests: not shipped. gtk-update-icon-cache,
    #   gtk-query-immodules-3.0, gtk-builder-tool, gtk-encode-symbolic-svg,
    #   gtk-launch and gtk-query-settings are not demos and are always built.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D x11_backend=true \
        -D wayland_backend=true \
        -D broadway_backend=true \
        -D xinerama=yes \
        -D print_backends=file,lpr \
        -D colord=no \
        -D cloudproviders=true \
        -D tracker3=true \
        -D profiler=false \
        -D introspection=true \
        -D man=true \
        -D gtk_doc=false \
        -D demos=false \
        -D examples=false \
        -D tests=false \
        -D installed_tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # The book runs gtk-query-immodules-3.0 --update-cache and
    # glib-compile-schemas here (the latter is glib's trigger). The icon
    # caches are rebuilt by this package because it owns gtk-update-icon-cache:
    # hicolor is where applications install their icons, Adwaita is the theme.
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/40-gtk-icon-cache-hicolor.zon" <<'EOT'
.{
    .name = "hicolor icon cache",
    .paths = .{"usr/share/icons/hicolor/"},
    .exec = .{ "/usr/bin/gtk-update-icon-cache", "-qtf", "/usr/share/icons/hicolor" },
}
EOT
    cat > "$DESTDIR/usr/lib/dave/triggers/41-gtk-icon-cache-adwaita.zon" <<'EOT'
.{
    .name = "Adwaita icon cache",
    .paths = .{"usr/share/icons/Adwaita/"},
    .exec = .{ "/usr/bin/gtk-update-icon-cache", "-qtf", "/usr/share/icons/Adwaita" },
}
EOT
    cat > "$DESTDIR/usr/lib/dave/triggers/42-gtk3-immodules.zon" <<'EOT'
.{
    .name = "GTK 3 input method module cache",
    .paths = .{"usr/lib/gtk-3.0/"},
    .exec = .{ "/usr/bin/gtk-query-immodules-3.0", "--update-cache" },
}
EOT
}
