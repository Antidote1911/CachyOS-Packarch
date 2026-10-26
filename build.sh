#!/usr/bin/env bash
#
# Reconstruit entièrement l'ISO :
#   1. Calamares (calamares/build.sh) dans le dépôt local localrepo/, sauf
#      si la version du PKGBUILD y est déjà (monter pkgrel après chaque
#      modification du patch)
#   2. l'ISO (scripts/buildiso.sh -p desktop -w), en root via sudo
#
# Usage : ./build.sh [-f] [-v] [-c] [-r]   (en utilisateur normal)
#   -f   recompiler Calamares même si sa version est déjà dans localrepo/
#   -v   journal détaillé
#   -c   ne pas vider le dossier de travail build/ avant
#   -r   construire en RAM (plus de 23 Go de RAM)
# L'ISO est produite dans out/desktop/.

set -euo pipefail

src_dir=$(dirname "$(readlink -f "$0")")
cd "${src_dir}"

usage() {
    sed -n '3,14s/^# \{0,1\}//p' "$0"
    exit "$1"
}

iso_args=()
cala_args=()
while getopts 'fvcrh' arg; do
    case "${arg}" in
        f) cala_args+=(-f) ;;
        v|c|r) iso_args+=("-${arg}") ;;
        h) usage 0 ;;
        *) usage 1 ;;
    esac
done

# makepkg refuse de tourner en root ; sudo n'est demandé que pour l'ISO
if [[ ${EUID} -eq 0 ]]; then
    echo "Lancer en utilisateur normal, sans sudo." >&2
    exit 1
fi

# Prérequis (README) : vérifiés avant de lancer une longue compilation
missing=()
for p in archiso mkinitcpio-archiso squashfs-tools grub git base-devel; do
    pacman -Q "${p}" &>/dev/null || missing+=("${p}")
done
if (( ${#missing[@]} )); then
    echo "Paquets manquants : ${missing[*]}" >&2
    echo "  sudo pacman -S --needed ${missing[*]}" >&2
    exit 1
fi

echo "==> 1/2 Calamares et dépôt local"
./calamares/build.sh "${cala_args[@]}"

echo "==> 2/2 ISO"
sudo ./scripts/buildiso.sh -p desktop -w "${iso_args[@]}"

# Les fichiers produits appartiennent à root
sudo chown -R "${USER}": out

echo "==> ISO prête :"
ls -lh out/desktop/*.iso
