#!/bin/bash

set -e

export HYBRID_ENV=$HYBRID_HOME/mc-r1-gke.env
source $HYBRID_ENV

kubectl config use-context $R1_CLUSTER

kubectl apply --validate=false -f $CERT_MANAGER_MANIFEST

# external: ahr-runtime-ctl install-profile small asm-gcp -c gcp-ip
# internal IP provisioning 
gcloud compute addresses create apigee-ingress-ip --region "$GCP_REGION" --subnet "$GCP_VPC_SUBNET" --purpose SHARED_LOADBALANCER_VIP
export RUNTIME_IP=$(gcloud compute addresses describe runtime-ip --region "$REGION" --format='value(address)')

sed -i -E "s/^(export RUNTIME_IP=).*/\1$RUNTIME_IP/g" $HYBRID_ENV

# refresh RUNTIME_IP
source $HYBRID_ENV

ahr-runtime-ctl install-profile small asm-gcp -c istio

ahr-runtime-ctl install-profile small asm-gcp -c apigee-org
ahr-runtime-ctl install-profile small asm-gcp -c runtime-config
ahr-runtime-ctl install-profile small asm-gcp -c runtime

source <(ahr-runtime-ctl get-apigeectl-home $HYBRID_HOME/$APIGEECTL_TARBALL)
ahr-runtime-ctl install-profile small asm-gcp -c source-env
