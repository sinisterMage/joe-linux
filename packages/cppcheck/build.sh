# Not in the book: the newest upstream release, built with CMake as
# readme.md describes.
build() {
    # No Qt GUI or triage tool, no rule files (they need PCRE), no tests.
    # FILESDIR: where cppcheck finds its cfg, platforms and addons.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D FILESDIR=/usr/share/cppcheck \
        -D BUILD_CLI=ON \
        -D BUILD_GUI=OFF \
        -D BUILD_TRIAGE=OFF \
        -D BUILD_ONLINE_HELP=OFF \
        -D BUILD_TESTS=OFF \
        -D HAVE_RULES=OFF \
        -D USE_MATCHCOMPILER=On \
        -D USE_BOOST=On \
        -D USE_BUNDLED_TINYXML2=ON \
        -D BUILD_MANPAGE=OFF
    ninja -C build

    # The manual page, as upstream's "make man" makes it (cppcheck.1 in
    # this directory); the stylesheet is found through the XML catalog.
    xsltproc --nonet --param man.charmap.use.subset 0 \
        http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl \
        man/cppcheck.1.xml
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
    install -Dm644 cppcheck.1 "$DESTDIR/usr/share/man/man1/cppcheck.1"
}
