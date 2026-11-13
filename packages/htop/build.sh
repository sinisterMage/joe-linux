# Not in the book: the newest upstream release, built as its README says.
build() {
    # Left out because joe does not package what they need: delay accounting
    # (libnl), temperatures (lm-sensors), hwloc, and backtraces of other
    # processes (libunwind).
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --enable-unicode \
        --enable-affinity \
        --enable-capabilities \
        --disable-delayacct \
        --disable-sensors \
        --disable-hwloc \
        --disable-backtrace \
        --without-libunwind \
        --disable-pcp \
        --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
