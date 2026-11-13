# The version of docbook-xsl-nons whose catalog entries are written below.
# Keep it the same as the version in packages/docbook-xsl-nons.
_xsl_version=1.79.2

unpack() {
    # A zip file with no top-level directory.
    python3 -m zipfile -e "$SOURCES/$PKG_SOURCE" .
}

package() {
    local dtd="$DESTDIR/usr/share/xml/docbook/xml-dtd-4.5"
    local catalog="$DESTDIR/etc/xml/catalog"
    local DTDVERSION uri rewrite

    install -v -d -m755 "$dtd"
    install -v -d -m755 "$DESTDIR/etc/xml"
    cp -v -af --no-preserve=ownership \
        catalog.xml docbook.cat *.dtd ent/ *.mod \
        "$dtd"

    # Everything below is the book's sequence of xmlcatalog commands, run on
    # the files in $DESTDIR. What is written into the catalogs are the
    # paths on the installed system.

    xmlcatalog --noout --add "rewriteSystem" \
        "http://www.oasis-open.org/docbook/xml/4.5" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5" \
        "$dtd/catalog.xml"

    xmlcatalog --noout --add "rewriteURI" \
        "http://www.oasis-open.org/docbook/xml/4.5" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5" \
        "$dtd/catalog.xml"

    # /etc/xml/catalog, the system XML catalog, belongs to this package.
    xmlcatalog --noout --create "$catalog"

    xmlcatalog --noout --add "delegatePublic" \
        "-//OASIS//ENTITIES DocBook XML" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
        "$catalog"

    xmlcatalog --noout --add "delegatePublic" \
        "-//OASIS//DTD DocBook XML" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
        "$catalog"

    xmlcatalog --noout --add "delegateSystem" \
        "http://www.oasis-open.org/docbook/" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
        "$catalog"

    xmlcatalog --noout --add "delegateURI" \
        "http://www.oasis-open.org/docbook/" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
        "$catalog"

    # Documents that ask for an older 4.x DTD get this one.
    for DTDVERSION in 4.1.2 4.2 4.3 4.4; do
        xmlcatalog --noout --add "public" \
            "-//OASIS//DTD DocBook XML V$DTDVERSION//EN" \
            "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" \
            "$dtd/catalog.xml"

        xmlcatalog --noout --add "rewriteSystem" \
            "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
            "file:///usr/share/xml/docbook/xml-dtd-4.5" \
            "$dtd/catalog.xml"

        xmlcatalog --noout --add "rewriteURI" \
            "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
            "file:///usr/share/xml/docbook/xml-dtd-4.5" \
            "$dtd/catalog.xml"
    done

    # The catalog entries of the DocBook XSL stylesheets, from the book's
    # docbook-xsl-nons page. The book adds them to /etc/xml/catalog when it
    # installs the stylesheets; a package cannot edit a file that belongs to
    # another package and there are no install scripts, so the owner of the
    # catalog writes them and docbook-xsl-nons ships only the stylesheets.
    # Until that package is installed these entries point at a directory
    # that does not exist, which is harmless.
    for uri in http{,s}://cdn.docbook.org/release/xsl-nons/{$_xsl_version,current} \
        http://docbook.sourceforge.net/release/xsl/current; do
        for rewrite in System URI; do
            xmlcatalog --noout --add "rewrite$rewrite" \
                "$uri" \
                "/usr/share/xml/docbook/xsl-stylesheets-nons-$_xsl_version" \
                "$catalog"
        done
    done
}
