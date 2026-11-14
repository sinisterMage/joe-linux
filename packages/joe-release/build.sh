# joe Linux releases are named J<X>-<Y>-<Z>[-<stage>] (README.md, "Releases"):
#
#   X      the system revision: this package's version, without its stage
#   Y      the kernel's version (packages/linux)
#   Z      dave's version (packages/dave and dave/src/main.zig)
#   stage  alpha1, beta1, rc1 ...; nothing for a final release
#
# Y and Z are written here, so this recipe changes (and its .release is
# bumped) whenever the kernel's or dave's version does. tests/vm/live.py
# checks them against the running kernel and dave.

# Prints the release's name; build machine scripts call it as well.
release_name() {
    local kernel=7.3.1 dave=0.2.0
    local revision=${PKG_VERSION%%[a-z]*}
    local stage=${PKG_VERSION#"$revision"}
    printf 'J%s-%s-%s%s\n' "$revision" "$kernel" "$dave" "${stage:+-$stage}"
}

package() {
    local name
    name=$(release_name)
    install -d "$DESTDIR/usr/lib" "$DESTDIR/etc"
    cat > "$DESTDIR/usr/lib/os-release" <<EOT
NAME="joe Linux"
ID=joe
PRETTY_NAME="joe Linux $name"
VERSION="$name"
VERSION_ID=$PKG_VERSION
BUILD_ID=$PKG_RELEASE
HOME_URL="https://github.com/sinisterMage/joe-linux"
EOT
    ln -s ../usr/lib/os-release "$DESTDIR/etc/os-release"
    printf 'joe Linux %s \\n \\l\n\n' "$name" > "$DESTDIR/etc/issue"
}
