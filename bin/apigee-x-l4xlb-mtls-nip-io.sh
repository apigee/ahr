#!/usr/bin/env bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Overlay GXLB with nip.io for a GKE hybrid install
#

set -e

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $BASEDIR/ahr-lib.sh


# parameter: Apigee Environement Group
#ORG=$1
#ENV_GROUP=$2
#ASM_CONFIG=$3

check_envvars "APIGEECTL_HOME HYBRID_HOME ORG ENV_GROUP ASM_CONFIG"
check_commands "kubectl asmcli yq"

#
# Global IP Address and GTM Host Name
#

export GTM_VIP=ingress-ip

# skip if exists
set +e
gcloud compute addresses create $GTM_VIP --global
set -e

# nip.io proof-of-ownership service for our provisioned certificate.

export GTM_IP=$(gcloud compute addresses describe $GTM_VIP --format="get(address)" --global --project "$PROJECT")

export GTM_HOST_ALIAS=$(echo "$GTM_IP" | tr '.' '-').nip.io

echo "INFO: GTM VIP: $GTM_VIP"
echo "INFO: GTM IP: $GTM_IP"
echo "INFO: Google Managed SSL Certificate for FQDN: $GTM_HOST_ALIAS"

# Add to $GTM_HOST_ALIAS to an $ENV_GROUP

HOSTNAMES=$(ahr-runtime-ctl env-group-config $ENV_GROUP|jq '.hostnames' | jq '. + ["'$GTM_HOST_ALIAS'"]'|jq -r '. | join(",")' )

ahr-runtime-ctl env-group-set-hostnames "$ENV_GROUP" "$HOSTNAMES"


# Provision a TLS certificate

cat <<EOF >$HYBRID_HOME/managed-cert.yaml
apiVersion: networking.gke.io/v1beta2
kind: ManagedCertificate
metadata:
  name: apigee-ssl-cert
  namespace: istio-system
spec:
  domains:
    - "$GTM_HOST_ALIAS"
EOF

kubectl apply -f $HYBRID_HOME/managed-cert.yaml

#
# Deploy the Ingress resource
#

cat <<EOF >$HYBRID_HOME/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gke-ingress
  namespace: istio-system
  annotations:
    kubernetes.io/ingress.allow-http: "false"
    kubernetes.io/ingress.global-static-ip-name: "$GTM_VIP"
    networking.gke.io/managed-certificates: "apigee-ssl-cert"
    kubernetes.io/ingress.class: "gce"
spec:
  defaultBackend:
    service:
      name: istio-ingressgateway
      port:
        number: 443
  rules:
  - http:
      paths:
      - path: /*
        pathType: ImplementationSpecific
        backend:
          service:
            name: istio-ingressgateway
            port:
              number: 443
EOF

kubectl apply -f $HYBRID_HOME/ingress.yaml

kubectl describe ingress gke-ingress -n istio-system

#
# Checks and reports

# Check istio ready
# kubectl wait --for=condition=available --timeout=600s deployment --all -n istio-system

echo "# To Check certificate status:
kubectl describe managedcertificate apigee-ssl-cert -n istio-system

# To check ingress status:
kubectl describe ingress gke-ingress -n istio-system

# NOTE: it takes 8-15 minutes to provision a certificate
"

echo "Test request:"
echo "curl https://$GTM_HOST_ALIAS/ping"

