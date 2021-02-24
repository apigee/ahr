#!/bin/bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# aws, eksctl
curl -O https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip awscli-exe-linux-x86_64.zip
mkdir ~/bin
./aws/install -i ~/bin -b ~/bin


mkdir ~/.aws
cat <<EOF > ~/.aws/credentials 

[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY

region = $AWS_REGION
EOF

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C ~/bin


ahr-verify-ctl prereqs-install-yq
