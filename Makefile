
VERSION ?= v0.1.0
VM_NAME ?= tangent-0

.PHONY: build
build:
	docker build -t frallan/tangent:${VERSION}-iso -f Dockerfile.iso .
	docker build -t frallan/tangent:${VERSION} .
	docker push frallan/tangent:${VERSION}
	rm iso/usr/sbin/tangent-installer && go build -o iso/usr/sbin/tangent-installer installer.go
	sudo elemental build-iso --config-dir=./ frallan/tangent:${VERSION}-iso --local

.PHONY: down
down:
	virsh undefine --nvram ${VM_NAME}
	virsh destroy ${VM_NAME}

.PHONY: up
up:
	./run.sh ${VM_NAME}