#!/bin/bash

# example usage:
#  time ./install.sh |& tee mc-install-`date -u +"%Y-%m-%dT%H:%M:%SZ"`.log
#


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

# eks to a parallel fork, join before eks hybrid deploy
export EKS_CLUSTER_LOG=${EKS_CLUSTER_LOG:-$HYBRID_HOME/mc-install-eks-`date -u +"%Y-%m-%dT%H:%M:%SZ"`.log}
echo "Building EKS cluser in background; progress log: $EKS_CLUSTER_LOG"

nohup bash <<EOS &> $EKS_CLUSTER_LOG &
./ci-eks.sh
EOS
export EKS_CLUSTER_PID=$!


./ci-gke.sh


./hi-gke.sh

source $HYBRID_HOME/source.env
$AHR_HOME/proxies/deploy.sh

echo "Making sure EKS cluster is ready before progressing [pid: $EKS_CLUSTER_PID]..."
wait $EKS_CLUSTER_PID

./hi-eks.sh

