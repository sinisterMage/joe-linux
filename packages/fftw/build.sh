# The book builds and installs the three precisions one after another in
# the source directory. Here each gets its own build directory, so that all
# three are built before any is installed. SSE2 and AVX code is selected at
# run time; there is none for long double.
build() {
    local flags=(--prefix=/usr --enable-shared --disable-static --enable-threads)
    local simd=(--enable-sse2 --enable-avx --enable-avx2)

    mkdir build-double build-float build-long-double
    (cd build-double && ../configure "${flags[@]}" "${simd[@]}" && make)
    (cd build-float && ../configure "${flags[@]}" "${simd[@]}" --enable-float && make)
    (cd build-long-double && ../configure "${flags[@]}" --enable-long-double && make)
}

package() {
    local precision
    for precision in double float long-double; do
        make -C "build-$precision" DESTDIR="$DESTDIR" install
    done
}
