#!/bin/bash
#
# build.sh — builds cachyos-calamares-next (PKGBUILD + live-offline.patch) and
# puts it in the local repository used by buildiso.sh (../localrepo).
# Run as a normal user (makepkg refuses root), before ./buildiso.sh.
#
# Skipped when the local repository already has the version of the PKGBUILD
# (bump pkgrel after each change of the patch).
#
# Usage: ./build.sh [-f]   (-f: rebuild anyway)

set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"
repo_dir="$(readlink -f ../localrepo)"
repo_name="packarch-live-local"

# Generic x86-64 code: Calamares runs on the live ISO, on any processor (the
# system makepkg.conf may use -march=native)
makepkg_conf="$(readlink -f ../scripts/makepkg-generic.conf)"

force=false
[[ ${1:-} == -f ]] && force=true

# Only the package of the PKGBUILD: older versions may still be in this
# directory
pkg="$(makepkg --config "$makepkg_conf" --packagelist)"

if ! $force && [[ -f "$repo_dir/$(basename "$pkg")" && -f "$repo_dir/$repo_name.db" ]]; then
    echo "$(basename "$pkg") already in $repo_dir: not rebuilt (-f to force)"
    exit 0
fi

makepkg --config "$makepkg_conf" --syncdeps --cleanbuild --force --noconfirm

mkdir -p "$repo_dir"
rm -f "$repo_dir"/cachyos-calamares-next-*.pkg.tar.zst
cp "$pkg" "$repo_dir"/
repo-add "$repo_dir/$repo_name.db.tar.gz" "$repo_dir/$(basename "$pkg")"

echo "Package added to $repo_dir ($repo_name)"
