BASE_BRANCH ?= devel
OCM_BASE_BRANCH ?= main
IMAGES ?= shipyard-dapper-base shipyard-linting nettest
MULTIARCH_IMAGES ?= nettest
PLATFORMS ?= linux/amd64,linux/arm64
NON_DAPPER_GOALS += images multiarch-images
SHELLCHECK_ARGS := scripts/shared/lib/*
FOCUS ?=
SKIP ?=
PLUGIN ?=

export BASE_BRANCH OCM_BASE_BRANCH

ifneq (,$(DAPPER_HOST_ARCH))

# Running in Dapper

ifneq (,$(filter ovn,$(_using)))
SETTINGS ?= $(DAPPER_SOURCE)/.shipyard.e2e.ovn.yml
else
SETTINGS ?= $(DAPPER_SOURCE)/.shipyard.e2e.yml
endif

override E2E_ARGS += --nolazy_deploy cluster1

include Makefile.inc

# Prevent rebuilding images inside dapper since they're already built outside it in Shipyard's case
package/.image.nettest package/.image.shipyard-dapper-base: ;

# Project-specific targets go here
deploy: package/.image.nettest

e2e: $(VENDOR_MODULES) clusters

else

# Not running in Dapper

export SCRIPTS_DIR=./scripts/shared

include Makefile.images
include Makefile.versions

# Shipyard-specific starts
# We need to ensure images, including the Shipyard base image, are updated
# before we start Dapper
clusters deploy deploy-latest e2e golangci-lint post-mortem print-version unit upgrade-e2e: images

.DEFAULT_GOAL := lint
# Shipyard-specific ends

include Makefile.dapper

# Make sure linting goals have up-to-date linting image
$(LINTING_GOALS): package/.image.shipyard-linting

script-test: .dapper images
	-docker network create -d bridge kind
	$(RUN_IN_DAPPER) $(SCRIPT_TEST_ARGS)

.PHONY: script-test

endif
