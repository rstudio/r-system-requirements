#!/bin/bash
set -euo pipefail

# Determine the directory where this script resides
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

declare -A os_identifiers=(
    [bionic]='ubuntu'
    [focal]='ubuntu'
    [jammy]='ubuntu'
    [buster]='debian'
    [bullseye]='debian'
    [sid]='debian'
    [centos7]='centos'
    [centos8]='centos'
    [rockylinux9]='rockylinux'
    [rhel7]='redhat'
    [rhel8]='redhat'
    [rhel9]='redhat'
    [opensuse153]='opensuse'
    [opensuse154]='opensuse'
    [sle153]='sle'
    [sle154]='sle'
    [fedora36]='fedora'
    [fedora37]='fedora'
    [fedora38]='fedora'
)

declare -A versions=(
    [bionic]='18.04'
    [focal]='20.04'
    [jammy]='22.04'
    [buster]='10'
    [bullseye]='11'
    [sid]='unstable'
    [centos7]='7'
    [centos8]='8'
    [rockylinux9]='9'
    [rhel7]='7'
    [rhel8]='8'
    [rhel9]='9'
    [opensuse153]='15.3'
    [opensuse154]='15.4'
    [sle153]='15.3'
    [sle154]='15.4'
    [fedora36]='36'
    [fedora37]='37'
    [fedora38]='38'
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
            sats=$(echo "$dep" | jq -r ".satisfy[]?")
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
