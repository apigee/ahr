
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

export CERT_MANAGER_MANIFEST=https://github.com/jetstack/cert-manager/releases/download/v0.14.2/cert-manager.yaml

export ASM_TARBALL=istio-1.5.8-asm.7-linux.tar.gz
export ASM_TEMPLATE=$AHR_HOME/templates/asm-overrides.yaml
export ASM_CONFIG=$HYBRID_HOME/asm.yaml

export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT} --format="value(projectNumber)")
export MESH_ID="proj-${PROJECT_NUMBER}"

#
# Hybrid release configuration
#
export HYBRID_VERSION=1.3.0
export HYBRID_TARBALL=apigeectl_linux_64.tar.gz


#
# GCP Project: 
#
export NETWORK=default
export SUBNETWORK=default

export REGION=europe-west1
export AX_REGION=$REGION
#

#
# Runtime Cluster definition
#
export CLUSTER_TEMPLATE=$AHR_HOME/templates/cluster-multi-zone-template.json
export CLUSTER_CONFIG=$HYBRID_HOME/cluster-mz.json

export MACHINE_TYPE_DATA=n1-standard-8
export MACHINE_TYPE_RUNTIME=n1-standard-4

export CLUSTER_VERSION=1.16

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

export MART_SA_ID=$MART_ID@$PROJECT.iam.gserviceaccount.com
export SYNCHRONIZER_SA_ID=$SYNCHRONIZER_ID@$PROJECT.iam.gserviceaccount.com

export RUNTIME_HOST_ALIAS=$ORG-$ENV.hybrid-apigee.net
export RUNTIME_SSL_CERT=$HYBRID_HOME/hybrid-cert.pem
export RUNTIME_SSL_KEY=$HYBRID_HOME/hybrid-key.pem
export RUNTIME_IP=$(gcloud compute addresses describe runtime-ip --region $REGION --format='value(address)')

#------------------------------------------------------------
