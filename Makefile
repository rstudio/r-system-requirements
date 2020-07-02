IMAGE ?= rstudio/r-system-requirements
VARIANTS = trusty xenial bionic focal jessie stretch centos6 centos7 centos8 opensuse42 opensuse15

RULES ?= rules/*.json

all: build-all

define GEN_BUILD_IMAGES
build-$(variant):
	docker build -t $(IMAGE):$(variant) docker/$(variant)/.

test-$(variant):
	for rule in $(RULES); do \
		docker run -it --rm -v $(PWD):/work -e DIST=$(variant) -e RULES=/work/$$$${rule} $(IMAGE):$(variant) /work/test/test-packages.sh || exit 1; \
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
