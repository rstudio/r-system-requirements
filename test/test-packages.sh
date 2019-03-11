#!/bin/bash
set -euo pipefail

# Determine the directory where this script resides
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

declare -A os_identifiers=(
    [trusty]='ubuntu'
    [xenial]='ubuntu'
    [bionic]='ubuntu'
    [jessie]='debian'
    [stretch]='debian'
    [centos6]='centos'
    [centos7]='centos'
    [opensuse42]='opensuse'
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
    test_package_ubuntu "$@"
}

test_package_centos() {
    pkg=$1
    printf "$pkg | "
    found=$(yum list -q "$pkg")
    echo $found
}

test_package_opensuse() {
    pkg=$1
    found=$(zypper info "$pkg")
    echo "$found"
    if [[ "$found" == *"not found." ]]; then
        exit 1
    fi
}

find_dependencies() {
    rule=$1
    dist=$2
    deps=$(jq < "$rule" | jq ".dependencies | map(select(.constraints[] | .distribution == \"$dist\"))")
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
    test_package="test_package_${dist}"
    for rule in $rules; do
        # Find all dependencies for this distro
        deps=$(find_dependencies "$rule" $dist)
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
DIST=${os_identifiers[$DIST]:-$DIST}

test_packages "$RULES" $DIST