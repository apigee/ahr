#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


export TF_MODULE=infra-cluster-az-tf

# 
AZ_TFVARS=$TF_MODULE/az.auto.tfvars
AWS_TFVARS=$TF_MODULE/aws.auto.tfvars


source mc-r3-aks.env

cat <<EOF > "$AZ_TFVARS"
resource_group = "$RESOURCE_GROUP"

az_vnet = "$AZ_VNET"
az_vnet_subnet = "$AZ_VNET_SUBNET"
az_vnet_cidr = "$AZ_VNET_CIDR"
EOF

cat <<EOF > "$AWS_TFVARS"
aws_vpc = "$AWS_VPC"
aws_vpn_gw_name = "$AWS_VPN_GW_NAME"
EOF
