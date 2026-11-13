prepare() {
    # From the book: warnings from a newer compiler must not stop the build.
    sed -i 's/-Werror //g' CPP/7zip/7zip_gcc.mak
}

build() {
    # As in the book: the full program (7z, with its codecs in 7z.so), the
    # standalone 7za and 7zr, and the stub for self-extracting archives.
    # UASM does not exist, so the C implementations are used throughout.
    local i
    for i in Bundles/Alone Bundles/Alone7z Bundles/Format7zF Bundles/SFXCon UI/Console; do
        make -C CPP/7zip/$i -f ../../cmpl_gcc.mak
    done
}

package() {
    install -vDm755 CPP/7zip/Bundles/Alone/b/g/7za \
        CPP/7zip/Bundles/Alone7z/b/g/7zr \
        CPP/7zip/Bundles/Format7zF/b/g/7z.so \
        CPP/7zip/UI/Console/b/g/7z \
        -t "$DESTDIR/usr/lib/7zip/"
    install -vm755 CPP/7zip/Bundles/SFXCon/b/g/7zCon \
        "$DESTDIR/usr/lib/7zip/7zCon.sfx"

    # 7z looks for 7z.so beside itself, hence the wrappers.
    install -d "$DESTDIR/usr/bin"
    local i
    for i in 7z 7za 7zr; do
        cat > "$DESTDIR/usr/bin/$i" <<EOF
#!/bin/sh
exec /usr/lib/7zip/$i "\$@"
EOF
        chmod 755 "$DESTDIR/usr/bin/$i"
    done
}
