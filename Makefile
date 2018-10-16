GOFLAGS :=
IMAGE_REPOSITORY_NAME ?= openshift

all build:
	go build $(GOFLAGS) ./cmd/cluster-kube-apiserver-operator
.PHONY: all build

verify-govet:
	go vet $(GOFLAGS) ./...
.PHONY: verify-govet

verify: verify-govet
	hack/verify-gofmt.sh
	hack/verify-codegen.sh
	hack/verify-generated-bindata.sh
.PHONY: verify

test test-unit:
ifndef JUNITFILE
	go test $(GOFLAGS) -race ./...
else
ifeq (, $(shell which gotest2junit 2>/dev/null))
$(error gotest2junit not found! Get it by `go get -u github.com/openshift/release/tools/gotest2junit`.)
endif
	go test $(GOFLAGS) -race -json ./... | gotest2junit > $(JUNITFILE)
endif
.PHONY: test-unit

images:
	imagebuilder -f Dockerfile -t $(IMAGE_REPOSITORY_NAME)/origin-cluster-kube-apiserver-operator .
.PHONY: images

clean:
	$(RM) ./cluster-kube-apiserver-operator
.PHONY: clean

, := ,
IMAGES ?= cluster-kube-apiserver-operator
QUOTED_IMAGES=\"$(subst $(,),\"$(,)\",$(IMAGES))\"

# Rebuild the origin-release:v4.0 image using the local images.
# Usage:
# $ IMAGES=cluster-kube-apiserver-operator,cluster-kube-controller-manager-operator,cluster-kube-scheduler-operator IMAGE_REPOSITORY_NAME=foo make origin-release
origin-release:
	docker pull registry.svc.ci.openshift.org/openshift/origin-release:v4.0
	bash -c 'imagebuilder -f <(sed "s/IMAGE_REPOSITORY_NAME/$(IMAGE_REPOSITORY_NAME)/g;s/IMAGES/$(QUOTED_IMAGES)/g" hack/lib/Dockerfile-origin-release) -t "$(IMAGE_REPOSITORY_NAME)/origin-release:latest" hack'
	@echo
	@echo "To install:"
	@echo
	@echo "  IMAGE_REPOSITORY_NAME=$(IMAGE_REPOSITORY_NAME) make images"
	@echo "  docker push $(IMAGE_REPOSITORY_NAME)/origin-cluster-kube-apiserver-operator"
	@echo "  OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=docker.io/$(IMAGE_REPOSITORY_NAME)/origin-release:latest bin/openshift-install cluster --log-level=debug"
