# The kernel loads the database as firmware and checks its signature against
# the keys of its maintainers, which it ships (CFG80211_USE_KERNEL_REGDB_KEYS).
package() {
    install -Dm644 -t "$DESTDIR/usr/lib/firmware" regulatory.db regulatory.db.p7s
    install -Dm644 LICENSE "$DESTDIR/usr/share/licenses/wireless-regdb/LICENSE"
}
