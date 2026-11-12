prepare() {
    # Keep 64-bit libraries in /usr/lib instead of /usr/lib64.
    case $(uname -m) in
        x86_64)
            sed -e '/m64=/s/lib64/lib/' \
                -i.orig gcc/config/i386/t-linux64
            ;;
    esac
}

build() {
    mkdir -v build
    (
        cd build
        # LD=ld: use the ld of the binutils package, found through PATH.
        ../configure --prefix=/usr \
            LD=ld \
            --enable-languages=c,c++ \
            --enable-default-pie \
            --enable-default-ssp \
            --enable-host-pie \
            --enable-targets=all \
            --disable-multilib \
            --disable-bootstrap \
            --disable-fixincludes \
            --with-system-zlib
        make
    )
}

package() {
    make -C build DESTDIR="$DESTDIR" install

    # Required by the FHS for historical reasons.
    ln -sv ../bin/cpp "$DESTDIR/usr/lib/cpp"

    # Many packages call the C compiler cc.
    ln -sv gcc "$DESTDIR/usr/bin/cc"
    ln -sv gcc.1 "$DESTDIR/usr/share/man/man1/cc.1"

    # Let ar, nm and ranlib of binutils find the link-time optimisation plugin.
    local plugin
    plugin=$(find "$DESTDIR/usr/libexec/gcc" -name liblto_plugin.so)
    [[ -f $plugin ]]
    install -dv "$DESTDIR/usr/lib/bfd-plugins"
    ln -sfvr "$plugin" "$DESTDIR/usr/lib/bfd-plugins/"

    # The gdb pretty-printer loader does not belong among the libraries.
    mkdir -pv "$DESTDIR/usr/share/gdb/auto-load/usr/lib"
    mv -v "$DESTDIR"/usr/lib/*gdb.py "$DESTDIR/usr/share/gdb/auto-load/usr/lib"
}
