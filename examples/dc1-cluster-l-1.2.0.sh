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


BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $BASEDIR/dc-all.sh


export REGION=us-east1
#

#
# Cluster
#
export CLUSTER_CONFIG=dc1-cluster.json

export CLUSTER=dc1-cluster
export CLUSTER_ZONE=us-east1-b
export CLUSTER_LOCATIONS='"us-east1-b","us-east1-c","us-east1-d"'
export CONTEXT=dc1-cluster


#------------------------------------------------------------

# 
# Runtime
#
export RUNTIME_CONFIG=$HYBRID_HOME/dc1-runtime.yaml

export RUNTIME_HOST_ALIAS=$ORG-$ENV-dc1.hybrid-apigee.net
export RUNTIME_IP=35.246.104.54
#------------------------------------------------------------
