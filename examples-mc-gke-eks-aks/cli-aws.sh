#!/bin/bash

set -e

# aws, eksctl
if ! [ -x "$(command -v aws)" ]; then

    mkdir -p ~/_downloads
    pushd ~/_downloads

    curl --silent -O https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
    unzip awscli-exe-linux-x86_64.zip > /dev/null
    ./aws/install -i ~/bin -b ~/bin

    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C ~/bin

    popd
fi
