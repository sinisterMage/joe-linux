# The book builds glib without introspection and installs it, builds and
# installs gobject-introspection against that glib, then turns introspection
# on in the same glib build tree and installs glib again.
#
# Nothing may be installed into the build root here, so the first glib and
# gobject-introspection are installed into a private staging directory and
# found there through pkg-config files whose prefix points into it.
# g-ir-scanner locates its own modules relative to where it is run from, so
# it works from the staging directory unchanged.
_gi_version=1.86.0

_stage_env() {
    _stage="$PWD/stage"
    _stage_pc="$PWD/stage-pc"
    export PKG_CONFIG_PATH="$_stage_pc"
    export LD_LIBRARY_PATH="$_stage/usr/lib"
    export PATH="$_stage/usr/bin:$PATH"
}

# Copies the staged pkg-config files to $_stage_pc with their prefix moved
# into the staging directory.
_stage_pc_refresh() {
    local f
    mkdir -p "$_stage_pc"
    for f in "$_stage"/usr/lib/pkgconfig/*.pc; do
        sed "s|^prefix=/usr\$|prefix=$_stage/usr|" "$f" > "$_stage_pc/${f##*/}"
    done
}

prepare() {
    mkdir gobject-introspection
    tar -xf "$SOURCES/gobject-introspection-$_gi_version.tar.xz" -C gobject-introspection \
        --strip-components=1 --no-same-owner --no-same-permissions
}

build() {
    _stage_env
    mkdir -p "$_stage_pc"

    # First pass: glib without introspection. No libselinux, no sysprof and
    # no dtrace/systemtap in joe Linux; libmount and libelf are in the base
    # system.
    meson setup build \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=disabled \
        -D glib_debug=disabled \
        -D man-pages=enabled \
        -D sysprof=disabled \
        -D selinux=disabled \
        -D libmount=enabled \
        -D libelf=enabled \
        -D dtrace=disabled \
        -D systemtap=disabled \
        -D documentation=false \
        -D tests=false \
        -D installed_tests=false
    ninja -C build
    DESTDIR="$_stage" ninja -C build install
    _stage_pc_refresh

    # gobject-introspection against the staged glib. cairo depends on glib,
    # so it cannot be used here (it only matters to the tests); g-ir-doc-tool
    # needs the Markdown module, which has no recipe.
    meson setup gobject-introspection gi-build \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D cairo=disabled \
        -D doctool=disabled \
        -D gtk_doc=false \
        -D tests=false
    ninja -C gi-build
    DESTDIR="$_stage" ninja -C gi-build install
    _stage_pc_refresh

    # Second pass: the same glib build tree, now generating GLib-2.0.gir and
    # friends with the staged g-ir-scanner.
    meson configure build -D introspection=enabled
    ninja -C build
}

package() {
    _stage_env
    DESTDIR="$DESTDIR" ninja -C gi-build install
    DESTDIR="$DESTDIR" ninja -C build install

    # GSettings schemas and GIO modules are compiled into caches that must
    # follow every change to their directories.
    install -d "$DESTDIR/usr/share/glib-2.0/schemas" "$DESTDIR/usr/lib/gio/modules"
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/30-glib-schemas.zon" <<'EOT'
.{
    .name = "GSettings schema cache",
    .paths = .{"usr/share/glib-2.0/schemas/"},
    .exec = .{ "/usr/bin/glib-compile-schemas", "/usr/share/glib-2.0/schemas" },
}
EOT
    cat > "$DESTDIR/usr/lib/dave/triggers/31-gio-modules.zon" <<'EOT'
.{
    .name = "GIO module cache",
    .paths = .{"usr/lib/gio/modules/"},
    .exec = .{ "/usr/bin/gio-querymodules", "/usr/lib/gio/modules" },
}
EOT
}
