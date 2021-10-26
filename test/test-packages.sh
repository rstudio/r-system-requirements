#!/bin/bash
set -euo pipefail

# Determine the directory where this script resides
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

declare -A os_identifiers=(
    [trusty]='ubuntu'
    [xenial]='ubuntu'
    [bionic]='ubuntu'
    [focal]='ubuntu'
    [jessie]='debian'
    [stretch]='debian'
    [centos7]='centos'
    [centos8]='centos'
    [rhel6]='redhat'
    [rhel7]='redhat'
    [rhel8]='redhat'
    [opensuse42]='opensuse'
    [opensuse15]='opensuse'
    [opensuse152]='opensuse'
    [opensuse153]='opensuse'
    [sle12]='sle'
    [sle15]='sle'
    [sle152]='sle'
    [sle153]='sle'
)

declare -A versions=(
    [trusty]='14.04'
    [xenial]='16.04'
    [bionic]='18.04'
    [focal]='20.04'
    [jessie]='8'
    [stretch]='9'
    [centos7]='7'
    [centos8]='8'
    [rhel6]='6'
    [rhel7]='7'
    [rhel8]='8'
    [opensuse42]='42.3'
    [opensuse15]='15.0'
    [opensuse152]='15.2'
    [opensuse153]='15.3'
    [sle12]='12.3'
    [sle15]='15.0'
    [sle152]='15.2'
    [sle153]='15.3'
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
    for rule in $rules; do
        # Find all dependencies for this distro
        deps=$(find_dependencies "$rule" $dist $version)
        jq -c ".[]" <<< "$deps" | while read dep; do
            # Run any pre-install commands (e.g. adding a repo)
            pre_install_cmds=$(echo "$dep" | jq ".pre_install[]?")
            pkgs=$(echo "$dep" | jq -r ".packages[]")
            jq -c <<< "$pre_install_cmds" | while read cmd; do
                run_extra_cmd "$cmd"
            done
            # Test that all packages are valid
            for pkg in $pkgs; do
                $test_package $pkg
            done
        done
    done
}

RULES=${RULES:-rules/*.json}
VER=${versions[$DIST]:-$VER}
DIST=${os_identifiers[$DIST]:-$DIST}

test_packages "$RULES" $DIST $VER