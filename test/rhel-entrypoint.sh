#!/bin/bash
set -euo pipefail

if [[ -z "${RH_ORG_ID:-}" || -z "${RH_ACTIVATION_KEY:-}" ]]; then
    echo "error: RH_ORG_ID and RH_ACTIVATION_KEY must be set to run RHEL tests" >&2
    exit 1
fi

cleanup() {
    subscription-manager unregister || true
    subscription-manager clean || true
}
trap cleanup EXIT

subscription-manager register --org="$RH_ORG_ID" --activationkey="$RH_ACTIVATION_KEY"
dnf config-manager --set-disabled "*ubi*"

bash -x  /work/test/test-packages.sh
