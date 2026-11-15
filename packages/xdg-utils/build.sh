_scripts="xdg-desktop-menu xdg-desktop-icon xdg-mime xdg-icon-resource xdg-open xdg-email xdg-screensaver xdg-settings"

build() {
    ./configure --prefix=/usr

    # The book's "make" builds the manual pages with xmlto and, through
    # xmlto's text output, which needs Lynx, Links or w3m, the text that
    # --help and --manual print and that is pasted into the scripts. Neither
    # xmlto nor a text browser exists here, so the same two things are made
    # from the same DocBook sources with the tools that do: the manual
    # pages with xsltproc and the DocBook stylesheets (as xmlto would), and
    # the text by rendering those pages with groff, with the section
    # headings written the way generate-help-script.awk looks for them
    # ("Name", then an empty line).
    cd scripts
    local n
    for n in $_scripts; do
        (cd man && xsltproc --nonet \
            http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl \
            "../desc/$n.xml")
        groff -man -Tutf8 -P-cbou "man/$n.1" |
            sed -E 's/^([A-Z])([A-Z ]+)$/\1\L\2\E\n/' > "$n.txt"
        [[ -s $n.txt ]]
    done
    make scripts
}

package() {
    make -C scripts DESTDIR="$DESTDIR" install
}
