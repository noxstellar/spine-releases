#!/bin/sh
# Install the published binary package. No Rust toolchain or source checkout needed.
set -eu

spine_fail() { printf 'spine installer: %s\n' "$*" >&2; exit 1; }

spine_version_is_valid() {
    case "$1" in ''|*[!0-9a-z.-]*) return 1 ;; esac
    [ "${#1}" -le 128 ] || return 1
    printf '%s\n' "$1" | LC_ALL=C grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-nightly\.[0-9]{8}\.[1-9][0-9]*\.[1-9][0-9]*)?$'
}

spine_cleanup() {
    spine_exit=$?
    trap - 0 HUP INT TERM
    [ -z "$spine_work" ] || rm -rf "$spine_work"
    [ -z "$spine_link_stage" ] || rm -rf "$spine_link_stage"
    [ "$spine_locked" != yes ] || rmdir "$spine_data/.install.lock" 2>/dev/null || :
    exit "$spine_exit"
}

spine_install() {
    case "${1-}" in
        --help|-h)
            printf '%s\n' 'Usage: sh install.sh [VERSION]' \
                'Default: latest official release; SPINE_RELEASE_REPOSITORY=noxstellar/spine-releases.' \
                'Pin with SPINE_VERSION=X.Y.Z or X.Y.Z-nightly.YYYYMMDD.RUN.ATTEMPT.' \
                'SPINE_BIN_DIR defaults to $HOME/.local/bin; SPINE_DATA_DIR to $HOME/.local/share/spine.' \
                'Installs the macOS ARM64 CLI. Task execution also needs the documented Docker worker.'
            return ;;
    esac
    [ "$#" -le 1 ] || spine_fail 'expected at most one version argument; use --help'
    spine_version=${1:-${SPINE_VERSION:-latest}}
    if [ "$spine_version" != latest ]; then
        spine_version=${spine_version#v}
        spine_version_is_valid "$spine_version" || spine_fail 'version must be latest, X.Y.Z or X.Y.Z-nightly.YYYYMMDD.RUN.ATTEMPT'
    fi
    spine_repo=${SPINE_RELEASE_REPOSITORY:-noxstellar/spine-releases}
    case "$spine_repo" in ''|*[!A-Za-z0-9._/-]*) spine_fail 'invalid GitHub release repository' ;; esac
    printf '%s\n' "$spine_repo" | LC_ALL=C grep -Eq '^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9][A-Za-z0-9._-]*$' || spine_fail 'invalid GitHub release repository'
    case "$(uname -s)/$(uname -m)" in
        Darwin/arm64|Darwin/aarch64) spine_target=aarch64-apple-darwin ;;
        *) spine_fail 'this release supports macOS on Apple Silicon only; no files installed' ;;
    esac
    for spine_command in curl tar shasum awk grep wc tr mktemp mkdir chmod mv ln readlink find diff rm; do
        command -v "$spine_command" >/dev/null 2>&1 || spine_fail "required command missing: $spine_command"
    done
    [ -n "${HOME-}" ] || spine_fail 'HOME must be set'
    spine_bin=${SPINE_BIN_DIR:-$HOME/.local/bin}
    spine_data=${SPINE_DATA_DIR:-$HOME/.local/share/spine}
    for spine_path in "$spine_bin" "$spine_data"; do
        case "$spine_path" in /*) ;; *) spine_fail 'installation directories must be absolute paths' ;; esac
        case "$spine_path" in *:*) spine_fail 'installation directories must not contain a colon' ;; esac
        [ "$(printf '%s' "$spine_path" | wc -l | tr -d ' ')" = 0 ] || spine_fail 'installation directories must not contain newlines'
        [ ! -L "$spine_path" ] || spine_fail "installation directory is a symlink: $spine_path"
    done
    spine_releases=$spine_data/releases
    [ ! -L "$spine_releases" ] || spine_fail 'release directory must not be a symlink'
    spine_command_path=$spine_bin/spine
    [ ! -d "$spine_command_path" ] || spine_fail "refusing to replace a directory or a link to one: $spine_command_path"
    if [ -L "$spine_command_path" ]; then
        spine_old_target=$(readlink "$spine_command_path")
        case "$spine_old_target" in
            "$spine_releases/"*/bin/spine)
                spine_old_name=${spine_old_target#"$spine_releases/"}
                spine_old_name=${spine_old_name%/bin/spine}
                case "$spine_old_name" in
                    *-"$spine_target") spine_old_version=${spine_old_name%"-$spine_target"} ;;
                    *) spine_fail 'existing spine link is not managed by this installer' ;;
                esac
                spine_version_is_valid "$spine_old_version" || spine_fail 'existing spine link is not managed by this installer' ;;
            *) spine_fail "refusing to replace an unrelated symlink: $spine_command_path" ;;
        esac
    elif [ -e "$spine_command_path" ]; then
        spine_fail "refusing to replace an existing file: $spine_command_path"
    fi
    umask 077
    spine_work= spine_link_stage= spine_locked=no
    mkdir -p "$spine_bin" "$spine_releases"
    mkdir "$spine_data/.install.lock" 2>/dev/null || spine_fail "another installation is active (lock: $spine_data/.install.lock)"
    spine_locked=yes
    trap spine_cleanup 0
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
    spine_work=$(mktemp -d "$spine_releases/.install.XXXXXXXX")
    if [ "$spine_version" = latest ]; then
        spine_latest_url=$(curl --proto '=https' --proto-redir '=https' --tlsv1.2 --fail --location --silent --show-error \
            --head --max-redirs 5 --connect-timeout 10 --max-time 60 --output /dev/null \
            --write-out '%{url_effective}' "https://github.com/$spine_repo/releases/latest") || spine_fail 'could not resolve the latest official release; no installation changed'
        spine_tag_prefix=https://github.com/$spine_repo/releases/tag/v
        case "$spine_latest_url" in
            "$spine_tag_prefix"*) spine_version=${spine_latest_url#"$spine_tag_prefix"} ;;
            *) spine_fail 'latest release redirected to an unexpected repository or URL' ;;
        esac
        spine_version_is_valid "$spine_version" || spine_fail 'latest release has an invalid version tag'
        case "$spine_version" in *-*) spine_fail 'latest official release must not be a nightly prerelease' ;; esac
    fi
    spine_release=$spine_releases/$spine_version-$spine_target
    spine_asset=spine-$spine_version-$spine_target.tar.gz
    spine_url=https://github.com/$spine_repo/releases/download/v$spine_version
    printf 'Installing Spine %s for %s...\n' "$spine_version" "$spine_target"
    curl --proto '=https' --proto-redir '=https' --tlsv1.2 --fail --location --silent --show-error \
        --connect-timeout 10 --max-time 180 --max-filesize 65536 \
        --output "$spine_work/SHA256SUMS" "$spine_url/SHA256SUMS"
    [ "$(wc -c < "$spine_work/SHA256SUMS")" -le 65536 ] || spine_fail 'checksum list exceeds its size limit'
    spine_expected=$(LC_ALL=C awk -v asset="$spine_asset" '
        $2 == asset {
            if (NF != 2 || length($1) != 64 || $1 !~ /^[0-9a-f]+$/) exit 1
            digest=$1; count++
        }
        END { if (count != 1) exit 1; print digest }
    ' "$spine_work/SHA256SUMS") || spine_fail 'release checksum is missing or duplicated'
    curl --proto '=https' --proto-redir '=https' --tlsv1.2 --fail --location --silent --show-error \
        --connect-timeout 10 --max-time 180 --max-filesize 67108864 \
        --output "$spine_work/package.tar.gz" "$spine_url/$spine_asset"
    [ "$(wc -c < "$spine_work/package.tar.gz")" -le 67108864 ] || spine_fail 'download exceeds its size limit'
    spine_actual=$(shasum -a 256 "$spine_work/package.tar.gz" | awk '{ print $1 }')
    [ "$spine_actual" = "$spine_expected" ] || spine_fail 'download checksum mismatch; previous installation unchanged'

    # A strict regular-file-only archive needs no general-purpose extraction policy.
    # Validate names, duplicates, types and declared sizes before writing any member.
    unset TAR_OPTIONS
    export LC_ALL=C COPYFILE_DISABLE=1
    tar -tzf "$spine_work/package.tar.gz" > "$spine_work/members"
    awk '
        !/^[A-Za-z0-9_.+\/-]+$/ || /(^|\/)\.\.?($|\/)/ || /^\// || /\/$/ || /\/\// { exit 1 }
        seen[$0]++ { exit 1 }
        $0 == "bin/spine" { binary++; next }
        $0 == "libexec/spine-core" { core++; next }
        $0 == "libexec/spine-worker-setup" { worker++; next }
        $0 == "PACKAGE.json" { metadata++; next }
        $0 == "LICENSE" { license++; next }
        /^THIRD_PARTY_NOTICES\// {
            count=split($0, parts, "/")
            if (count < 3 || count > 10 || parts[count] !~ /^(LICENSE|COPYING|COPYRIGHT|NOTICE|UNLICENSE)[A-Za-z0-9_.+-]*$/) exit 1
            notices++; next
        }
        { exit 1 }
        END { if (binary != 1 || core != 1 || worker != 1 || metadata != 1 || license != 1 || notices < 1 || NR > 4096) exit 1 }
    ' "$spine_work/members" || spine_fail 'release archive contains unsafe, duplicate or unexpected paths'
    spine_members=$(wc -l < "$spine_work/members")
    tar -tvzf "$spine_work/package.tar.gz" > "$spine_work/member-details"
    awk -v expected="$spine_members" '
        substr($0, 1, 1) != "-" { exit 1 }
        { size=($2 ~ /^[0-9]+$/ ? $5 : $3)
          if (size !~ /^[0-9]+$/ || size > 67108864) exit 1
          total+=size; if (total > 134217728) exit 1 }
        END { if (NR != expected) exit 1 }
    ' "$spine_work/member-details" || spine_fail 'release archive contains links, special files or excessive sizes'
    mkdir "$spine_work/payload"
    tar -xzf "$spine_work/package.tar.gz" -C "$spine_work/payload" --no-same-owner --no-same-permissions
    [ -f "$spine_work/payload/bin/spine" ] && [ ! -L "$spine_work/payload/bin/spine" ] || spine_fail 'release binary is missing'
    [ -f "$spine_work/payload/libexec/spine-core" ] && [ ! -L "$spine_work/payload/libexec/spine-core" ] || spine_fail 'release core is missing'
    [ -f "$spine_work/payload/libexec/spine-worker-setup" ] && [ ! -L "$spine_work/payload/libexec/spine-worker-setup" ] || spine_fail 'worker setup helper is missing'
    chmod 755 "$spine_work/payload/bin/spine" "$spine_work/payload/libexec/spine-core" "$spine_work/payload/libexec/spine-worker-setup"
    spine_reported=$("$spine_work/payload/bin/spine" --version) || spine_fail 'downloaded binary could not start; previous installation unchanged'
    [ "$spine_reported" = "spine $spine_version" ] || spine_fail 'downloaded binary version does not match the selected release'
    printf '%s\n' "$spine_expected" > "$spine_work/payload/.spine-package-sha256"
    if [ -e "$spine_release" ] || [ -L "$spine_release" ]; then
        [ -d "$spine_release" ] && [ ! -L "$spine_release" ] || spine_fail 'existing release path is not a regular directory'
        [ -z "$(find "$spine_release" ! -type d ! -type f -print)" ] || spine_fail 'existing release contains links or special files'
        for spine_executable in bin/spine libexec/spine-core libexec/spine-worker-setup; do
            [ -f "$spine_release/$spine_executable" ] && [ -x "$spine_release/$spine_executable" ] || spine_fail 'existing release executable permissions changed; refusing to report a successful reinstall'
        done
        diff -qr "$spine_work/payload" "$spine_release" >/dev/null || spine_fail 'existing release contents differ; refusing to overwrite them'
    else
        mv "$spine_work/payload" "$spine_release"
    fi
    spine_link_stage=$(mktemp -d "$spine_bin/.spine-link.XXXXXXXX")
    ln -s "$spine_release/bin/spine" "$spine_link_stage/spine"
    mv -f "$spine_link_stage/spine" "$spine_command_path"
    printf 'Spine %s installed: %s\n' "$spine_version" "$spine_command_path"
    case ":${PATH-}:" in
        *":$spine_bin:"*) ;;
        *) printf 'Add this directory to your PATH: %s\n' "$spine_bin" ;;
    esac
    printf '%s\n' 'Next: spine setup (after adding its directory to PATH if needed).'
    printf '%s\n' 'Task execution also requires Docker and the separately provisioned pinned worker.' \
        "Setup instructions: https://github.com/$spine_repo#readme"
}

# Keeping execution at the end prevents a partially downloaded script doing work.
spine_install "$@"
