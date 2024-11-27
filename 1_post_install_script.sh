#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154

current_dir="$(pwd)"
unypkg_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
unypkg_root_dir="$(cd -- "$unypkg_script_dir"/.. &>/dev/null && pwd)"

cd "$unypkg_root_dir" || exit

#############################################################################################
### Start of script
unyp install python

pip3_bin=(/uny/pkg/python/*/bin/pip3)
"${pip3_bin[0]}" install --upgrade pip
"${pip3_bin[0]}" install six

#############################################################################################
### End of script

cd "$current_dir" || exit
