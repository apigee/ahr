#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# 

GCP_TFVARS=gke-eks-cluster-infra-tf/gcp.auto.tfvars
AWS_TFVARS=gke-eks-cluster-infra-tf/aws.auto.tfvars


source mc-r2-eks.env

cat <<EOF > "$AWS_TFVARS"
aws_region = "$AWS_REGION"
aws_vpc = "$AWS_VPC"
aws_public_subnet = "$AWS_PUBLIC_SUBNET"

EOF

awk -f $BASEDIR/env-to-tfvars.awk mc-r2-eks.env >> "$AWS_TFVARS"
