#!/bin/bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $BASEDIR/lib.sh

set -e

check_envvars "PROJECT GCP_OS_USERNAME"
check_commands "gcloud aws terraform"

export TF_DIR=${TF_DIR:-$BASEDIR/infra-gcp-aws-tf}


#
if [ ! -f ~/.ssh/id_gcp ]; then
  ssh-keygen -t rsa -C "gcp-key" -f ~/.ssh/id_gcp  -P ""
fi
export GCP_SSH_PUB_KEY_FILE=~/.ssh/id_gcp.pub

if [ ! -f ~/.ssh/id_aws ]; then
  ssh-keygen -t rsa -C "aws-key" -f ~/.ssh/id_aws -P ""
fi
export AWS_KEY_NAME=aws-key
export AWS_SSH_PUB_KEY_FILE=~/.ssh/id_aws.pub


#
# GCP
#

# override if required
REGION="europe-west1"
ZONE="europe-west1-b"


GCP_TFVARS=$TF_DIR/gcp.auto.tfvars
AWS_TFVARS=$TF_DIR/aws.auto.tfvars


GCP_VARS=$BASEDIR/mc-gcp-networking.env

source $GCP_VARS

cat <<EOF > "$GCP_TFVARS"
gcp_project_id = "$PROJECT"

gcp_os_username = "$GCP_OS_USERNAME"
gcp_ssh_pub_key_file = "$GCP_SSH_PUB_KEY_FILE"

EOF
awk -f $BASEDIR/tf-env-to-tfvars.awk $GCP_VARS >> "$GCP_TFVARS"


#
# AWS
#

AWS_VARS=$BASEDIR/mc-aws-networking.env
source $AWS_VARS



cat <<EOF > "$AWS_TFVARS"
aws_key_name = "$AWS_KEY_NAME"
aws_ssh_pub_key_file = "$AWS_SSH_PUB_KEY_FILE"
EOF

awk -f $BASEDIR/tf-env-to-tfvars.awk $AWS_VARS >> "$AWS_TFVARS"


# process .tfi modules [TODO: [ ] hard-coded right now]
awk -f $BASEDIR/tfi-module-include.awk $TF_DIR/modules.tfi > $TF_DIR/modules.tfi.tf
