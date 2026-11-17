# Not in the book: upstream stable, using its Meson backend.
# pyproject.toml supports Python 3.15 and requires Pythran >=0.19 for it.
# Its Cython <3.3 and pybind11 <3.1 pins are explicitly preemptive, not known incompatibilities.
# --no-build-isolation uses joe's newer Cython/pybind11 (including their Python 3.15 support).
# Boost.Math (header-only) is the copy in subprojects/: SciPy requires
# exactly the Boost release it pins (1.91.0) when using the system's.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD" \
        -Csetup-args=-Dblas=openblas -Csetup-args=-Dlapack=lapack \
        -Csetup-args=-Duse-ilp64=false -Csetup-args=-Duse-pythran=true \
        -Csetup-args=-Duse-system-libraries=qhull
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist scipy
}
