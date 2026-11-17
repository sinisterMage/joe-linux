# Not in the book: the newest upstream release, built with its meson files
# (the README describes only Flatpak builds through GNOME Builder).
# Upstream publishes no checksum for the release archive.
prepare() {
    # Upstream hard-codes its Flatpak paths; use joe's system OCR engine
    # and data. Downloaded models belong in the native XDG data directory.
    sed -i \
        -e "s|OCR_TESSERACT_CMD = '/app/bin/tesseract'|OCR_TESSERACT_CMD = '/usr/bin/tesseract'|" \
        -e "s|OCR_ORIGINAL_TESSDATA_DIR = '/app/share/tessdata'|OCR_ORIGINAL_TESSDATA_DIR = '/usr/share/tessdata'|" \
        meson.build
    sed -i 's|os.path.expanduser(f"~/.var/app/{app_id}/data/tessdata")|os.path.join(GLib.get_user_data_dir(), "gradia", "tessdata")|' \
        gradia/backend/ocr.py
}

build() {
    mkdir build
    cd build
    # Tesseract supplies the engine and its English/OSD language data.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D enable-ocr=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
