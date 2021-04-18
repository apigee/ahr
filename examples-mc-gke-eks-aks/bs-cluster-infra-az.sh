#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


export TF_MODULE=infra-cluster-az-tf

# 
AZ_TFVARS=$TF_MODULE/az.auto.tfvars


source mc-r3-aks.env

cat <<EOF > "$AZ_TFVARS"
resource_group = "$RESOURCE_GROUP"

az_vnet = "$AZ_VNET"
az_vnet_subnet = "$AZ_VNET_SUBNET"
EOF
