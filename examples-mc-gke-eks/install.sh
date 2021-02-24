#!/bin/bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

check_vars "AHR_HOME PROJECT GCP_OS_USERNAME AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION HYBRID_HOME"


export PATH=$AHR_HOME/bin:$PATH

# useful functions
source $AHR_HOME/bin/ahr-lib.sh

./bs-prereqisites.sh

export PATH=~/bin:$PATH

# gcp
gcloud config set project $PROJECT

# enable required APIs
ahr-verify-ctl api-enable

# infrastructure setup

# Build GCP/AWS VPC/VPN Infrastructure
cd $HYBRID_HOME
./bs-networking.sh
cd gcp-aws-vpc-infra-tf
terraform init
terraform apply -auto-approve

cd $HYBRID_HOME
./bs-cluster-infra.sh
cd gke-eks-cluster-infra-tf
terraform init
terraform apply -auto-approve

./ci-gke.sh

./ci-eks.sh


./hi-gke.sh

$AHR_HOME/proxies/deploy.sh

./hi-gke.sh

