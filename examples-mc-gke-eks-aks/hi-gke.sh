#!/bin/bash

set -e

export HYBRID_ENV=$HYBRID_HOME/mc-r1-gke.env
source $HYBRID_ENV

kubectl config use-context $R1_CLUSTER

kubectl apply --validate=false -f $CERT_MANAGER_MANIFEST

echo "ASM version: $ASM_VERSION"

# internal IP provisioning
set +e
gcloud compute addresses create runtime-ip \
    --region "$GCP_REGION" \
    --subnet "$GCP_VPC_SUBNET" \
    --purpose SHARED_LOADBALANCER_VIP
set -e

export RUNTIME_IP=$(gcloud compute addresses describe runtime-ip --region "$GCP_REGION" --format='value(address)')

sed -i -E "s/^(export RUNTIME_IP=).*/\1$RUNTIME_IP/g" $HYBRID_ENV

# refresh RUNTIME_IP
source $HYBRID_ENV

# Use supplied istio-operator.yaml template
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT} --format="value(projectNumber)")
export ref=\$ref
export ASM_RELEASE=$(echo "$ASM_VERSION"|awk '{sub(/\.[0-9]+-asm\.[0-9]+/,"");print}')

export ASM_VERSION_MINOR=$(echo "$ASM_VERSION"|awk '{sub(/\.[0-9]+-asm\.[0-9]+/,"");print}')

cp $AHR_HOME/templates/istio-operator-$ASM_RELEASE-$ASM_PROFILE.yaml $HYBRID_HOME/istio-operator-gke-template.yaml

yq merge -i $HYBRID_HOME/istio-operator-gke-template.yaml - <<"EOF"
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        k8s:
          serviceAnnotations:
            networking.gke.io/load-balancer-type: "Internal"
            networking.gke.io/internal-load-balancer-allow-global-access: "true"
EOF

ahr-cluster-ctl template $HYBRID_HOME/istio-operator-gke-template.yaml > $ASM_CONFIG

# Get ASM and add _HOME to PATH
source <(ahr-cluster-ctl asm-get $ASM_VERSION)

# Configure GKE cluster
ahr-cluster-ctl asm-gke-configure "$ASM_VERSION_MINOR"

# Install istio
istioctl install -f $ASM_CONFIG

ahr-runtime-ctl install-profile small asm-gcp -c apigee-org
ahr-runtime-ctl install-profile small asm-gcp -c runtime-config
ahr-runtime-ctl install-profile small asm-gcp -c runtime

# Generate source.env for R1_CLUSTER
source <(ahr-runtime-ctl get-apigeectl-home $HYBRID_HOME/$APIGEECTL_TARBALL)
ahr-runtime-ctl install-profile small asm-gcp -c source-env
