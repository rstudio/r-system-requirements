IMAGE ?= rstudio/r-system-requirements
VARIANTS ?= focal jammy noble bookworm sid centos7 centos8 rockylinux8 rockylinux9 rockylinux10 opensuse156 fedora41 alpine-3.19 alpine-3.20 alpine-3.21 alpine-edge

RULES ?= rules/*.json

all: build-all

define GEN_BUILD_IMAGES
build-$(variant):
	docker build --platform=linux/amd64 -t $(IMAGE):$(variant) docker/$(variant)/.

test-$(variant):
	for rule in $(RULES); do \
		docker run --rm --platform=linux/amd64 -v $(PWD):/work -e DIST=$(variant) -e RULES=/work/$$$${rule} $(IMAGE):$(variant) /work/test/test-packages.sh || exit 1; \
	done

bash-$(variant):
	docker run -it --rm -v $(PWD):/work -e DIST=$(variant) -e RULES=/work/$(RULES) $(IMAGE):$(variant) /bin/bash

BUILD_IMAGES += build-$(variant)
TEST_IMAGES += test-$(variant)
endef

$(foreach variant,$(VARIANTS), \
	$(eval $(GEN_BUILD_IMAGES)) \
)

build-all: $(BUILD_IMAGES)

test-all: $(TEST_IMAGES)

update-sysreqs:
	cd test && Rscript get-sysreqs.R > sysreqs.json

print-variants:
	@echo $(VARIANTS)
