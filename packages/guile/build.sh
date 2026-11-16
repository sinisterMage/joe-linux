# Following the book's Guile page, without its HTML and plain-text manuals
# (documentation-only steps).

# Compiled Scheme modules (.go under /usr/lib/guile) are ELF containers of
# Guile's own, not machine code, and strip damages them (Debian and Gentoo
# exclude them from stripping too). package() strips the real binaries
# itself, the way the driver would.
NOSTRIP=1

build() {
    ./configure --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/guile-3.0.11
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The book's change: GDB finds the helper for debugging Guile programs
    # in its auto-load directory, not next to the library.
    install -d "$DESTDIR/usr/share/gdb/auto-load/usr/lib"
    mv "$DESTDIR"/usr/lib/libguile-*-gdb.scm "$DESTDIR/usr/share/gdb/auto-load/usr/lib"

    # What the driver does for NOSTRIP-less packages, leaving out the .go
    # files: guile, libguile and the guile-readline extension.
    local f
    while IFS= read -r -d '' f; do
        [[ $(head -c 4 "$f" | od -An -c | tr -d ' ') == '177ELF' ]] || continue
        strip --strip-unneeded "$f"
    done < <(find "$DESTDIR" -type f ! -name '*.go' -print0)

    # Guile loads a compiled module only when it is not older than its
    # source (libguile/load.c, compiled_is_fresh); otherwise it compiles the
    # source again into ~/.cache for every user. dave writes files in path
    # order without keeping their times, so the sources in /usr/share/guile
    # end up newer than the .go files in /usr/lib/guile. This trigger makes
    # the compiled files the newer ones after every transaction that
    # touches either.
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/60-guile-ccache.zon" << "EOT"
.{
    .name = "Guile compiled modules newer than their sources",
    .paths = .{ "usr/lib/guile/", "usr/share/guile/" },
    .exec = .{ "/usr/bin/find", "/usr/lib/guile", "-name", "*.go", "-exec", "/usr/bin/touch", "-c", "{}", "+" },
}
EOT
}
