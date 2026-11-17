# Not in the book: newest upstream stable, using its Meson backend.
# Use system libraries: never download Meson fallback subprojects.
# Upstream publishes cp315 wheels for 3.11.2 (including Linux x86-64),
# despite stale classifiers stopping at 3.14; build with Python-3.15-aware pybind11 3.1.
# GUI backends are selected at runtime (GTK3/4, Qt6 and Tk); no native autodetection.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD" \
        -Csetup-args=--wrap-mode=nofallback \
        -Csetup-args=-Dsystem-freetype=true -Csetup-args=-Dsystem-qhull=true \
        -Csetup-args=-Dsystem-libraqm=true -Csetup-args=-Dmacosx=false \
        -Csetup-args=-DrcParams-backend=auto
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist matplotlib
}
