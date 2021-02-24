#!/bin/bash

export HYBRID_ENV=$HYBRID_HOME/mc-r1-gke.env
source $HYBRID_ENV

kubectl config use-context $R1_CLUSTER

kubectl apply --validate=false -f $CERT_MANAGER_MANIFEST

ahr-runtime-ctl install-profile small asm-gcp -c gcp-ip

# refresh RUNTIME_IP
source $HYBRID_ENV

ahr-runtime-ctl install-profile small asm-gcp -c istio

ahr-runtime-ctl install-profile small asm-gcp -c apigee-org
ahr-runtime-ctl install-profile small asm-gcp -c runtime-config
ahr-runtime-ctl install-profile small asm-gcp -c runtime

ahr-runtime-ctl install-profile small asm-gcp -c source-env
