# Not in the book: the newest upstream release, built as its README says
# (configure, make). lnav draws the screen with its own copy of notcurses,
# which reads terminfo itself, so ncurses is not used.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"

    # configure takes an absolute CARGO_CMD as given, and src/Makefile runs
    # "$(CARGO_CMD) build ..." for the Rust extension (PRQL queries,
    # log2src, :external-access); --locked builds exactly the crates in
    # upstream's Cargo.lock. Stated: libarchive (opening archives) and no
    # jemalloc (not packaged); bzip2 has no switch and is always found, as
    # it is a dependency. --disable-system-paths keeps configure from
    # adding /usr/local and lib64 search paths.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-system-paths \
        --with-libarchive \
        --without-jemalloc \
        CARGO_CMD="/usr/bin/cargo --locked"
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
