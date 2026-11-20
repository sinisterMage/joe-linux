# Throwaway signed package repositories for the tests, built with dave on
# the host and served to machines by neomake (tests/vm/machines.tomlx).
# Sourced by the tests' preludes; run from the top of the tree.
#
#   repo_init DIR                      an empty DIR and a new key, DIR-key.{key,pub}
#   stage=$(repo_stage DIR NAME VERSION)   a fresh directory to put the package's files in
#   repo_file PATH CONTENT             a file (0644)
#   repo_script PATH TEXT              an executable /bin/sh script (0755) running TEXT
#   repo_pack DIR NAME VERSION [dave pack options]   pack the staged files
#   repo_index DIR                     sign the repository's index
#
# Packages are sealed with build/keys/joe-code.key when the distribution
# has been built, since that is the key joe's kernel trusts.

repo_dave=${DAVE:-dave/zig-out/bin/dave}

repo_init() {
    rm -rf "$1" "$1-stage" "$1-key.key" "$1-key.pub"
    mkdir -p "$1" "$1-stage"
    "$repo_dave" key generate "$1-key" >/dev/null
}

repo_stage() {
    local stage=$1-stage/$2-$3
    rm -rf "$stage"
    mkdir -p "$stage"
    printf '%s\n' "$stage"
}

repo_file() {
    mkdir -p "$(dirname "$1")"
    printf '%s' "$2" > "$1"
    chmod 0644 "$1"
}

repo_script() {
    mkdir -p "$(dirname "$1")"
    printf '#!/bin/sh\n%s\n' "$2" > "$1"
    chmod 0755 "$1"
}

repo_pack() {
    local dir=$1 name=$2 version=$3
    shift 3
    local seal=()
    [[ -e build/keys/joe-code.key ]] && seal=(--code-key build/keys/joe-code.key)
    "$repo_dave" pack --name "$name" --version "$version" --out "$dir" "${seal[@]}" "$@" \
        "$dir-stage/$name-$version" >/dev/null
}

repo_index() {
    "$repo_dave" repo index "$1" --key "$1-key.key" >/dev/null
}
