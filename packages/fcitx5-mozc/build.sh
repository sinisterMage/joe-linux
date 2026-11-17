# Not in the book: Fcitx's maintained Mozc branch, following its Bazel build
# and scripts/install_{server,fcitx5}_bazel. Mozc itself has no stable releases.
# Bazel is a PRIVATE stage0 build tool, not a shipped tier-2 package: its
# verified distribution archive bootstraps with OpenJDK. Only source-built
# Mozc ELF files, generated dictionaries and runtime assets are installed.
prepare() {
    mkdir .bazel-bootstrap .registry .repository-cache .home
    bsdtar -xf "$SOURCES/bazel-9.0.2-dist.zip" -C .bazel-bootstrap
    tar -xf "$SOURCES/bazel-central-registry-b0cb0e8ec70689252e3b35f109ffa4a32329b900.tar.gz" \
        --strip-components=1 -C .registry

    # A content-addressed cache avoids URL-basename collisions (three material
    # icons are all called 24px.svg). All inputs have dave-verified SHA-256s.
    # Bazel also downloads registry-injected patches and module overlays;
    # these are verified as part of the pinned registry archive.
    local file digest cache
    while IFS= read -r -d '' file; do
        digest=$(sha256sum "$file")
        digest=${digest%% *}
        cache="$PWD/.repository-cache/content_addressable/sha256/$digest"
        if [ ! -f "$cache/file" ]; then
            mkdir -p "$cache"
            cp --reflink=auto "$file" "$cache/file"
        fi
    done < <(
        printf '%s\0' "$SOURCES"/mozc-????????????-*
        find .registry/modules -type f \
            \( -path '*/patches/*' -o -path '*/overlay/*' -o -name MODULE.bazel \) -print0
    )

    # Use joe's source-built Go if a transitive rule needs Go, never a fetched
    # SDK. The vendored rules_go/gazelle sources and registry are pinned above.
    cat >> src/MODULE.bazel <<'EOF'

joe_go_sdk = use_extension("@io_bazel_rules_go//go:extensions.bzl", "go_sdk")
joe_go_sdk.host(name = "joe_go_sdk", version = "1.27.4")
use_repo(joe_go_sdk, "joe_go_sdk")
EOF
}

build() {
    export JAVA_HOME=/usr/lib/jvm/default
    export HOME="$PWD/.home"
    export GOTOOLCHAIN=local GOPROXY=off GOSUMDB=off
    # The bootstrap's own source and Maven caches are inside its verified
    # dist.zip. They are build tools only; none is copied into DESTDIR.
    # JDK 23+ no longer discovers processors by default. Enable bundled
    # AutoValue processing in both the shell and Bazel bootstrap phases.
    (
        cd .bazel-bootstrap
        env -u DESTDIR -u SOURCES \
            EMBED_LABEL=9.0.2 \
            BAZEL_JAVAC_OPTS="-proc:full" \
            EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk --java_runtime_version=local_jdk --javacopt=-proc:full --host_javacopt=-proc:full --repository_disable_download --jobs=$JOBS" \
            bash ./compile.sh
    )

    local root=$PWD
    cd src
    env -u DESTDIR -u SOURCES "$root/.bazel-bootstrap/output/bazel" \
        --batch --output_user_root="$root/.bazel-user" \
        build \
        --config=oss_linux --config=stable_channel --config=release_build \
        --config=no_sframe \
        --jobs="$JOBS" \
        --registry="file://$root/.registry" \
        --repository_cache="$root/.repository-cache" \
        --repository_disable_download \
        --repo_env=BAZEL_HTTP_RULES_URLS_AS_DEFAULT_CANONICAL_ID=0 \
        --lockfile_mode=off \
        --extra_toolchains=@rules_python//python/runtime_env_toolchains:all \
        --repo_env=BAZEL_PYTHON=/usr/bin/python3 \
        --java_runtime_version=local_jdk \
        --tool_java_runtime_version=local_jdk \
        --@com_google_protobuf//bazel/toolchains:prefer_prebuilt_protoc=false \
        --nostart_end_lib --linkopt=-fuse-ld=bfd \
        --copt=-DNDEBUG \
        //unix/fcitx5:fcitx5-mozc.so //server:mozc_server \
        //gui/tool:mozc_tool //unix:icons
}

package() {
    cd src
    install -Dm755 bazel-bin/unix/fcitx5/fcitx5-mozc.so \
        "$DESTDIR/usr/lib/fcitx5/fcitx5-mozc.so"
    install -Dm755 bazel-bin/server/mozc_server "$DESTDIR/usr/lib/mozc/mozc_server"
    install -Dm755 bazel-bin/gui/tool/mozc_tool "$DESTDIR/usr/lib/mozc/mozc_tool"
    # Upstream's data installer includes translations, addon/inputmethod
    # registration, Fcitx hicolor icons and AppStream metadata.
    PREFIX="$DESTDIR/usr" bash ../scripts/install_fcitx5_data
    install -d "$DESTDIR/usr/share/icons/mozc" "$DESTDIR/usr/lib/mozc/documents" \
        "$DESTDIR/usr/share/licenses/fcitx5-mozc"
    bsdtar -xf bazel-bin/unix/icons.zip -C "$DESTDIR/usr/share/icons/mozc"
    # config.bzl's DOCUMENT_DIR is lib/mozc/documents, not share/doc (which
    # the common driver deletes). The GUI's help and licence links need these.
    install -m644 data/installer/*.html "$DESTDIR/usr/lib/mozc/documents/"
    install -m644 ../LICENSE "$DESTDIR/usr/share/licenses/fcitx5-mozc/"
    install -m644 data/dictionary_oss/README.txt \
        "$DESTDIR/usr/share/licenses/fcitx5-mozc/dictionary.txt"
    # The OSS dictionary, usage/zipcode dictionaries and conversion tables are
    # generated from the pinned sources and embedded in mozc_server by Bazel's
    # //data_manager/oss:oss_data_manager; no dictionary download happens at runtime.
}
