# Stripped by package() below rather than by the build driver, so that the
# dynamic linker keeps its symbol table.
NOSTRIP=1

prepare() {
    patch -Np1 -i "$SOURCES/glibc-fhs-1.patch"
    patch -Np1 -i "$SOURCES/glibc-2.44-upstream_fixes-4.patch"
}

build() {
    mkdir build
    cd build
    echo "rootsbindir=/usr/sbin" > configparms
    ../configure --prefix=/usr \
        --disable-werror \
        --disable-nscd \
        libc_cv_slibdir=/usr/lib \
        --enable-stack-protector=strong \
        --enable-kernel=5.10
    make
}

package() {
    cd build
    # The installation self-test would run against the build root, not $DESTDIR.
    sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
    sed '/RTLDLIST=/s@/usr@@g' -i elf/ldd
    make DESTDIR="$DESTDIR" install

    # Only the locales every system needs; more can become a separate package.
    make DESTDIR="$DESTDIR" localedata/install-locale-files \
        SUPPORTED-LOCALES="C.UTF-8/UTF-8 en_US.UTF-8/UTF-8"

    install -d "$DESTDIR/etc/ld.so.conf.d"
    cat > "$DESTDIR/etc/ld.so.conf" <<'EOT'
/usr/local/lib
/opt/lib
include /etc/ld.so.conf.d/*.conf
EOT
    cat > "$DESTDIR/etc/nsswitch.conf" <<'EOT'
passwd: files systemd
group: files systemd
shadow: files systemd

hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
networks: files

protocols: files
services: files
ethers: files
rpc: files
EOT

    # The time zone data is the tzdata package.

    # The dynamic linker cache follows every change to the library directories.
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/10-ldconfig.zon" <<'EOT'
.{
    .name = "dynamic linker cache",
    .paths = .{ "usr/lib/", "usr/local/lib/", "etc/ld.so.conf" },
    .exec = .{"/usr/sbin/ldconfig"},
}
EOT

    # What the build driver would do, except that ld-linux-x86-64.so.2 loses
    # only its debugging information: valgrind's Memcheck needs the dynamic
    # linker's symbol table to replace strlen and friends in it, or it
    # reports errors that are not there (LFS keeps it for the same reason).
    local f
    while IFS= read -r -d '' f; do
        if [[ $(head -c 4 "$f" | od -An -c | tr -d ' ') != '177ELF' ]]; then
            [[ $f != *.a ]] || strip --strip-debug "$f" 2>/dev/null || true
            continue
        fi
        case $f in
            */ld-linux-x86-64.so.2 | *.o) strip --strip-debug "$f" 2>/dev/null || true ;;
            *) strip --strip-unneeded "$f" 2>/dev/null || true ;;
        esac
    done < <(find "$DESTDIR" -type f -print0)
}
