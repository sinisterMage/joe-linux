# Not in the book: upstream's last release, with Debian's patches and built
# the way Debian builds it (debian/rules).
prepare() {
    tar -xf "$SOURCES/iftop_1.0pre4-10.debian.tar.xz"
    local p
    while read -r p; do
        [[ -z $p || $p == \#* ]] && continue
        patch -Np1 -i "debian/patches/$p"
    done < debian/patches/series
    # The configure script dates from 2014 (Autoconf 2.69); regenerate it
    # with the current Autotools, as Debian does.
    autoreconf -fi
}

build() {
    # Debian's flags: name resolution with getnameinfo (which handles IPv6),
    # interface addresses with getifaddrs, no "!" shell escape (iftop runs as
    # root), and -fcommon for the variables defined in more than one file.
    ./configure --prefix=/usr \
        --sbindir=/usr/sbin \
        CFLAGS="-O2 -Wall -fcommon -DNO_SYSTEM -DUSE_GETNAMEINFO=1 -DUSE_GETIFADDRS=1"
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
