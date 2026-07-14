#!/bin/bash
# Run r-system-requirements rule tests on a RHEL image, registering the
# subscription once for the whole run and reusing it across per-rule
# containers.
#
# Strategy: register inside a throwaway container, `docker commit` that
# container to a temporary image tagged with this run's PID, then spawn a
# fresh minimal container per rule from that image. Only the shared state
# is the entitlement baked into the temp image; each rule still runs in a
# fresh container with no residual state from previous rules. A host-side
# DNF cache dir is bind-mounted to avoid repeated metadata downloads.
#
# On any exit (EXIT, INT, TERM, ERR) the trap unregisters the subscription
# and removes the temp image, so the seat is released on Red Hat's side.
# SIGKILL / power loss will skip the trap; release the seat manually in
# the Red Hat customer portal in that case, and `docker rmi` any leftover
# `${IMAGE}:${VARIANT}-registered-*` tag.

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "usage: $0 VARIANT RULES" >&2
    echo "  VARIANT: rhel8 | rhel9 | rhel10" >&2
    echo "  RULES:   shell glob or space-separated list of rule paths (relative to repo root)" >&2
    exit 2
fi

VARIANT=$1
RULES=$2
IMAGE=${IMAGE:-rstudio/r-system-requirements}
IMG="${IMAGE}:${VARIANT}"
REG_IMG="${IMAGE}:${VARIANT}-registered-$$"

if [[ -z "${RH_ORG_ID:-}" || -z "${RH_ACTIVATION_KEY:-}" ]]; then
    echo "error: RH_ORG_ID and RH_ACTIVATION_KEY must be set to run RHEL tests" >&2
    exit 1
fi

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CACHE_DIR="$REPO_ROOT/.cache/dnf-$VARIANT"
mkdir -p "$CACHE_DIR"

REG_CONTAINER=""

# cleanup is a subshell (parens, not braces) so `set +e` doesn't leak into
# the main script when the trap fires mid-run.
cleanup() (
    set +e
    if [[ -n "$REG_CONTAINER" ]]; then
        docker rm -f "$REG_CONTAINER" >/dev/null 2>&1
    fi
    if docker image inspect "$REG_IMG" >/dev/null 2>&1; then
        # Unregister in a throwaway container spawned from the registered image,
        # so the seat is released on Red Hat's side. Best-effort.
        docker run --rm --platform=linux/amd64 --stop-timeout=5 "$REG_IMG" bash -c '
            subscription-manager unregister
            subscription-manager clean
        '
        docker rmi -f "$REG_IMG" >/dev/null 2>&1
    fi
)
trap cleanup EXIT INT TERM ERR

# 1. Spin up a container, register it, tune dnf for caching, commit it to REG_IMG.
REG_CONTAINER=$(docker run -d --platform=linux/amd64 \
    -e RH_ORG_ID -e RH_ACTIVATION_KEY \
    "$IMG" sleep infinity)

docker exec "$REG_CONTAINER" bash -c '
    set -euo pipefail
    subscription-manager register --org="$RH_ORG_ID" --activationkey="$RH_ACTIVATION_KEY"
    dnf config-manager --set-disabled "*ubi*"
    # Keep downloaded RPMs in /var/cache/dnf so the host-mounted cache dir
    # avoids repeat downloads across per-rule containers.
    echo "keepcache=1" >> /etc/dnf/dnf.conf
'

docker commit "$REG_CONTAINER" "$REG_IMG" >/dev/null
docker rm -f "$REG_CONTAINER" >/dev/null
REG_CONTAINER=""

# 2. Per-rule loop: fresh container per rule, spawned from the registered image.
# The DNF cache is bind-mounted so metadata + RPMs are reused across rules.
for rule in $RULES; do
    docker run --rm --platform=linux/amd64 \
        -v "$REPO_ROOT:/work" \
        -v "$CACHE_DIR:/var/cache/dnf" \
        -e DIST=$VARIANT -e RULES="/work/$rule" \
        "$REG_IMG" /work/test/test-packages.sh
done
