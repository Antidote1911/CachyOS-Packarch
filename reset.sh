#!/usr/bin/env bash
#
# Remet le projet à l'état propre, prêt à être publié (GitHub...) : supprime
# tout ce que ./build.sh et ./run.sh génèrent.
#   - out/                 ISO, sommes de contrôle, liste des paquets
#   - build/               dossier de travail de buildiso.sh (s'il reste)
#   - localrepo/           dépôt local (Calamares)
#   - calamares/src, pkg, calamares, *.pkg.tar.zst   compilation de Calamares
#   - fichiers écrits dans archiso/ par scripts/util-iso.sh à chaque build,
#     et date de l'ISO remise à AAMMJJ dans archiso/grub/grub.cfg
#   - vm-test/             disque et variables UEFI de la VM (sauf -k)
#
# Usage : ./reset.sh [-y] [-k]   (en utilisateur normal ; sudo est demandé
#                                 pour les fichiers appartenant à root)
#   -y   ne pas demander de confirmation
#   -k   garder la machine virtuelle (vm-test/)

set -euo pipefail

src_dir=$(dirname "$(readlink -f "$0")")
cd "${src_dir}"

usage() {
    sed -n '3,16s/^# \{0,1\}//p' "$0"
    exit "$1"
}

confirm=true
keep_vm=false
while getopts 'ykh' arg; do
    case "${arg}" in
        y) confirm=false ;;
        k) keep_vm=true ;;
        h) usage 0 ;;
        *) usage 1 ;;
    esac
done

if [[ ${EUID} -eq 0 ]]; then
    echo "Lancer en utilisateur normal, sans sudo." >&2
    exit 1
fi

# Générés par scripts/util-iso.sh (recréés à chaque build)
archiso_generated=(
    archiso/packages.x86_64
    archiso/airootfs/etc/motd
    archiso/airootfs/etc/environment
    archiso/airootfs/etc/version-tag
    archiso/airootfs/etc/edition-tag
    archiso/airootfs/etc/pacman.d/cachyos-mirrorlist
    archiso/airootfs/etc/systemd/system/display-manager.service
    archiso/airootfs/etc/systemd/system/cachyos-rate-mirrors.timer
)

targets=(out build localrepo calamares/src calamares/pkg calamares/calamares)
targets+=(calamares/*.pkg.tar.zst)
targets+=("${archiso_generated[@]}")
${keep_vm} || targets+=(vm-test)

# Date de l'ISO écrite dans grub.cfg par scripts/util-iso.sh à chaque build
grub_cfg=archiso/grub/grub.cfg
grub_version='PACKARCH_VERSION="AAMMJJ"'
grub_dirty=false
grep -qx "${grub_version}" "${grub_cfg}" || grub_dirty=true

# Seulement ce qui existe ([[ -L ]] pour les liens vers /dev/null ou lightdm)
existing=()
for t in "${targets[@]}"; do
    [[ -e ${t} || -L ${t} ]] && existing+=("${t}")
done

if (( ${#existing[@]} == 0 )) && ! ${grub_dirty}; then
    echo "Le projet est déjà propre."
    exit 0
fi

if (( ${#existing[@]} )); then
    echo "À supprimer :"
    du -shc "${existing[@]}" 2>/dev/null | sed 's/^/  /'
fi
${grub_dirty} && echo "À remettre : ${grub_version} dans ${grub_cfg}"
if ${confirm}; then
    read -rp "Confirmer la suppression ? [o/N] " answer
    [[ ${answer} == [oOyY]* ]] || { echo "Annulé."; exit 1; }
fi

# Un build interrompu peut laisser des systèmes de fichiers montés dans build/
if [[ -d build ]] && findmnt -rno TARGET | grep -q "^${src_dir}/build/"; then
    echo "Des systèmes de fichiers sont encore montés dans build/ :" >&2
    findmnt -rno TARGET | grep "^${src_dir}/build/" >&2
    echo "Les démonter (sudo umount -R …) avant de relancer reset.sh." >&2
    exit 1
fi

# out/, build/ et les fichiers d'archiso/ appartiennent à root
(( ${#existing[@]} )) && sudo rm -rf -- "${existing[@]}"
${grub_dirty} && sed -i "s/^PACKARCH_VERSION=\".*\"$/${grub_version}/" "${grub_cfg}"

echo "Projet nettoyé."
