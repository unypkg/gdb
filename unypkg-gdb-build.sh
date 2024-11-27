#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154

set -vx

######################################################################################################################
### Setup Build System and GitHub

##apt install -y autopoint

wget -qO- uny.nu/pkg | bash -s buildsys

### Installing build dependencies
unyp install python expat openssl

pip3_bin=(/uny/pkg/python/*/bin/pip3)
"${pip3_bin[0]}" install --upgrade pip
"${pip3_bin[0]}" install six

### Getting Variables from files
UNY_AUTO_PAT="$(cat UNY_AUTO_PAT)"
export UNY_AUTO_PAT
GH_TOKEN="$(cat GH_TOKEN)"
export GH_TOKEN

source /uny/git/unypkg/fn
uny_auto_github_conf

######################################################################################################################
### Timestamp & Download

uny_build_date

mkdir -pv /uny/sources
cd /uny/sources || exit

pkgname="gdb"
pkggit="https://sourceware.org/git/binutils-gdb.git refs/tags/*"
gitdepth="--depth=1"

### Get version info from git remote
# shellcheck disable=SC2086
latest_head="$(git ls-remote --refs --tags --sort="v:refname" $pkggit | grep -E "gdb-[0-9.]+-release$" | tail --lines=1)"
latest_ver="$(echo "$latest_head" | grep -o "gdb-[0-9.].*" | sed -e "s|gdb-||" -e "s|-release||")"
latest_commit_id="$(echo "$latest_head" | cut --fields=1)"

version_details

# Release package no matter what:
echo "newer" >release-"$pkgname"

git_clone_source_repo

cd "$pkg_git_repo_dir" || exit
./configure --disable-binutils --disable-ld --disable-gold --disable-gas --disable-sim --disable-gprof --disable-gprofng --disable-intl
rm -rf binutils ld gold gas sim gprof gprofng
cd /uny/sources || exit

archiving_source

######################################################################################################################
### Build

# unyc - run commands in uny's chroot environment
# shellcheck disable=SC2154
unyc <<"UNYEOF"
set -vx
source /uny/git/unypkg/fn

pkgname="gdb"

version_verbose_log_clean_unpack_cd
get_env_var_values
get_include_paths

####################################################
### Start of individual build script

unset LD_RUN_PATH

mkdir build
cd build || exit

python3_bin=(/uny/pkg/python/*/bin/python3)

../configure \
    --prefix=/uny/pkg/"$pkgname"/"$pkgver" \
    --with-system-readline \
    --with-python="${python3_bin[0]}" \
    --without-auto-load-safe-path \
    --disable-binutils --disable-ld --disable-gold --disable-gas --disable-sim --disable-gprof --disable-gprofng --disable-intl

make -j"$(nproc)"

make -j"$(nproc)" -C gdb install
make -j"$(nproc)" -C gdbserver install

####################################################
### End of individual build script

add_to_paths_files
dependencies_file_and_unset_vars
cleanup_verbose_off_timing_end
UNYEOF

######################################################################################################################
### Packaging

package_unypkg
