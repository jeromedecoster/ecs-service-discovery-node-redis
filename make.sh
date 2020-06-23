#!/bin/bash


#
# variables
#

# AWS variables
PROFILE=default
REGION=eu-west-3
DOCKER_IMAGE=jeromedecoster/vote
# terraform
export TF_VAR_profile=$PROFILE


# the directory containing the script file
dir="$(cd "$(dirname "$0")"; pwd)"
cd "$dir"


log()   { echo -e "\e[30;47m ${1^^} \e[0m ${@:2}"; }        # $1 uppercase background white
info()  { echo -e "\e[48;5;28m ${1^^} \e[0m ${@:2}"; }      # $1 uppercase background green
warn()  { echo -e "\e[48;5;202m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background orange
error() { echo -e "\e[48;5;196m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background red



# log $1 in underline then $@ then a newline
under() {
    local arg=$1
    shift
    echo -e "\033[0;4m${arg}\033[0m ${@}"
    echo
}

usage() {
    under usage 'call the Makefile directly: make dev
      or invoke this file directly: ./make.sh dev'
}

# local development with docker-compose
dev() {
    docker-compose \
        --file docker-compose.dev.yml \
        --project-name compose_dev \
        up
}

# build production image
build() {
    VERSION=$(jq --raw-output '.version' vote/package.json)
    docker image build \
        --file vote/prod/Dockerfile \
        --tag $DOCKER_IMAGE:latest \
        --tag $DOCKER_IMAGE:$VERSION \
        ./vote
}

# run production image locally
prod() {
    docker-compose \
        --project-name compose_prod \
        up
}

# push production image to docker hub
push() {
    VERSION=$(jq --raw-output '.version' vote/package.json)
    docker push $DOCKER_IMAGE:latest
    docker push $DOCKER_IMAGE:$VERSION
}

# terraform init
tf-init() {
    cd "$dir/infra"
    terraform init
}

# terraform format + validate
tf-validate() {
    cd "$dir/infra"
    terraform fmt -recursive
	terraform validate
}

# terraform plan + apply with auto approve
tf-apply() {
    cd "$dir/infra"
    terraform plan \
        -out=terraform.plan

    terraform apply \
        -auto-approve \
        terraform.plan
}

# terraform scale up to 3 instances
tf-scale-up() {
    export TF_VAR_desired_count=3
    tf-apply
}

# terraform scale down to 1 instance (warn: target deregistration take time)
tf-scale-down() {
    export TF_VAR_desired_count=1
    tf-apply
}

# terraform destroy all resources
tf-destroy() {
    cd "$dir/infra"
    terraform destroy \
        -auto-approve
}

# if `$1` is a function, execute it. Otherwise, print usage
# compgen -A 'function' list all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep $1)
[[ -n $FUNC ]] && { info execute $1; eval $1; } || usage;
exit 0