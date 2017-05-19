# if using docker PROJECT should be your username
PROJECT = myproject
NAME = manageiq-base
VERSION = 0.1
REGISTRY=`minishift openshift registry`

.PHONY: all build tag_latest release

all: build

build:
	docker build -t $(NAME):$(VERSION) --rm .

tag_latest:
	docker tag $(NAME):$(VERSION) $(REGISTRY)/$(PROJECT)/$(NAME):latest

release: tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(REGISTRY)/$(PROJECT)/$(NAME)
	@echo "*** Don't forget to create a tag by creating an official GitHub release."
