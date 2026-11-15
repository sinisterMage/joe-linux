prepare() {
    # As in the book: keep the install from writing per-module file lists
    # (only packagers splitting LibreOffice use them), and leave the manual
    # pages uncompressed.
    sed -i "/distro-install-file-lists/d" Makefile.in
    sed -e "/gzip -f/d" \
        -e "s|.1.gz|.1|g" \
        -i bin/distro-install-desktop-integration
}

# The Makefile refuses to run as root unless it is in a container, which it
# recognises by $container. The build runs as root only inside its user
# namespace. TMPDIR: the installer stages a full copy of the suite there, too
# much for the /tmp tmpfs.
_lo_env() {
    export container=dave-build
    export TMPDIR=/build/lo-tmp
    mkdir -p "$TMPDIR"
}

build() {
    _lo_env

    # configure reads Python's include and library flags through distutils,
    # which Python 3.12 removed; it takes them from the environment instead.
    export PYTHON_CFLAGS="$(pkg-config --cflags python3-embed)"
    export PYTHON_LIBS="$(pkg-config --libs python3-embed)"

    # The book's configuration, adapted:
    # - Offline: --disable-fetch-external, and every external tarball the
    #   build unpacks is a source of this recipe, found in $SOURCES.
    # - en-US only, no local help (the help and translations tarballs are not
    #   sources), no Java (so no HSQLDB, report builder, BeanShell or Rhino
    #   scripting, and nothing for --without-junit to do), no SDK.
    # - Spelling uses the system's Hunspell dictionaries (hunspell-en) instead
    #   of the book's bundled dictionaries tarball; hyphenation patterns and
    #   thesauri would be read from /usr/share/hyphen and /usr/share/mythes.
    # - --without-fonts: the bundled fonts (DejaVu, Liberation, Noto, ...)
    #   come from joe's font packages instead. Carlito and Caladea, the
    #   metric-compatible stand-ins for Calibri and Cambria, are not packaged
    #   yet, so those fonts fall back to whatever fontconfig picks.
    # - System libraries wherever joe has a recipe (the book's list, plus
    #   Abseil, Argon2, OpenJPEG, fast_float, Hunspell and the SANE and BlueZ
    #   headers). Not system: HarfBuzz and Graphite (joe's harfbuzz has no
    #   Graphite support, and system HarfBuzz requires it), CLucene, GLM,
    #   gpgmepp, Redland and the rest of the sources above, which configure
    #   bundles by default. OpenLDAP has no recipe: --disable-ldap.
    # - Firebird is not built (--disable-firebird-sdbc) and there is no Java
    #   for HSQLDB, so Base has no embedded database engine; it still opens
    #   PostgreSQL servers, ODBC data sources, spreadsheets and dBASE or CSV
    #   files. MariaDB is off, as in the book.
    # - GTK 3 backend (the one LibreOffice picks under GNOME) plus the
    #   generic X11 one. The GTK 4 backend is never chosen automatically and
    #   is left out, as in the book. No Qt or KDE.
    # - dconf (system-wide defaults) and Avahi (the Impress remote) are on,
    #   since both exist here; Evolution address books are off.
    # - Things configure would otherwise pick up from whatever is in the
    #   build root are stated: no ccache, no valgrind headers, no coredumpctl
    #   test support, no AT-SPI tests.
    ./autogen.sh --prefix=/usr \
        --libdir=/usr/lib \
        --sysconfdir=/etc \
        --with-vendor="joe Linux" \
        --with-lang=en-US \
        --without-help \
        --without-myspell-dicts \
        --with-system-dicts \
        --with-external-dict-dir=/usr/share/hunspell \
        --without-fonts \
        --without-java \
        --without-junit \
        --disable-odk \
        --disable-mariadb-sdbc \
        --disable-firebird-sdbc \
        --disable-ldap \
        --enable-release-build=yes \
        --enable-python=system \
        --enable-gtk3 \
        --disable-gtk4 \
        --enable-dconf \
        --enable-avahi \
        --disable-fetch-external \
        --with-external-tar="$SOURCES" \
        --with-parallelism="$JOBS" \
        --disable-ccache \
        --without-valgrind \
        --without-coredumpctl \
        --disable-atspi-tests \
        --with-system-abseil \
        --with-system-argon2 \
        --with-system-bluez \
        --with-system-boost \
        --with-system-cairo \
        --with-system-curl \
        --with-system-epoxy \
        --with-system-expat \
        --with-system-fast-float \
        --with-system-hunspell \
        --with-system-icu \
        --with-system-jpeg \
        --with-system-lcms2 \
        --with-system-libpng \
        --with-system-libtiff \
        --with-system-libwebp \
        --with-system-libxml \
        --with-system-nss \
        --with-system-openjpeg \
        --with-system-openssl \
        --with-system-poppler \
        --with-system-postgresql \
        --with-system-sane \
        --with-system-zlib \
        --with-system-zstd
    # The build environment exports DESTDIR, and LibreOffice's build step
    # already installs into $(DESTDIR)/instdir (its gdb pretty-printers):
    # build into the source tree, as LibreOffice expects.
    env -u DESTDIR make build
}

package() {
    _lo_env
    make distro-pack-install

    # The installer's lists of files per module, written at the top of
    # DESTDIR for packagers that split the suite; nothing here uses them.
    rm -f "$DESTDIR"/gid_*
}
