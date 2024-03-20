
ROOT_DIR  :=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VERSION   ?= $(shell git describe --candidates=50 --abbrev=0 --tags 2>/dev/null || echo "v0.1.0" )
VM_NAME   ?= tangent-0
REPO      ?= ghcr.io/frelon/tangent
ELEMENTAL ?= ghcr.io/rancher/elemental-toolkit/elemental-cli:v2.0.0
DOCKER    ?= docker
ARCH      ?= x86_64
PLATFORM  ?= linux/$(ARCH)
DISKSIZE  ?=20G
QCOW2     ?=$(ROOT_DIR)/build/tangent-$(ARCH).qcow2

.PHONY: build
build:
	@echo Building Tangent-${ARCH} disk
	mkdir -p build
	docker build --load --build-arg ELEMENTAL_IMAGE=${ELEMENTAL} --build-arg REPO=${REPO} --build-arg VERSION=${VERSION} -t ${REPO}:${VERSION} .
	$(DOCKER) run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(ROOT_DIR)/build:/build \
		$(ELEMENTAL) build-disk \
			--debug \
			--local \
			--expandable \
			-n tangent-$(ARCH) \
			-o /build/ \
			--platform $(PLATFORM) \
			--system $(REPO):$(VERSION)
	qemu-img convert -O qcow2 build/tangent-$(ARCH).raw build/tangent-$(ARCH).qcow2
	qemu-img resize build/tangent-$(ARCH).qcow2 $(DISKSIZE) 


.PHONY:
down:
	@./run_vm.sh stop
	@./run_vm.sh clean

.PHONY: up
up:
	@./run_vm.sh start $(QCOW2)

.PHONY: debug
debug:
	@./run_vm.sh debug $(QCOW2)



