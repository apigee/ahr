#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $BASEDIR/lib.sh

# just bootstrap, nothing noughty, actually


export PROJECT=$(gcloud projects list|grep qwiklabs-gcp|awk '{print $1}')
export GCP_OS_USERNAME=$(gcloud config get-value account | awk -F@ '{print $1}' )

#
ssh-keygen -t rsa -C "gcp-key" -f ~/.ssh/id_gcp  -P ""
export GCP_SSH_PUB_KEY_FILE=~/.ssh/id_gcp.pub

ssh-keygen -t rsa -C "aws-key" -f ~/.ssh/id_aws -P ""
export AWS_KEY_NAME=aws-key
export AWS_SSH_PUB_KEY_FILE=~/.ssh/id_aws.pub

# override if required
REGION="europe-west1"
ZONE="europe-west1-b"


GCP_TFVARS=gcp.auto.tfvars
AWS_TFVARS=aws.auto.tfvars


# lif $GCP_TFVARS "project = " $PROJECT


source mc-gcp-networking.env

cat <<EOF > "$GCP_TFVARS"
gcp_project_id = "$PROJECT"

gcp_os_username = "$GCP_OS_USERNAME"
gcp_ssh_pub_key_file = "$GCP_SSH_PUB_KEY_FILE"

EOF

awk -f env-to-tfvars.awk mc-gcp-networking.env >> "$GCP_TFVARS"

source mc-aws-networking.env

cat <<EOF > "$AWS_TFVARS"
aws_key_name = "$AWS_KEY_NAME"
aws_ssh_pub_key_file = "$AWS_SSH_PUB_KEY_FILE"
EOF

awk -f env-to-tfvars.awk mc-aws-networking.env >> "$AWS_TFVARS"

