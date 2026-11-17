# Following the book's Python Dependencies page (Markdown). It installs the
# markdown_py program.
build() {
    pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist Markdown
}
