# Not in the book: the newest upstream release, built with CMake as its
# README says.
prepare() {
    mkdir .corrosion
    tar -xf "$SOURCES/corrosion-0.5.1.tar.gz" -C .corrosion --strip-components=1 --no-same-owner
    # Build exactly the crate versions in upstream's Cargo.lock.
    sed -i 's/corrosion_import_crate(MANIFEST_PATH Cargo.toml CRATES/corrosion_import_crate(MANIFEST_PATH Cargo.toml LOCKED CRATES/' CMakeLists.txt
    [[ $(grep -c 'LOCKED CRATES' CMakeLists.txt) == 3 ]]
    # The release's Cargo.lock omits libsqlite3-sys's dependency on cc, which
    # current cargo records, so --locked refuses it. Add exactly the line cargo
    # would; every pinned version stays as upstream locked it.
    sed -i '/^name = "libsqlite3-sys"$/,/^dependencies = \[$/{/^dependencies = \[$/a\ "cc",
}' Cargo.lock
    grep -A6 '^name = "libsqlite3-sys"$' Cargo.lock | grep -x ' "cc",' >/dev/null
}

build() {
    # Keep cargo's registry and download cache inside the build directory.
    export CARGO_HOME="$PWD/.cargo-home"
    # The documentation is an Info manual, which joe does not ship; the
    # tests are not run.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D FETCHCONTENT_SOURCE_DIR_CORROSION="$PWD/.corrosion" \
        -D WITH_SQLITE3=ON \
        -D BUILD_DATA=ON \
        -D BUILD_DOC=OFF \
        -D BUILD_TESTING=OFF
    # The dictionaries are compiled with chewing-cli, built first.
    ninja -C build
}

package() {
    # The library, chewing-cli and the dictionaries in
    # /usr/share/libchewing.
    DESTDIR="$DESTDIR" ninja -C build install
}
