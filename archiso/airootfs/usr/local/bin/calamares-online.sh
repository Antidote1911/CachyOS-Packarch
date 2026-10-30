#!/bin/bash
#
# Started by Packarch Hello ("Launch installer"). Online installation: the
# packages are downloaded (up to date) by pacstrap, then the XFCE settings of
# the live ISO are copied to the target (packages@online, shellprocess@live_config).
# Calamares comes from the local repository of the ISO build (calamares/), it
# must not be replaced by the one of the CachyOS repository.

main() {
    # Remove current keyring first, to complete initiate it
    sudo rm -rf /etc/pacman.d/gnupg
    # We are using this, because archlinux is signing the keyring often with a newly created keyring
    # This results into a failed installation for the user.
    # Installing archlinux-keyring fails due not being correctly signed
    # Mitigate this by installing the latest archlinux-keyring on the ISO, before starting the installation
    # The issue could also happen, when the installation does rank the mirrors and then a "faulty" mirror gets used
    sudo pacman -Sy --noconfirm archlinux-keyring cachyos-keyring
    # Also populate the keys, before starting the Installer, to avoid above issue
    sudo pacman-key --init
    sudo pacman-key --populate archlinux cachyos
    # Also use timedatectl to sync the time with the hardware clock
    # There has been a bunch of reports, that the keyring was created in the future
    # Syncing appears to fix it
    timedatectl set-ntp true

    local progname="$(basename "$0")"
    local log="/home/liveuser/cachy-install.log"
    local mode="online"

    local SYSTEM=""

    if [ -d /sys/firmware/efi ]; then
        SYSTEM="UEFI SYSTEM"
    else
        SYSTEM="BIOS/MBR SYSTEM"
    fi

    local ISO_VERSION="$(cat /etc/version-tag)"
    echo "USING ISO VERSION: ${ISO_VERSION}"

    # Get Hardware Informations
    inxi -F > "$log"

    cat <<EOF >> "$log"
########## $log by $progname
########## Started (UTC): $(date -u "+%x %X")
########## ISO version: $ISO_VERSION
########## System: $SYSTEM
########## Mode: $mode
EOF

    # Our configuration (settings and module configurations) is in
    # /etc/xdg/calamares, read before /etc/calamares with -X. Calamares only
    # uses /etc/xdg when XDG_CONFIG_DIRS is set (pkexec clears it). The copy
    # in /etc/calamares keeps our sequence of pages and jobs in any case: if
    # /etc/xdg were not read, the log would show "No config file for" warnings
    # for our module configurations.
    sudo cp "/etc/xdg/calamares/settings_${mode}.conf" /etc/xdg/calamares/settings.conf
    sudo cp "/etc/xdg/calamares/settings_${mode}.conf" /etc/calamares/settings.conf
    exec pkexec-wrapper env XDG_CONFIG_DIRS=/etc/xdg calamares -X -D6 >> "$log" 2>&1
}

main "$@"
