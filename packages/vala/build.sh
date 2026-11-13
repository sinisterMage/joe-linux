build() {
    # valadoc needs Graphviz, which has no recipe. The cache variable makes
    # configure believe there is no xsltproc, so the Devhelp manual is not
    # built when libxslt happens to be installed.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-valadoc \
        ac_cv_path_XSLTPROC=:
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
