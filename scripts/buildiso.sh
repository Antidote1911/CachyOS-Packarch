#!/bin/bash
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

set -e
# scripts/ holds this script and its util*.sh; src_dir is the repository root
# (archiso/, localrepo/, out/), whatever the current directory
lib_dir="$(dirname "$(readlink -f "$0")")"
src_dir="$(dirname "$lib_dir")"
cd "$src_dir"
[[ -r ${lib_dir}/util-msg.sh ]] && source ${lib_dir}/util-msg.sh
import ${lib_dir}/util.sh

# setting of the general parameters
work_dir="${src_dir}/build"
outFolder="${src_dir}/out"

build_list_iso="desktop"
clean_first=true
verbose=false
build_in_ram=false
remove_build_dir=false

usage() {
    echo "Usage: ${0##*/} [options]"
    echo '    -c                 Disable clean work dir'
    echo '    -r                 Enable building in RAM on systems with more than 23GB RAM'
    echo '    -w                 Remove build directory (not the ISO) after ISO file is built'
    echo "    -p <profile>       Buildset or profile [default: ${build_list_iso}]"
    echo '    -v                 Verbose output to log file, show profile detail (-q)'
    echo '    -h                 This help'
    echo ''
    echo ''
    exit $1
}

orig_argv=("$@")

opts='p:cvhrw'

while getopts "${opts}" arg; do
    case "${arg}" in
        c) clean_first=false ;;
        p) build_list_iso="$OPTARG" ;;
        r) build_in_ram=true ;;
        w) remove_build_dir=true ;;
        v) verbose=true ;;
        h|?) usage 0 ;;
        *) echo "invalid argument '${arg}'"; usage 1 ;;
    esac
done

shift $(($OPTIND - 1))

timer_start=$(get_timer)

#check_root "$0" "${orig_argv[@]}"

# Build ISO in RAM if RAM amount is greater than 23GB. This would speed up build process and extend disk lifetime 
if [[ "$build_in_ram" == "true" ]] && [[ $(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}') -gt 23 ]]; then
    work_dir="$(mktemp -d --suffix="-packarch-iso")"
fi

prepare_dir "${work_dir}"

import ${lib_dir}/util-iso.sh
import ${lib_dir}/util-iso-mount.sh

check_requirements

for sig in TERM HUP QUIT; do
    trap "trap_exit $sig \"$(gettext "%s signal caught. Exiting...")\" \"$sig\"" "$sig"
done
trap 'trap_exit INT "$(gettext "Aborted by user! Exiting...")"' INT
trap 'trap_exit USR1 "$(gettext "An unknown error has occurred. Exiting...")"' ERR
# Normal end (status 0): unmount only, without the error message
trap 'if (( $? == 0 )); then umount_fs; else trap_exit EXIT "$(gettext "An unknown error has occurred. Exiting...")"; fi' EXIT

run_build "${build_list_iso}"
