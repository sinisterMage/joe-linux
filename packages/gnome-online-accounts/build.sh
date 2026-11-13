build() {
    mkdir build
    cd build
    # kerberos: off as in the book. The Google client id and secret are the
    # ones the book registered for its readers. No provider needs WebKit:
    # OAuth log-ins open the web browser.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D goabackend=true \
        -D introspection=true \
        -D vapi=true \
        -D man=true \
        -D documentation=false \
        -D kerberos=false \
        -D fedora=false \
        -D google_client_secret=5ntt6GbbkjnTVXx-MSxbmx5e \
        -D google_client_id=595013732528-llk8trb03f0ldpqq6nprjp1s79596646.apps.googleusercontent.com
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
