IMAGE ?= rstudio/r-system-requirements
VARIANTS ?= jammy noble trixie sid centos7 centos8 rockylinux8 rockylinux9 rockylinux10 rhel8 rhel9 rhel10 opensuse156 fedora41 alpine-3.21 alpine-3.22 alpine-3.23 alpine-edge

RULES ?= rules/*.json

RHEL_VARIANTS = rhel8 rhel9 rhel10
ROCKY_VARIANTS = rockylinux8 rockylinux9 rockylinux10
NON_CACHED_VARIANTS = $(filter-out $(RHEL_VARIANTS) $(ROCKY_VARIANTS),$(VARIANTS))

all: build-all

define GEN_BUILD_IMAGES
build-$(variant):
	docker build --platform=linux/amd64 -t $(IMAGE):$(variant) docker/$(variant)/.

bash-$(variant):
	docker run -it --rm -v $(PWD):/work -e DIST=$(variant) -e RULES=/work/$(RULES) -e RH_ORG_ID -e RH_ACTIVATION_KEY $(IMAGE):$(variant) /bin/bash

BUILD_IMAGES += build-$(variant)
TEST_IMAGES += test-$(variant)
endef

$(foreach variant,$(VARIANTS), \
	$(eval $(GEN_BUILD_IMAGES)) \
)

# Non-RHEL, non-Rocky test targets: fresh container per rule, no shared state.
define GEN_TEST
test-$(variant):
	for rule in $(RULES); do \
		docker run --rm --platform=linux/amd64 -v $(PWD):/work -e DIST=$(variant) -e RULES=/work/$$$${rule} $(IMAGE):$(variant) /work/test/test-packages.sh || exit 1; \
	done
endef

$(foreach variant,$(NON_CACHED_VARIANTS), \
	$(eval $(GEN_TEST)) \
)

# Rocky Linux test targets: fresh container per rule, but bind-mount a
# persistent DNF cache and a dnf.conf with keepcache=1 so metadata and RPMs
# are reused across per-rule containers. No shared subscription — Rocky is
# unauthenticated.
define GEN_ROCKY_TEST
test-$(rocky_variant):
	mkdir -p .cache/dnf-$(rocky_variant)
	for rule in $(RULES); do \
		docker run --rm --platform=linux/amd64 \
			-v $(PWD):/work \
			-v $(PWD)/.cache/dnf-$(rocky_variant):/var/cache/dnf \
			-v $(PWD)/test/rocky-dnf.conf:/etc/dnf/dnf.conf:ro \
			-e DIST=$(rocky_variant) -e RULES=/work/$$$${rule} \
			$(IMAGE):$(rocky_variant) /work/test/test-packages.sh || exit 1; \
	done
endef

$(foreach rocky_variant,$(ROCKY_VARIANTS), \
	$(eval $(GEN_ROCKY_TEST)) \
)

# RHEL test targets: register once, share entitlement + DNF cache across
# per-rule containers via test/rhel-run.sh. Each rule still runs in a fresh
# container; only the subscription entitlement and DNF cache are shared.
define GEN_RHEL_TEST
test-$(rhel_variant):
	IMAGE=$(IMAGE) bash test/rhel-run.sh $(rhel_variant) "$(RULES)"
endef

$(foreach rhel_variant,$(RHEL_VARIANTS), \
	$(eval $(GEN_RHEL_TEST)) \
)

build-all: $(BUILD_IMAGES)

test-all: $(TEST_IMAGES)

update-sysreqs:
	cd test && Rscript get-sysreqs.R > sysreqs.json

print-variants:
	@echo $(VARIANTS)
