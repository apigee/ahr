#!/bin/bash

export HYBRID_HOME=~/apigee-hybrid-multicloud

cp -R $AHR_HOME/examples-mc-gke-eks/ $HYBRID_HOME


source $HYBRID_HOME/mc-r2-eks.env
source <(terraform output |awk '{printf( "export %s=%s\n", toupper($1), $3)}')

ahr-cluster-ctl template $HYBRID_HOME/eks-cluster-template.yaml > $HYBRID_HOME/eks-cluster-config.yaml

eksctl create cluster -f $HYBRID_HOME/eks-cluster-config.yaml

ahr-cluster-ctl anthos-hub-register
ahr-cluster-ctl anthos-user-ksa-create



echo "Token for Attached cluster login\n"

CLUSTER_SECRET=$(kubectl get serviceaccount anthos-user -o jsonpath='{$.secrets[0].name}')

kubectl get secret ${CLUSTER_SECRET} -o jsonpath='{$.data.token}' | base64 --decode


export EKS_DEFAULT_CONTEXT=$(aws iam get-user --query 'User.UserName' --output text)@$CLUSTER.$AWS_REGION.eksctl.io ; echo $EKS_DEFAULT_CONTEXT
kubectl config rename-context $EKS_DEFAULT_CONTEXT $R2_CLUSTER
