# Not in the book: the newest upstream release. Building the wheel runs
# upstream's hatch hook (hatch_build.py), which installs the JavaScript
# dependencies from the lockfile and bundles the solver scripts with rollup
# into dist/, then puts them in the wheel. The bundled astring (MIT) and
# meriyah (ISC) are why the license is not only the Unlicense.

prepare() {
    # The hook uses whichever of pnpm, deno, bun and npm it finds first,
    # and joe's build root may hold pnpm and bun; always use npm, with
    # upstream's package-lock.json.
    sed -i -e 's/shutil\.which("pnpm")/None/' \
        -e 's/shutil\.which("deno")/None/' \
        -e 's/shutil\.which("bun")/None/' hatch_build.py
    grep -q 'npm := shutil.which("npm")' hatch_build.py
}

build() {
    # npm's cache stays in the build directory, out of the shared build
    # root's /root.
    export HOME="$PWD/.home"
    export npm_config_cache="$HOME/.npm"
    pip3 wheel -w dist-wheel --no-cache-dir --no-build-isolation --no-deps "$PWD"

    # yt-dlp accepts these scripts only if they are byte for byte the ones
    # upstream released (it checks their SHA3-512, the values in yt-dlp's
    # yt_dlp/extractor/youtube/jsc/_builtin/vendor/_info.py for 0.8.0), and
    # otherwise ignores them. Fail here rather than ship a bundle it would
    # refuse.
    python3 - << "EOT"
import hashlib, sys
expected = {
    "dist/yt.solver.core.min.js": "ee5b307d07f55e91e4723edf5ac205cc877a474187849d757dc1322e38427b157a9d706d510c1723d3670f98e5a3f8cbcde77874a80406bd7204bc9fea30f283",
    "dist/yt.solver.lib.min.js": "8420c259ad16e99ce004e4651ac1bcabb53b4457bf5668a97a9359be9a998a789fee8ab124ee17f91a2ea8fd84e0f2b2fc8eabcaf0b16a186ba734cf422ad053",
}
for path, digest in expected.items():
    with open(path, encoding="utf-8") as f:
        actual = hashlib.sha3_512(f.read().encode()).hexdigest()
    if actual != digest:
        sys.exit(f"{path}: SHA3-512 {actual}, yt-dlp expects {digest}")
EOT
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist-wheel yt-dlp-ejs
}
