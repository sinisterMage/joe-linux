# Not in the book: the newest upstream release, built with CMake as its
# README ("Building from source with CMake") describes: the system PCRE2,
# message localization, and the documentation built with Sphinx. fish is
# not added to /etc/shells.
build() {
    # Keep cargo's registry, git checkouts and download cache inside the
    # build directory rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # CARGO_FLAGS=--locked: build exactly the crate versions in upstream's
    # Cargo.lock (CMake appends these flags to its cargo build).
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_SYSCONFDIR=/etc \
        -D CMAKE_BUILD_TYPE=Release \
        -D FISH_USE_SYSTEM_PCRE2=ON \
        -D WITH_MESSAGE_LOCALIZATION=ON \
        -D WITH_DOCS=ON \
        -D CARGO_FLAGS=--locked
    ninja -C build
}

package() {
    # fish, with fish_indent and fish_key_reader as links to it;
    # /etc/fish/config.fish; usr/share/fish with its functions, completions,
    # man pages for the builtins and the empty vendor_completions.d,
    # vendor_conf.d and vendor_functions.d other packages install into;
    # fish.pc; and the user manual pages. The HTML manual goes to
    # usr/share/doc/fish, which the build driver removes, so "help" opens
    # the online manual.
    DESTDIR="$DESTDIR" ninja -C build install
}
