# dave is a static binary with no libc, cross-built by Zig on the build host,
# because joe does not package a Zig compiler yet. bootstrap/build-packages.sh
# places the binary and the unit files from system/ in this recipe's files/
# directory before the build.
NOSTRIP=1

package() {
    local units="$DESTDIR/usr/lib/systemd/system"
    install -Dm755 /recipe/files/dave "$DESTDIR/usr/bin/dave"
    install -Dm644 /recipe/files/dave-boot-check.service "$units/dave-boot-check.service"
    install -Dm644 /recipe/files/dave-finalize.service "$units/dave-finalize.service"
    install -Dm644 /recipe/files/boot-complete-dave.conf "$units/boot-complete.target.d/10-dave.conf"

    # The units are enabled by shipping the links: there are no install scripts.
    install -d "$units/boot-complete.target.requires" "$units/multi-user.target.wants"
    ln -s ../dave-boot-check.service "$units/boot-complete.target.requires/dave-boot-check.service"
    ln -s ../dave-finalize.service "$units/multi-user.target.wants/dave-finalize.service"

    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    echo 'd /var/cache/dave 0755 root root -' > "$DESTDIR/usr/lib/tmpfiles.d/dave.conf"
}
