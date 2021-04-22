#!/bin/bash

# example usage:
#  time ./install...sh |& tee mc-install-`date -u +"%Y-%m-%dT%H:%M:%SZ"`.log
#
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

# useful functions
source $AHR_HOME/bin/ahr-lib.sh

check_envvars "AHR_HOME PROJECT GCP_OS_USERNAME AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION HYBRID_HOME"
check_commands "gcloud aws kubectl terraform jq yq"

export PATH=$AHR_HOME/bin:$PATH
export PATH=~/bin:$PATH

# gcp
gcloud config set project $PROJECT

# enable required APIs
ahr-verify-ctl api-enable

# infrastructure setup
cd $HYBRID_HOME


# Build GCP/AWS VPC/VPN Infrastructure
./bs-gcp-aws.sh

pushd infra-gcp-aws-tf
terraform init
terraform apply -auto-approve
popd

./bs-cluster-infra-gke-eks.sh

pushd infra-cluster-gke-eks-tf
terraform init
terraform apply -auto-approve
popd


./ci-gke.sh
./hi-gke.sh

source $HYBRID_HOME/source.env
$AHR_HOME/proxies/deploy.sh

./ci-eks.sh
./hi-eks.sh

