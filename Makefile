.SILENT:

help:
	{ grep --extended-regexp '^[a-zA-Z_-]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) || true; } \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-15s\033[0m%s\n", $$1, $$2 }'

dev: # local development with docker-compose
	./make.sh dev

build: # build production image
	./make.sh build

prod: # run production image locally
	./make.sh prod

push: # push production image to docker hub
	./make.sh push

tf-init: # terraform init
	./make.sh tf-init

tf-validate: # terraform format + validate
	./make.sh tf-validate

tf-apply: # terraform plan + apply with auto approve
	./make.sh tf-apply

tf-scale-up: # terraform scale up to 3 instances
	./make.sh tf-scale-up

tf-scale-down: # terraform scale down to 1 instance (warn: target deregistration take time)
	./make.sh tf-scale-down
	
tf-destroy: # terraform destroy all resources
	./make.sh tf-destroy
