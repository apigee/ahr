#!/bin/bash

# Install GTM on top of the Hybrid Multi-region topology at GCP

# This scripts assumes previously successfully installed dual region Hybrid

# example usage:
#  time ./install-gtm.sh |& tee mc-install-`date -u +"%Y-%m-%dT%H:%M:%SZ"`.log
#
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

check_envvars "AHR_HOME PROJECT HYBRID_HOME CLUSTER"
check_commands "gcloud kubectl jq yq"

# gcp
gcloud config set project $PROJECT

#
# Project-level Setup
#

# Source Configuration and make the $R1_CLUSTER active for Region 1

source $HYBRID_HOME/source.env

source $HYBRID_HOME/mr-r1-gke-cluster.env
kubectl config  use-context $CLUSTER

# Extract cluster node tags

export R1_CLUSTER_TAG=$(gcloud compute instances describe "$(kubectl --context $R1_CLUSTER get nodes -o jsonpath='{.items[0].metadata.name}')" --zone $R1_CLUSTER_ZONE  --format="value(tags.items[0])")

export R2_CLUSTER_TAG=$(gcloud compute instances describe "$(kubectl --context $R2_CLUSTER get nodes -o jsonpath='{.items[0].metadata.name}')" --zone $R2_CLUSTER_ZONE  --format="value(tags.items[0])")

export CLUSTER_NETWORK_TAGS=$R1_CLUSTER_TAG,$R2_CLUSTER_TAG

set +e

#  firewall for Google Health probers
gcloud compute firewall-rules create fw-allow-health-check-and-proxy-hybrid \
  --network=$NETWORK \
  --action=allow \
  --direction=ingress \
  --target-tags=$CLUSTER_NETWORK_TAGS \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --rules=tcp:8443


## Project-level: Google-Managed Certificate

# Provision GTM's VIP:
export GTM_VIP=hybrid-vip

gcloud compute addresses create $GTM_VIP \
  --ip-version=IPV4 \
  --global

export GTM_IP=$(gcloud compute addresses describe $GTM_VIP --format="get(address)" --global --project "$PROJECT")

echo $GTM_IP

export GTM_HOST_ALIAS=$(echo "$GTM_IP" | tr '.' '-').nip.io

echo "INFO: External IP: Create Google Managed SSL Certificate for FQDN: $GTM_HOST_ALIAS"

# Add to $GTM_HOST_ALIAS to an $ENV_GROUP

HOSTNAMES=$(ahr-runtime-ctl env-group-config $ENV_GROUP|jq '.hostnames' | jq '. + ["'$GTM_HOST_ALIAS'"]'|jq -r '. | join(",")' )

ahr-runtime-ctl env-group-set-hostnames "$ENV_GROUP" "$HOSTNAMES"


# Provision Google-managed certificate
gcloud compute ssl-certificates create apigee-ssl-cert \
    --domains="$GTM_HOST_ALIAS" --project "$PROJECT"

# Provision Google-managed certificate
gcloud compute ssl-certificates create apigee-ssl-cert \
    --domains="$GTM_HOST_ALIAS" --project "$PROJECT"

## Project-level: Health Check and Backend Service provisioning

# TCP Heath Check configuration
gcloud compute health-checks create tcp https-basic-check \
  --use-serving-port

# Backend Service configuration
gcloud compute backend-services create hybrid-bes \
  --port-name=https \
  --protocol HTTPS \
  --health-checks https-basic-check \
  --global

# URL map
gcloud compute url-maps create hybrid-web-map \
  --default-service hybrid-bes

## Project-level: Target Proxy and Forwarding Rule

# Target https proxy
gcloud compute target-https-proxies create hybrid-https-lb-proxy \
  --ssl-certificates=apigee-ssl-cert \
  --url-map hybrid-web-map

# Forwarding Rule
gcloud compute forwarding-rules create hybrid-https-forwarding-rule \
  --address=$GTM_VIP \
  --global \
  --target-https-proxy=hybrid-https-lb-proxy \
  --ports=443
set -e

#
# Region 1: ApigeeRoute for non-SNI Google Load Balancer
#

# Define a secret for non-SNI ApigeeRoute
export TLS_SECRET=$ORG-$ENV_GROUP

# Non-SNI ApigeeRoute 

cat <<EOF > $HYBRID_HOME/apigeeroute-non-sni.yaml
apiVersion: apigee.cloud.google.com/v1alpha1
kind: ApigeeRoute
metadata:
  name: apigee-route-non-sni
  namespace: apigee
spec:
  enableNonSniClient: true
  hostnames:
  - "*"
  ports:
  - number: 443
    protocol: HTTPS
    tls:
      credentialName: $TLS_SECRET
      mode: SIMPLE
      minProtocolVersion: TLS_AUTO
  selector:
    app: istio-ingressgateway
EOF

kubectl apply -f $HYBRID_HOME/apigeeroute-non-sni.yaml

# Reconfigure virtual host in Region 1 with .virtualhosts.additionalGateways array
yq merge -i $RUNTIME_CONFIG - <<EOF
virtualhosts:
  - name: $ENV_GROUP
    additionalGateways: ["apigee-route-non-sni"]
EOF

ahr-runtime-ctl apigeectl apply -f $RUNTIME_CONFIG --settings virtualhosts --env $ENV

## Region 1: Define NEG Configuration in GKE cluster

# Define region's NEG name
export NEG_NAME=hybrid-neg-$REGION

# Edit istio operator to add NEG annotation
yq merge -i $ASM_CONFIG - <<EOF
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        k8s:
          serviceAnnotations:
            cloud.google.com/neg: '{"exposed_ports": {"443":{"name": "$NEG_NAME"}}}'
EOF

istioctl install -f $ASM_CONFIG

# Chose your capacity setting wisely
export MAX_RATE_PER_ENDPOINT=100

# Add region 1 backend to the load balancer
set +e
gcloud compute backend-services add-backend hybrid-bes --global \
   --network-endpoint-group $NEG_NAME \
   --network-endpoint-group-zone $CLUSTER_ZONE \
   --balancing-mode RATE --max-rate-per-endpoint $MAX_RATE_PER_ENDPOINT
set -e

#
# Region 2: NEG Configuration
# 

# Switch current env variable config to the region 2
source $HYBRID_HOME/mr-r2-gke-cluster.env
kubectl config  use-context $CLUSTER

# Define region's NEG name
export NEG_NAME=hybrid-neg-$REGION

# Edit istio operator to add NEG annotation
yq merge -i $ASM_CONFIG - <<EOF
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        k8s:
          serviceAnnotations:
            cloud.google.com/neg: '{"exposed_ports": {"443":{"name": "$NEG_NAME"}}}'
EOF

istioctl install -f $ASM_CONFIG

# Create non-SNI ApigeeRoute
kubectl apply -f $HYBRID_HOME/apigeeroute-non-sni.yaml

# Add additionalGateways value to the virtual host $ENV_GROUP
yq merge -i $RUNTIME_CONFIG - <<EOF
virtualhosts:
  - name: $ENV_GROUP
    additionalGateways: ["apigee-route-non-sni"]
EOF

ahr-runtime-ctl apigeectl apply -f $RUNTIME_CONFIG --settings virtualhosts --env $ENV

# Add region 2 backend to the load balancer
gcloud compute backend-services add-backend hybrid-bes --global \
   --network-endpoint-group $NEG_NAME \
   --network-endpoint-group-zone $CLUSTER_ZONE \
   --balancing-mode RATE --max-rate-per-endpoint $MAX_RATE_PER_ENDPOINT


echo "Done: $(date)"
echo "Test request:"
echo "    curl https://$GTM_HOST_ALIAS/ping"
