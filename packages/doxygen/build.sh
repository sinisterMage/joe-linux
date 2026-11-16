# Following the book's Doxygen page, without doxywizard: the Qt 6 front end
# would make every package that builds its documentation with Doxygen wait
# for (and run with) Qt. spdlog, fmt and SQLite are the copies bundled in
# deps/, as the book has it (use_sys_*=OFF). The libclang parser, the search
# tools (Xapian) and the manual (texlive) are off.
prepare() {
    grep -rl '^#!.*python$' | xargs sed -i '1s/python/&3/'
}

build() {
    mkdir -v build
    cd build
    cmake -G "Unix Makefiles" \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D build_wizard=OFF \
        -D build_search=OFF \
        -D build_doc=OFF \
        -D use_libclang=OFF \
        -D use_sys_spdlog=OFF \
        -D use_sys_fmt=OFF \
        -D use_sys_sqlite3=OFF \
        -W no-author ..
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
    install -Dm644 ../doc/doxygen.1 "$DESTDIR/usr/share/man/man1/doxygen.1"
}
