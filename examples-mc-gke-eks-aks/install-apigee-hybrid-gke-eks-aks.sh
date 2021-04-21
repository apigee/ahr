#!/bin/bash

# example usage:
#  time ./install...sh |& tee mc-install-`date -u +"%Y-%m-%dT%H:%M:%SZ"`.log
#
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

# useful functions
source $AHR_HOME/bin/ahr-lib.sh

check_envvars "AHR_HOME PROJECT GCP_OS_USERNAME AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION HYBRID_HOME"
check_commands "gcloud aws az kubectl terraform jq yq"

export PATH=$AHR_HOME/bin:$PATH
export PATH=~/bin:$PATH

# gcp
gcloud config set project $PROJECT

# enable required APIs
ahr-verify-ctl api-enable

# infrastructure setup
cd $HYBRID_HOME


# Build GCP/AWS/Azure VPC/VPN Infrastructure
./bs-gcp-aws-az.sh

pushd infra-gcp-aws-az-tf
terraform init
terraform apply -auto-approve
popd

./bs-cluster-infra-gke-eks.sh

pushd infra-cluster-gke-eks-tf
terraform init
terraform apply -auto-approve
popd

./bs-cluster-infra-az.sh

pushd infra-cluster-az-tf
terraform init
terraform apply -auto-approve
popd

./ci-gke.sh
./hi-gke.sh

source $HYBRID_HOME/source.env
$AHR_HOME/proxies/deploy.sh

./ci-eks.sh
./hi-eks.sh


./ci-aks.sh
./hi-aks.sh



#
# skip parallel fork for now: 
# it doesn't work as is because kubernetes create cluster commands override default enty
#
if false; then

# TODO: [ ] change to KUBECONFIG-based implementation


# eks to a parallel fork, join before eks hybrid deploy
export EKS_CLUSTER_LOG=${EKS_CLUSTER_LOG:-$HYBRID_HOME/mc-install-eks-`date -u +"%Y-%m-%dT%H:%M:%SZ"`.log}
echo "Building EKS cluser in background; progress log: $EKS_CLUSTER_LOG"

nohup bash <<EOS &> $EKS_CLUSTER_LOG &
./ci-eks.sh
EOS
export EKS_CLUSTER_PID=$!


# eks to a parallel fork, join before eks hybrid deploy
export AKS_CLUSTER_LOG=${AKS_CLUSTER_LOG:-$HYBRID_HOME/mc-install-aks-`date -u +"%Y-%m-%dT%H:%M:%SZ"`.log}
echo "Building AKS cluser in background; progress log: $AKS_CLUSTER_LOG"

nohup bash <<EOS &> $AKS_CLUSTER_LOG &
./ci-aks.sh
EOS
export AKS_CLUSTER_PID=$!


./ci-gke.sh

# Installation of Hybrid instances

./hi-gke.sh

source $HYBRID_HOME/source.env
$AHR_HOME/proxies/deploy.sh


echo "Making sure EKS cluster is ready before progressing [pid: $EKS_CLUSTER_PID]..."
wait $EKS_CLUSTER_PID

./hi-eks.sh


echo "Making sure AKS cluster is ready before progressing [pid: $AKS_CLUSTER_PID]..."
wait $AKS_CLUSTER_PID

./hi-aks.sh

fi

