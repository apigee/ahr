#!/bin/bash

set -e

cp -R $AHR_HOME/examples-mc-gke-eks/ $HYBRID_HOME


source $HYBRID_HOME/mc-r2-eks.env

pushd $HYBRID_HOME/gke-eks-cluster-infra-tf
source <(terraform output |awk '{printf( "export %s=%s\n", toupper($1), $3)}')
popd

ahr-cluster-ctl template $HYBRID_HOME/eks-cluster-template.yaml > $HYBRID_HOME/eks-cluster-config.yaml

eksctl create cluster -f $HYBRID_HOME/eks-cluster-config.yaml

ahr-cluster-ctl anthos-hub-register
ahr-cluster-ctl anthos-user-ksa-create

# rename context to $CLUSTER
export EKS_DEFAULT_CONTEXT=$(aws iam get-user --query 'User.UserName' --output text)@$CLUSTER.$AWS_REGION.eksctl.io ; echo $EKS_DEFAULT_CONTEXT
kubectl config rename-context $EKS_DEFAULT_CONTEXT $R2_CLUSTER
