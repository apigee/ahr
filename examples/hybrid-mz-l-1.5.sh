
# Copyright 2020 Google LLC
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
# collection of variables to define apigee hybrid topology and configuration
#
#  cloud: GCP
#  cluster: two node-pools, multi-zonal
#  
#
# usage:
#    source <env-conf-file>
source $AHR_HOME/bin/ahr-lib.sh     # for get_platform_suffix

export PLATFORM=${PLATFORM:-linux}  # linux | osx | win

export CERT_MANAGER_MANIFEST=${CERT_MANAGER_MANIFEST:-https://github.com/jetstack/cert-manager/releases/download/v1.2.0/cert-manager.yaml}

export ASM_PROFILE=${ASM_PROFILE:-asm-gcp}
export ASM_VERSION=${ASM_VERSION:-1.7.3-asm.6}

export ASM_TEMPLATE=$HYBRID_HOME/anthos-service-mesh-packages/asm/istio/istio-operator.yaml

export ASM_CONFIG=$HYBRID_HOME/istio-operator.yaml

#
# Hybrid release configuration
#
export HYBRID_VERSION=${HYBRID_VERSION:-1.5.1}
export APIGEECTL_TARBALL_URL=$(get_apigeectl_tarball_url "$HYBRID_VERSION" "$PLATFORM")
export APIGEECTL_TARBALL=apigeectl_$(get_platform_suffix apigeectl "$PLATFORM")


#
# GCP Project: 
#
export NETWORK=default
export SUBNETWORK=default

export REGION=${REGION:-europe-west1}
export ZONE=${ZONE:-europe-west1-b}
export AX_REGION=${AX_REGION:-europe-west1}
#

#
# Runtime Cluster definition
#
export CLUSTER_TEMPLATE=$AHR_HOME/templates/cluster-multi-zone-two-nodepools-template.json
export CLUSTER_CONFIG=$HYBRID_HOME/cluster-mz.json

# For a real production e2-standard-8 is recommended. -4 is used to fit into 24 CPU per region limit
export MACHINE_TYPE_DATA=${MACHINE_TYPE_DATA:-e2-standard-4}
export MACHINE_TYPE_RUNTIME=${MACHINE_TYPE_RUNTIME:-e2-standard-4}

export CLUSTER_VERSION=1.20

export CLUSTER=hybrid-cluster
export CLUSTER_ZONE=europe-west1-b
export CLUSTER_LOCATIONS='"europe-west1-b","europe-west1-c","europe-west1-d"'
export CONTEXT=$CLUSTER

#------------------------------------------------------------

# 
# Runtime Hybrid configuration
#
export RUNTIME_CONFIG=$HYBRID_HOME/runtime-mz.yaml


export ORG=$PROJECT
export ENV=test
export ENV_GROUP=test-group

export CASSANDRA_REQUESTS_CPU=1000m
export CASSANDRA_REQUESTS_MEMORY=2Gi
export CASSANDRA_STORAGE_CAPACITY=20Gi

#export ENC_KEY_KMS=$(LC_ALL=C tr -dc "[:print:]" < /dev/urandom | head -c 32 | openssl base64)
#export ENC_KEY_KVM=$ENC_KEY_KMS
#export ENC_KEY_CACHE=$ENC_KEY_KMS

export SA_DIR=$HYBRID_HOME/service-accounts

export MART_ID=apigee-mart
export SYNCHRONIZER_ID=apigee-synchronizer


export SYNCHRONIZER_SA=$SA_DIR/$PROJECT-$SYNCHRONIZER_ID.json
export UDCA_SA=$SA_DIR/$PROJECT-apigee-udca.json
export MART_SA=$SA_DIR/$PROJECT-apigee-mart.json
export METRICS_SA=$SA_DIR/$PROJECT-apigee-metrics.json
export WATCHER_SA=$SA_DIR/$PROJECT-apigee-watcher.json

export MART_SA_ID=$MART_ID@$PROJECT.iam.gserviceaccount.com
export SYNCHRONIZER_SA_ID=$SYNCHRONIZER_ID@$PROJECT.iam.gserviceaccount.com

export RUNTIME_HOST_ALIAS=$ORG-$ENV.hybrid-apigee.net
export RUNTIME_SSL_CERT=$HYBRID_HOME/hybrid-cert.pem
export RUNTIME_SSL_KEY=$HYBRID_HOME/hybrid-key.pem
export RUNTIME_IP=203.0.113.10

#------------------------------------------------------------
