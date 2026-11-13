prepare() {
    # Use the EXSLT "replace" function when it is available: the recursive
    # string substitution overflows the stack on long strings.
    patch -Np1 -i "$SOURCES/docbook-xsl-nons-1.79.2-stack_fix-1.patch"
}

package() {
    local dir="$DESTDIR/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2"

    install -v -m755 -d "$dir"

    cp -R VERSION assembly common eclipse epub epub3 extensions fo \
        highlighting html htmlhelp images javahelp lib manpages params \
        profiling roundtrip slides template tests tools webhelp website \
        xhtml xhtml-1_1 xhtml5 \
        "$dir"

    ln -sf VERSION "$dir/VERSION.xsl"

    # No xmlcatalog commands here: the entries for these stylesheets are
    # part of /etc/xml/catalog as docbook-xml ships it.
}
