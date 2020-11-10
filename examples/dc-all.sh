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
# dc-all.sh -- common variables for each dc/project
#  can be used for ahr-runtime-ctl home as well
#
#  cloud: GCP
#  cluster: two node-pools, multi-zonal
#  
#
# usage:
#    source <env-conf-file>

#
# Hybrid version
#
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export HYBRID_VERSION=1.2.0
export HYBRID_HOME=${HYBRID_HOME:-$BASEDIR}
export HYBRID_TARBALL=apigeectl_linux_64.tar.gz




#
# Project
#

export PROJECT=emea-cs-hybrid-demo2
export NETWORK=default
export SUBNETWORK=default

#
# Cluster
#
export CLUSTER_TEMPLATE=$AHR_HOME/templates/cluster-multi-zone-template.json

export CLUSTER_VERSION=1.14

export MACHINE_TYPE_DATA=n1-standard-4
export MACHINE_TYPE_RUNTIME=n1-standard-4

#
# Certificates 
#
export APIGEE_NET_CHAIN=/home/yuriyl/apigee-hybrid/certificates/hybrid-net-cert-20200531.pem
export APIGEE_NET_KEY=/home/yuriyl/apigee-hybrid/certificates/hybrid-net-key-20200531.pem



#
# Runtime
#
export RUNTIME_TEMPLATE=$AHR_HOME/templates/overrides-large-template.yaml

export SA_DIR=/home/yuriyl/apigee-hybrid/service-account-keys


export ORG=$PROJECT
export ENV=test

export CASSANDRA_REQUESTS_CPU=1000m
export CASSANDRA_REQUESTS_MEMORY=2Gi
export CASSANDRA_STORAGE_CAPACITY=15Gi

export ENC_KEY_KMS=$(LC_ALL=C tr -dc "[:print:]" < /dev/urandom | head -c 32 | openssl base64)
export ENC_KEY_KVM=$ENC_KEY_KMS
export ENC_KEY_CACHE=$ENC_KEY_KMS

export MART_ID=apigee-mart
export SYNCHRONIZER_ID=apigee-synchronizer


export SYNCHRONIZER_SA=$SA_DIR/$PROJECT-$SYNCHRONIZER_ID.json
export UDCA_SA=$SA_DIR/$PROJECT-apigee-udca.json
export MART_SA=$SA_DIR/$PROJECT-apigee-mart.json
export METRICS_SA=$SA_DIR/$PROJECT-apigee-metrics.json

export MART_SA_ID=$MART_ID@$PROJECT.iam.gserviceaccount.com
export SYNCHRONIZER_SA_ID=$SYNCHRONIZER_ID@$PROJECT.iam.gserviceaccount.com

export RUNTIME_SSL_CERT=$APIGEE_NET_CHAIN
export RUNTIME_SSL_KEY=$APIGEE_NET_KEY

export MART_HOST_ALIAS=$ORG-mart.hybrid-apigee.net
export MART_SSL_CERT=$APIGEE_NET_CHAIN
export MART_SSL_KEY=$APIGEE_NET_KEY
export MART_IP=35.197.194.6

#------------------------------------------------------------
