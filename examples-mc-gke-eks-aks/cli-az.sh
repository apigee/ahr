#!/bin/bash

set -e

# rust to compile cryptography modules
if ! [ -x "$(command -v rustc)" ]; then
    echo "rustc is not found. installing it..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y -q
fi

echo "install azure-cli into your ~ directory"
pip3 install azure-cli > /dev/null

echo "execute az login to authenticate"



