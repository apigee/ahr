#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


export TF_MODULE=infra-cluster-gke-eks-tf

# 
GCP_TFVARS=$TF_MODULE/gcp.auto.tfvars
AWS_TFVARS=$TF_MODULE/aws.auto.tfvars


source mc-r2-eks.env

cat <<EOF > "$AWS_TFVARS"
aws_region = "$AWS_REGION"
aws_vpc = "$AWS_VPC"
aws_public_subnet = "$AWS_PUBLIC_SUBNET"

aws_vpn_gw_name = "$AWS_VPN_GW_NAME"
gcp_vpc_cidr = "$GCP_VPC_CIDR"
EOF

awk -f $BASEDIR/tf-env-to-tfvars.awk mc-r2-eks.env >> "$AWS_TFVARS"
