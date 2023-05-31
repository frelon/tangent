
VERSION ?= v0.1.0
VM_NAME ?= tangent-0
REPO    ?= ghcr.io/frelon/tangent

.PHONY: build
build:
	mkdir -p build
	docker build -t ${REPO}:${VERSION}-iso -f Dockerfile.iso .
	docker build --build-arg REPO=${REPO} --build-arg VERSION=${VERSION} -t ${REPO}:${VERSION} .
	docker push ${REPO}:${VERSION}
	rm -f iso/usr/sbin/tangent-installer && go build -o iso/usr/sbin/tangent-installer ./cmd/installer/installer.go
	sudo elemental build-iso --output=build --config-dir=./ ${REPO}:${VERSION}-iso --local --debug

.PHONY: down
down:
	virsh undefine --nvram ${VM_NAME}
	virsh destroy ${VM_NAME}

.PHONY: up
up:
	./run.sh ${VM_NAME}
