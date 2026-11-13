build() {
    mkdir -p build
    cd build
    # The manual page needs xsltproc and the DocBook XSL stylesheets (the
    # book's optional libxslt); there is no SELinux. The completion
    # directories are given so that they do not depend on whether
    # bash-completion is in the build root.
    meson setup --prefix=/usr .. \
        --libdir=lib \
        --buildtype=release \
        -D man=disabled \
        -D selinux=disabled \
        -D tests=false \
        -D bash_completion_dir=/usr/share/bash-completion/completions \
        -D zsh_completion_dir=/usr/share/zsh/site-functions
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
