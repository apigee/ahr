#!/bin/bash

# Install Hybrid Multi-region topology at GCP

#
# expected Environment Variables
#

# example usage:
#  time ./install...sh |& tee mc-install-`date -u +"%Y-%m-%dT%H:%M:%SZ"`.log
#
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

check_envvars "AHR_HOME PROJECT HYBRID_HOME"
check_commands "gcloud kubectl jq yq"


# useful functions
source $AHR_HOME/bin/ahr-lib.sh


# gcp
gcloud config set project $PROJECT

#
# Create Region 1 cluster 
#
source $HYBRID_HOME/mr-r1-gke-cluster.env

ahr-cluster-ctl template $CLUSTER_TEMPLATE > $CLUSTER_CONFIG

ahr-cluster-ctl create

#
# Create Region 2 cluster 
#
source $HYBRID_HOME/mr-r2-gke-cluster.env

ahr-cluster-ctl template $CLUSTER_TEMPLATE > $CLUSTER_CONFIG

ahr-cluster-ctl create

# Multi-region Connectivity for Cassandra
export R1_CLUSTER_CIDR=$(gcloud container clusters describe $R1_CLUSTER --zone=$R1_CLUSTER_ZONE  --format='value(clusterIpv4Cidr)')

export R2_CLUSTER_CIDR=$(gcloud container clusters describe $R2_CLUSTER --zone=$R2_CLUSTER_ZONE  --format='value(clusterIpv4Cidr)')


gcloud compute firewall-rules create allow-cs-7001 \
    --project $PROJECT \
    --network $NETWORK \
    --allow tcp:7001 \
    --direction INGRESS \
    --source-ranges $R1_CLUSTER_CIDR,$R2_CLUSTER_CIDR


ahr-verify-ctl api-enable

#
# Apigee ORG
#

ahr-runtime-ctl org-create $ORG --ax-region $AX_REGION

ahr-runtime-ctl env-create $ENV

ahr-runtime-ctl env-create $ENV

ahr-runtime-ctl env-group-create $ENV_GROUP $RUNTIME_HOST_ALIASES

ahr-runtime-ctl env-group-assign $ORG $ENV_GROUP $ENV

ahr-sa-ctl create-sa all

ahr-sa-ctl create-key all

#
# Hybrid Region 1: Install Hybrid
#
export HYBRID_ENV=$HYBRID_HOME/mr-r1-gke-cluster.env
source $HYBRID_ENV

kubectl config use-context $CLUSTER

kubectl apply --validate=false -f $CERT_MANAGER_MANIFEST

# Hybrid Region 1: ASM installation
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

source <(ahr-cluster-ctl asm-get $ASM_VERSION)

gcloud compute addresses create runtime-ip \
    --region "$REGION" \
    --subnet "$SUBNETWORK" \
    --purpose SHARED_LOADBALANCER_VIP

export RUNTIME_IP=$(gcloud compute addresses describe runtime-ip --region "$REGION" --format='value(address)')
sed -i -E "s/^(export RUNTIME_IP=).*/\1$RUNTIME_IP/g" $HYBRID_ENV

ahr-cluster-ctl template $HYBRID_HOME/istio-operator-gke-template.yaml > $ASM_CONFIG

ahr-cluster-ctl asm-gke-configure "$ASM_VERSION_MINOR"

istioctl install -f $ASM_CONFIG

# Hybrid Region 1: Install Apigee Hybrid
ahr-verify-ctl cert-create-ssc $RUNTIME_SSL_CERT $RUNTIME_SSL_KEY $RUNTIME_HOST_ALIAS

export HYBRID_VERSION_MINOR=$(echo -n "$HYBRID_VERSION"|awk '{sub(/\.[0-9]$/,"");print}')

ahr-runtime-ctl template $RUNTIME_TEMPLATE > $RUNTIME_CONFIG

source <(ahr-runtime-ctl get-apigeectl)

ahr-runtime-ctl apigeectl init -f $RUNTIME_CONFIG
sleep 30
ahr-runtime-ctl apigeectl wait-for-ready -f $RUNTIME_CONFIG

ahr-runtime-ctl apigeectl apply -f $RUNTIME_CONFIG
ahr-runtime-ctl apigeectl wait-for-ready -f $RUNTIME_CONFIG

source <(ahr-runtime-ctl get-apigeectl-home $HYBRID_HOME/$APIGEECTL_TARBALL)
ahr-runtime-ctl install-profile small asm-gcp -c source-env


$AHR_HOME/proxies/deploy.sh

#
# Hybrid Region 2: Install Hybrid
#

export HYBRID_ENV=$HYBRID_HOME/mr-r2-gke-cluster.env
source $HYBRID_ENV

kubectl config use-context $CLUSTER

kubectl create namespace cert-manager

kubectl --context=$R1_CLUSTER get secret apigee-ca --namespace=cert-manager -o yaml | kubectl --context=$R2_CLUSTER apply --namespace=cert-manager -f -


kubectl apply --validate=false -f $CERT_MANAGER_MANIFEST

gcloud compute addresses create runtime-ip \
    --region "$REGION" \
    --subnet "$SUBNETWORK" \
    --purpose SHARED_LOADBALANCER_VIP

export RUNTIME_IP=$(gcloud compute addresses describe runtime-ip --region "$REGION" --format='value(address)')
sed -i -E "s/^(export RUNTIME_IP=).*/\1$RUNTIME_IP/g" $HYBRID_ENV

# Hybrid Region 2: ASM installation

ahr-cluster-ctl template $HYBRID_HOME/istio-operator-gke-template.yaml > $ASM_CONFIG

ahr-cluster-ctl asm-gke-configure "$ASM_VERSION_MINOR"

istioctl install -f $ASM_CONFIG

# Hybrid Region 2: Setting up Cassandra replication

export CS_USERNAME=jmxuser
export CS_PASSWORD=iloveapis123

CS_STATUS=$(kubectl --context $R1_CLUSTER -n apigee exec apigee-cassandra-default-0 -- nodetool -u $CS_USERNAME -pw $CS_PASSWORD status)

echo -e "$CS_STATUS"

export DC1_CS_SEED_NODE=$(echo "$CS_STATUS" | awk '/dc-1/{getline;getline;getline;getline;getline; print $2}')


echo $DC1_CS_SEED_NODE 

# Hybrid Region 2: Install Apigee Hybrid

ahr-verify-ctl cert-create-ssc $RUNTIME_SSL_CERT $RUNTIME_SSL_KEY $RUNTIME_HOST_ALIAS

ahr-runtime-ctl template $RUNTIME_TEMPLATE > $RUNTIME_CONFIG

yq m -i $RUNTIME_CONFIG - <<EOF
cassandra:
  multiRegionSeedHost: $DC1_CS_SEED_NODE
  datacenter: "dc-2"
  rack: "ra-1"
EOF

ahr-runtime-ctl apigeectl init -f $RUNTIME_CONFIG
sleep 30
ahr-runtime-ctl apigeectl wait-for-ready -f $RUNTIME_CONFIG

ahr-runtime-ctl apigeectl apply -f $RUNTIME_CONFIG
ahr-runtime-ctl apigeectl wait-for-ready -f $RUNTIME_CONFIG


# Hybrid Region 2: Finalize Cassandra Configuration in Region 2
kubectl --context $R1_CLUSTER -n apigee exec apigee-cassandra-default-0 -- nodetool -u $CS_USERNAME -pw $CS_PASSWORD status

kubectl --context $R2_CLUSTER exec apigee-cassandra-default-0 -n apigee  -- nodetool -u $CS_USERNAME -pw $CS_PASSWORD rebuild -- dc-1

yq d -i $RUNTIME_CONFIG cassandra.multiRegionSeedHost

ahr-runtime-ctl apigeectl apply --datastore -f $RUNTIME_CONFIG

echo "Done: $(date)"

