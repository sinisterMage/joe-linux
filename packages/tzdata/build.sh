# The time zone data that LFS installs on its glibc page, compiled the same
# way (with glibc's zic) but packaged on its own, so that a new release of the
# rules does not mean rebuilding the C library. Keep the layout exactly as
# glibc made it: posix/ and right/ are directories, not links.

unpack() {
    tar -xf "$SOURCES/$PKG_SOURCE" --no-same-owner --no-same-permissions
}

package() {
    local zoneinfo="$DESTDIR/usr/share/zoneinfo" tz
    mkdir -p "$zoneinfo"/{posix,right}
    for tz in etcetera southamerica northamerica europe africa antarctica asia australasia backward; do
        zic -L /dev/null -d "$zoneinfo" "$tz"
        zic -L /dev/null -d "$zoneinfo/posix" "$tz"
        zic -L leapseconds -d "$zoneinfo/right" "$tz"
    done
    cp zone.tab zone1970.tab iso3166.tab "$zoneinfo"
    zic -d "$zoneinfo" -p America/New_York
}
