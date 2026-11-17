# Not in the book. Since version 4 libimagequant is written in Rust; its C
# library (libimagequant.so.0, libimagequant.h, imagequant.pc) is the
# imagequant-sys crate, built with cargo-c as upstream's README for it
# describes. Default features: multithreading (rayon). libvips uses it.
_capi_args=(--release --locked --prefix=/usr --libdir=/usr/lib
    --library-type=cdylib)

build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    cargo cbuild "${_capi_args[@]}"
}

package() {
    export CARGO_HOME="$PWD/.cargo-home"
    cargo cinstall "${_capi_args[@]}" --destdir="$DESTDIR"
}
