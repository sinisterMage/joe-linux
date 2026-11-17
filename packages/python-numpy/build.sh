# Following the book's NumPy page (2.5.4), with system BLAS/LAPACK.
# Upstream pyproject.toml explicitly supports CPython 3.15; regenerate with Cython 3.3.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD" \
        -Csetup-args=-Dblas=openblas -Csetup-args=-Dlapack=lapack \
        -Csetup-args=-Dallow-noblas=false -Csetup-args=-Duse-ilp64=false \
        -Csetup-args=-Dcpu-baseline=min -Csetup-args=-Dcpu-dispatch=max
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist numpy
}
