#!/bin/bash



if ! [ -x "$(command -v terraform)" ]; then

    mkdir -p ~/_downloads
    pushd ~/_downloads

    TERRAFORM_RELEASE=https://releases.hashicorp.com/terraform/0.14.6/terraform_0.14.6_linux_amd64.zip

    curl --silent -L $TERRAFORM_RELEASE -o terraform.zip
    unzip ~/_downloads/terraform.zip -d ~/bin
    popd
fi

