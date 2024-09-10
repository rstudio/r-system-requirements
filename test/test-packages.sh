#!/bin/bash
set -euo pipefail

# Determine the directory where this script resides
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

declare -A os_identifiers=(
    [focal]='ubuntu'
    [jammy]='ubuntu'
    [noble]='ubuntu'
    [buster]='debian'
    [bullseye]='debian'
    [bookworm]='debian'
    [sid]='debian'
    [centos7]='centos'
    [centos8]='centos'
    [rockylinux9]='rockylinux'
    [rhel7]='redhat'
    [rhel8]='redhat'
    [rhel9]='redhat'
    [opensuse155]='opensuse'
    [opensuse156]='opensuse'
    [sle155]='sle'
    [sle156]='sle'
    [fedora38]='fedora'
    [fedora39]='fedora'
    [fedora40]='fedora'
    [alpine-3.17]='alpine'
    [alpine-3.18]='alpine'
    [alpine-3.19]='alpine'
    [alpine-3.20]='alpine'
    [alpine-edge]='alpine'
)

declare -A versions=(
    [focal]='20.04'
    [jammy]='22.04'
    [noble]='24.04'
    [buster]='10'
    [bullseye]='11'
    [bookworm]='12'
    [sid]='unstable'
    [centos7]='7'
    [centos8]='8'
    [rockylinux9]='9'
    [rhel7]='7'
    [rhel8]='8'
    [rhel9]='9'
    [opensuse155]='15.5'
    [opensuse156]='15.6'
    [sle155]='15.5'
    [sle156]='15.6'
    [fedora38]='38'
    [fedora39]='39'
    [fedora40]='40'
    [alpine-3.17]='3.17'
    [alpine-3.18]='3.18'
    [alpine-3.19]='3.19'
    [alpine-3.20]='3.20'
    [alpine-edge]='edge'
)

test_package_ubuntu() {
    pkg=$1
    found=$(apt-cache search --names-only "^${pkg}$")
    if [ -z "$found" ]; then
        echo "$pkg | error: package not found"
        exit 1
    else
        echo "$pkg | $found"
    fi
}

test_package_debian() {
    # Same as Ubuntu
    test_package_ubuntu "$@"
}

test_package_centos() {
    pkg=$1
    printf "$pkg | "
    found=$(yum list -q "$pkg")
    echo $found
}

test_package_rockylinux() {
    # Same as CentOS
    test_package_centos "$@"
}

test_package_redhat() {
    # Same as CentOS
    test_package_centos "$@"
}

test_package_opensuse() {
    pkg=$1
    found=$(zypper info "$pkg")
    echo "$found"
    if [[ "$found" == *"not found." ]]; then
        exit 1
    fi
}

test_package_sle() {
    # Same as openSUSE
    test_package_opensuse "$@"
}

test_package_fedora() {
    pkg=$1
    printf "$pkg | "
    # We only use the local cache, because metadata queries are slow,
    # especially for rawhide
    found=$(yum -Cq repoquery --whatprovides "$pkg")
    if [[ -z "$found" ]]; then
	exit 1
    fi
    echo $found
}

test_package_alpine() {
    pkg=$1
    printf "$pkg | "
    found=$(apk info -d $pkg | sed -n 2p)
    if [[ -z "$found" ]]; then
        exit 1
    fi
    echo $found
}

test_satisfy_ubuntu() {
    sat="$1"
    ver="$2"
    if [[ "$ver" == "18.04" ]]; then
        return
    fi
    if ! apt-get satisfy -s "$sat" >/dev/null; then
        echo "$sat | error: cannot satisfy"
        exit 1
    else
        echo "$sat | satisfied"
    fi
}

test_satisfy_debian() {
    sat="$1"
    ver="$2"
    if [[ "$ver" == "10" ]]; then
        return
    fi
    test_satisfy_ubuntu "$sat" "$ver"
}

find_dependencies() {
    rule=$1
    dist=$2
    version=$3
    deps=$(jq < "$rule" | jq ".dependencies | map(select(.constraints[] | .distribution == \"$dist\" and (.versions | . == null or contains([\"$version\"]))))")
    echo $deps
}

run_extra_cmd() {
    command=$(jq -r ".command // empty" <<< "$1")
    if [[ ! -z "$command" ]]; then
        bash -c "$command"
    fi

    script=$(jq -r ".script // empty" <<< "$1")
    if [[ ! -z "$script" ]]; then
        script_file="$DIR/../scripts/$script"
        chmod +x "$script_file"
        bash -c "$script_file"
    fi
}

test_packages() {
    rules=$1
    dist=$2
    version=$3
    test_package="test_package_${dist}"
    test_satisfy="test_satisfy_${dist}"

    for rule in $rules; do
        # Find all dependencies for this distro
        deps=$(find_dependencies "$rule" $dist $version)
        jq -c ".[]" <<< "$deps" | while read dep; do
            # Run any pre-install commands (e.g. adding a repo)
            pre_install_cmds=$(echo "$dep" | jq ".pre_install[]?")
            pkgs=$(echo "$dep" | jq -r ".packages[]")
            sats=$(echo "$dep" | jq -r ".apt_satisfy[]?")
            jq -c <<< "$pre_install_cmds" | while read cmd; do
                run_extra_cmd "$cmd"
            done
            # Test that all packages are valid
            for pkg in $pkgs; do
                $test_package $pkg
            done
            if [ ! -z "$sats" ]; then
                echo "$sats" | while read sat; do
                    $test_satisfy "$sat" $version
                done
            fi
        done
    done
}

RULES=${RULES:-rules/*.json}
VER=${versions[$DIST]:-$VER}
DIST=${os_identifiers[$DIST]:-$DIST}

test_packages "$RULES" $DIST $VER
