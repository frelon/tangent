
ROOT_DIR  :=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VERSION   ?= v0.1.0
VM_NAME   ?= tangent-0
REPO      ?= ghcr.io/frelon/tangent
ELEMENTAL ?= ghcr.io/frelon/elemental-cli:overlay
DOCKER    ?= docker
ARCH      ?= x86_64
PLATFORM  ?= linux/$(ARCH)
IMAGE_SIZE?=20G
QCOW2     ?=$(ROOT_DIR)/build/tangent.$(ARCH).qcow2

.PHONY: build
build:
	@echo Building Tangent-${ARCH} disk
	mkdir -p build
	docker build --load --build-arg REPO=${REPO} --build-arg VERSION=${VERSION} -t ${REPO}:${VERSION} .
	qemu-img create -f raw build/tangent.$(ARCH).img $(IMAGE_SIZE)
	- losetup -f --show build/tangent.$(ARCH).img > .loop
	$(DOCKER) run --rm --privileged --device=$$(cat .loop):$$(cat .loop) -v /var/run/docker.sock:/var/run/docker.sock \
		--entrypoint=/bin/bash $(ELEMENTAL) -c "mount -t devtmpfs none /dev && \
		elemental --debug install --firmware efi --system.uri $(REPO):$(VERSION) --local --disable-boot-entry --platform $(PLATFORM) $$(cat .loop)"
	losetup -d $$(cat .loop)
	rm .loop
	qemu-img convert -O qcow2 build/tangent.$(ARCH).img build/tangent.$(ARCH).qcow2
	rm build/tangent.$(ARCH).img

.PHONY:
down:
	@./run_vm.sh stop
	@./run_vm.sh clean

.PHONY: up
up:
	@./run_vm.sh start $(QCOW2)
