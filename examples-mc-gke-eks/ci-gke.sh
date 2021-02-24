#!/bin/bash

export HYBRID_ENV=$HYBRID_HOME/mc-r1-gke.env
source $HYBRID_ENV

gcloud compute networks subnets update $GCP_VPC_SUBNET \
    --region=$GCP_REGION \
--add-secondary-ranges=$GCP_VPC_SUBNET_PODS=$GCP_VPC_SUBNET_PODS_CIDR,$GCP_VPC_SUBNET_SERVICES=$GCP_VPC_SUBNET_SERVICES_CIDR

ahr-cluster-ctl template $CLUSTER_TEMPLATE > $CLUSTER_CONFIG

export CLUSTER_IP_ALLOCATION_POLICY=$( cat << EOT
 {
      "useIpAliases": true,
      "clusterSecondaryRangeName": "$GCP_VPC_SUBNET_PODS",
      "servicesSecondaryRangeName": "$GCP_VPC_SUBNET_SERVICES"
}
EOT
)

cat <<< "$(jq .cluster.ipAllocationPolicy="$CLUSTER_IP_ALLOCATION_POLICY" < $CLUSTER_CONFIG)" > $CLUSTER_CONFIG

ahr-cluster-ctl create
