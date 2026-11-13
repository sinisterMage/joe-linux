build() {
    # The book's options: the library only. The command-line encoder is not
    # built because it would link ffmpeg, which itself links this library.
    # The remaining switches name the inputs only that program uses, so that
    # nothing is picked up from the build root; OpenCL has no recipe.
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --enable-shared \
        --disable-cli \
        --disable-opencl \
        --disable-avs \
        --disable-swscale \
        --disable-lavf \
        --disable-ffms \
        --disable-gpac \
        --disable-lsmash \
        --disable-bashcompletion
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
