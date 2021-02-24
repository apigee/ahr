#!/bin/bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

# useful functions
source $AHR_HOME/bin/ahr-lib.sh

check_envvars "AHR_HOME PROJECT GCP_OS_USERNAME AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION HYBRID_HOME"

export PATH=$AHR_HOME/bin:$PATH

./bs-prerequisites.sh

export PATH=~/bin:$PATH

# gcp
gcloud config set project $PROJECT

# enable required APIs
ahr-verify-ctl api-enable

# infrastructure setup
cd $HYBRID_HOME


# Build GCP/AWS VPC/VPN Infrastructure
./bs-networking.sh

pushd gcp-aws-vpc-infra-tf
terraform init
terraform apply -auto-approve
popd

./bs-cluster-infra.sh

pushd gke-eks-cluster-infra-tf
terraform init
terraform apply -auto-approve
popd

# TODO: [ ] eks to parallel fork, join before eks hybrid
#
#

./ci-gke.sh

./ci-eks.sh


./hi-gke.sh

source $HYBRID_HOME/source.env
$AHR_HOME/proxies/deploy.sh

./hi-eks.sh

