#!/bin/bash
set -euo pipefail

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

find_packages() {
    rule=$1
    dist=$2
    pkgs=$(jq < "$rule" | jq ".dependencies | map(select(.constraints[] | .distribution == \"$dist\") | .packages[])")
    echo $pkgs
}

test_packages() {
    rules=$1
    dist=$2
    for rule in $rules; do
        pkgs=$(find_packages "$rule" $dist)
        test_package="test_package_${dist}"
        echo $pkgs | jq -r .[] | while read pkg; do
            $test_package $pkg
        done
    done
}

RULES=${RULES:-rules/*.json}
DIST=${os_identifiers[$DIST]:-$DIST}

test_packages "$RULES" $DIST