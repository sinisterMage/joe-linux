# Not in the book: the newest upstream release, built with meson as its
# INSTALL says. Face detection is off (it needs OpenCV, which has no
# recipe), and so is Ubuntu's Apport crash-report hook.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D publishers=flickr,googlephotos,piwigo,youtube,gallery3,tumblr \
        -D udev=enabled \
        -D face_detection=false \
        -D install_apport_hook=false \
        -D dupe_detection=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
