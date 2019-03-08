IMAGE ?= rstudio/r-system-requirements
VARIANTS = trusty xenial bionic jessie stretch centos6 centos7 opensuse42

all: build-all

define GEN_BUILD_IMAGES
build-$(variant):
	docker build -t $(IMAGE):$(variant) docker/$(variant)/.

BUILD_IMAGES += build-$(variant)
endef

$(foreach variant,$(VARIANTS), \
	$(eval $(GEN_BUILD_IMAGES)) \
)

build-all: $(BUILD_IMAGES)
