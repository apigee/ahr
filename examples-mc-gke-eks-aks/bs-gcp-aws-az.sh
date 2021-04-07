#!/bin/bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $BASEDIR/lib.sh

set -e

check_commands "az"

export TF_DIR=${TF_DIR:-$BASEDIR/infra-gcp-aws-az-tf}

$BASEDIR/bs-gcp-aws.sh

if [ ! -f ~/.ssh/id_az ]; then
  ssh-keygen -t rsa -C "az-key" -f ~/.ssh/id_az  -P ""
fi
export AZ_USERNAME=azureuser
export AZ_SSH_PUB_KEY_FILE=~/.ssh/id_az.pub



# source gcp and aws vars to have if they are used in az vars
GCP_VARS=$BASEDIR/mc-gcp-networking.env
source $GCP_VARS
AWS_VARS=$BASEDIR/mc-aws-networking.env
source $AWS_VARS


AZ_VARS=$BASEDIR/mc-az-networking.env

AZ_TFVARS=$TF_DIR/az.auto.tfvars

source $AZ_VARS

cat <<EOF > "$AZ_TFVARS"
az_username = "$AZ_USERNAME"
az_ssh_pub_key_file = "$AZ_SSH_PUB_KEY_FILE"

EOF
awk -f $BASEDIR/tf-env-to-tfvars.awk "$AZ_VARS" >> "$AZ_TFVARS"
