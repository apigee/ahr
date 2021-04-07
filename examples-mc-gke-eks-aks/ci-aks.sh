#!/bin/bash

set -e

source $HYBRID_HOME/mc-r3-aks.env

pushd $HYBRID_HOME/infra-cluster-az-tf
source <(terraform output |awk '{printf( "export %s=%s\n", toupper($1), $3)}')
popd


# AKS create command does not support a partial Kubernetes version. Get full Kubernetes version

export AKS_FULL_KUBERNETES_VERSION=$(az aks get-versions --location $AZ_REGION  | jq -r ".orchestrators[].orchestratorVersion| select(test(\"^$CLUSTER_VERSION.*\")) " | sort | tail -n1 ); echo $AKS_FULL_KUBERNETES_VERSION

check_envvars " \
  RESOURCE_GROUP \
  CLUSTER \
  AZ_REGION \
  AKS_FULL_KUBERNETES_VERSION \
  AZ_VM_SIZE_RUNTIME \
  AZ_VNET_SUBNET_ID \
  AKS_SERVICE_CIDR \
  AKS_DNS_SERVICE_IP \
  AKS_DOCKER_CIDR "

az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER \
  --location $AZ_REGION \
  --kubernetes-version $AKS_FULL_KUBERNETES_VERSION \
  --nodepool-name hybridpool \
  --node-vm-size $AZ_VM_SIZE_RUNTIME \
  --node-count 4 \
  --network-plugin azure \
  --vnet-subnet-id $AZ_VNET_SUBNET_ID \
  --service-cidr $AKS_SERVICE_CIDR \
  --dns-service-ip $AKS_DNS_SERVICE_IP \
  --docker-bridge-address $AKS_DOCKER_CIDR \
  --enable-managed-identity \
  --generate-ssh-keys \
  --output table --yes


az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER

ahr-cluster-ctl anthos-hub-register
ahr-cluster-ctl anthos-user-ksa-create

