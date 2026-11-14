# As the book's firmware page does: the sof* directories (firmware, and the
# topologies that describe each laptop's audio) into
# /usr/lib/firmware/intel. Upstream's install.sh does the same with rsync.
NOSTRIP=1

package() {
    install -d "$DESTDIR/usr/lib/firmware/intel"
    cp -a sof* "$DESTDIR/usr/lib/firmware/intel/"
    if [[ -d tools ]]; then
        install -d "$DESTDIR/usr/bin"
        cp -a tools/. "$DESTDIR/usr/bin/"
    fi
    install -Dm644 -t "$DESTDIR/usr/share/licenses/sof-firmware" LICENCE.*
}
