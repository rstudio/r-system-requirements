#!/bin/bash
set -euo pipefail

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

find_packages() {
    file=$1
    dist=$2
    pkgs=$(jq < "$file" | jq ".dependencies | map(select(.constraints[] | .distribution == \"$dist\") | .packages[])")
    echo $pkgs
}

test_packages() {
    files=$1
    dist=$2
    for file in $files; do
        pkgs=$(find_packages "$file" $dist)
        test_package="test_package_${dist}"
        echo $pkgs | jq -r .[] | while read pkg; do
            $test_package $pkg
        done
    done
}

FILES=${FILES:=rules/*.json}
DIST=${DIST:=ubuntu}

test_packages "$FILES" $DIST