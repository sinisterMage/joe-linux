# Not in the book: the newest upstream release, built with CMake as its
# README and Makefile ("make release") build it.
build() {
    # The release archive has no .git, so the version and commit that
    # upstream's build reads from git are given: the shell reports them, and
    # the version names the directory of extensions.duckdb.org that INSTALL
    # downloads extensions from at run time. The commit is the one tag
    # v2.0.0 points to.
    #
    # Extensions: only the ones in this source tree, all statically linked:
    # core_functions, parquet, json and icu (upstream's default set,
    # extension/extension_config.cmake) and autocomplete, the shell's tab
    # completion, which upstream's own release builds link too. Nothing is
    # fetched while building; out-of-tree extensions (httpfs, fts, ...) are
    # not built. The capabilities are those of upstream's release builds:
    # its HTTP client and loading extensions at run time.
    #
    # SET_DUCKDB_LIBRARY_VERSION gives libduckdb a versioned soname
    # (libduckdb.so.2.0) rather than none. The unit tests and benchmarks
    # are not built.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D DUCKDB_EXPLICIT_VERSION=v2.0.0 \
        -D GIT_COMMIT_HASH=d54cbbe3df17e8e5ce68312f483b4155836112aa \
        -D BUILD_EXTENSIONS=autocomplete \
        -D LINK_CORE_EXTENSIONS=ON \
        -D DUCKDB_CAPABILITIES="httplib;loadable_extensions" \
        -D SET_DUCKDB_LIBRARY_VERSION=ON \
        -D BUILD_SHELL=ON \
        -D BUILD_UNITTESTS=OFF \
        -D BUILD_BENCHMARKS=OFF \
        -D ENABLE_SANITIZER=OFF \
        -D ENABLE_UBSAN=OFF \
        -D NATIVE_ARCH=OFF \
        -D TREAT_WARNINGS_AS_ERRORS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build

    # cmake --install also installs every static archive the build makes
    # (libduckdb_static.a, the bundled libraries, the extensions) and CMake
    # package files that name all those archives. Only the shell, libduckdb
    # and DuckDB's own headers are kept: programs link it with -lduckdb.
    rm "$DESTDIR"/usr/lib/*.a
    rm -r "$DESTDIR/usr/lib/cmake/DuckDB"
    rmdir "$DESTDIR/usr/lib/cmake" 2>/dev/null || true
    test -x "$DESTDIR/usr/bin/duckdb"
    test -e "$DESTDIR/usr/lib/libduckdb.so"
}
