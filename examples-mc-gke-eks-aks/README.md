# GCP/AWS or GCP/AWS/Azure VPN Topologies

This terraform project allows you to install non-default networking on either GCP/AWS or GCP/AWS/Azure combo with jumpboxes on each cloud and a sample 7000,7001 ports allowed to communication across clouds.

Of course, you need an active account at each of the two or three clouds.

## Terminal

 Use your working computer terminal or a VM  to overcome the timeout limit of CloudShell. We recommend to provision a default VM in your GCP project.


## Bastion VM in a default network


As a multi-cloud Apigee hybrid provisioning is a long-running process, let's provision a bastion VM. Bastion VM is also useful for troubleshooting, at it would be able to access private network addresses.

We are going to:

* create a Service Account;
* add Editor and Network Admin roles to it;
* provision a VM with scope and service account that will allow execute the provisioning script successfully;
* invoke SSH session at the VM.

1. In the GCP Console, activate Cloud Shell

1. Define PROJECT variable

```sh
export PROJECT=<your-project-id>
export BASTION_ZONE=europe-west1-b
```

1. Create a service account for installation purposes.

Click at the Authorize button when asked.

```sh
export INSTALLER_SA_ID=installer-sa

gcloud iam service-accounts create $INSTALLER_SA_ID
```

1. Add IAM policy bindings with required roles

```sh
roles='roles/editor 
       roles/compute.networkAdmin
       roles/iam.securityAdmin
       roles/container.admin'

for r in $roles; do
    gcloud projects add-iam-policy-binding $PROJECT \
        --member="serviceAccount:$INSTALLER_SA_ID@$PROJECT.iam.gserviceaccount.com" \
        --role=$r
done
```

1. Create a compute instance with installer SA identity that will be used to execute script.

```sh
gcloud compute instances create bastion \
    --service-account "$INSTALLER_SA_ID@$PROJECT.iam.gserviceaccount.com" \
    --zone $BASTION_ZONE \
    --scopes cloud-platform
```

1. In GCP Console, open Compute Engine/VM instances page, using hamburger menu.

1. The for bastion host, click SSH button to open an SSH session.

## Install Prerequisites and Cloud CLIs

?. Have a GCP, AWS, and Azure projects ready.

?. Create a bastion VM in your GCP project.

?. Install utilites required by cloud cli utilities

```sh
sudo apt-get update
sudo apt -y install mc jq git python3-pip
```


?. Clone Ahr repo and define Ahr variables
```
export AHR_HOME=~/ahr

cd ~
git clone https://github.com/apigee/ahr.git
```

?. Define HYBRID_HOME

```
export HYBRID_HOME=~/apigee-hybrid-multicloud

mkdir -p $HYBRID_HOME

cp -R $AHR_HOME/examples-mc-gke-eks-aks/. $HYBRID_HOME
```


?. CLIs

```sh

sudo apt-get install kubectl

./cli-terraform.sh
./cli-aws.sh
./cli-az.sh

$AHR_HOME/bin/ahr-verify-ctl prereqs-install-yq

source ~/.profile
```

### Cloud Logins

?. __GCP:__ For Qwiklabs/CloudShell:

```sh
# populate variables as appropriate or 
# use those pre-canned commands if you're using qwiklabs
export PROJECT=$(gcloud projects list|grep qwiklabs-gcp|awk '{print $1}')
# export GCP_OS_USERNAME=$(gcloud config get-value account | awk -F@ '{print $1}' ) 
export GCP_OS_USERNAME=$USER
```

?. __AWS:__ for a current session

```sh
export AWS_ACCESS_KEY_ID=<access-key>
export AWS_SECRET_ACCESS_KEY=<secret-access-key>
export AWS_REGION=us-east-1
export AWS_PAGER=
```

?. Define AWS user-wide credentials file

```sh
mkdir ~/.aws
cat <<EOF > ~/.aws/credentials

[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY

region = $AWS_REGION
EOF
```

?. Azure

```sh
az login
```
?. Check we are logged in
```
echo "Check if logged in gcloud: "
gcloud compute instances list

echo "Check if logged in aws: "
aws sts get-caller-identity

echo "Check if logged in az: "
az account show
```


# Install Apigee Hybrid Multi-cloud

**WARNING:** Install takes around 40 minutes. If you are using Cloud Shell (which by design is meant for an interactive work only), make sure you keep your install session alive, as CloudShell has  an inactivity timeout. For details, see: https://cloud.google.com/shell/docs/limitations#usage_limits

```
cd $HYBRID_HOME

cp -R $AHR_HOME/examples-mc-gke-eks-aks/. $HYBRID_HOME

./install-apigee-hybrid-gke-eks-aks.sh |& tee mc-install-`date -u +"%Y-%m-%dT%H:%M:%SZ"`.log
``` 


### Validate connectivity

After the install finished, you can use provisioned jumpboxes and suggested commands to check connectivity bewtween VPCs.

```sh
# to define jumpboxes IP address
pushd infra-gcp-aws-az-tf
source <(terraform output |awk '{printf( "export %s=%s\n", toupper($1), $3)}')
popd

gcloud compute config-ssh --ssh-key-file ~/.ssh/id_gcp
gcloud compute ssh vm-gcp --ssh-key-file ~/.ssh/id_gcp --zone europe-west1-b

ssh $USER@$GCP_JUMPBOX_IP -i ~/.ssh/id_gcp
ssh ec2-user@$AWS_JUMPBOX_IP -i ~/.ssh/id_aws
ssh azureuser@$AZ_JUMPBOX_IP -i ~/.ssh/id_az


hostname -i
# uname -a
#  sudo apt install -y netcat
# sudo yum install -y nc

while true ; do  echo -e "HTTP/1.1 200 OK\n\n $(date)" | nc -l -p 7001  ; done
```

# Multi-cloud connectivity check between Kubernetes containers

For connectivity check use following commands:
```
# source R#_CLUSTER variables
export AHR_HOME=~/ahr
export HYBRID_HOME=~/apigee-hybrid-multicloud
source $HYBRID_HOME/mc-hybrid-common.env

# gke
kubectl --context $R1_CLUSTER run -i --tty busybox --image=busybox --restart=Never -- sh

# eks
kubectl --context $R2_CLUSTER run -i --tty busybox --image=busybox --restart=Never -- sh

# aks
kubectl --context $R3_CLUSTER run -i --tty busybox --image=busybox --restart=Never -- sh


#
hostname -i

# nc-based server
while true ; do  echo -e "HTTP/1.1 200 OK\n\n $(date)" | nc -l -p 7001  ; done

# nc client
nc -v 10.4.0.76 7001

# delete busybox containers
kubectl --context $R1_CLUSTER delete pod busybox
kubectl --context $R2_CLUSTER delete pod busybox
kubectl --context $R3_CLUSTER delete pod busybox
```

# Cassandra Replication Walkthrough

```
# for each cluster: 1, 2, 3
kubectl --context $R1_CLUSTER run -i --tty --restart=Never --rm --image google/apigee-hybrid-cassandra-client:1.0.0 cqlsh

# at the shell, execute cqlsh and enter password, default: iloveapis123
cqlsh apigee-cassandra-default-0.apigee-cassandra-default.apigee.svc.cluster.local -u ddl_user --ssl

describe tables;

# WARNING: Replace my organization name with your organization name with dashes replaced with underscores!!

select * from kms_qwiklabs_gcp_03_d1330351146a_hybrid.developer;

```


## Remove resources

```
pushd infra-cluster-az-tf
terraform destroy
popd

pushd infra-cluster-gke-eks-tf
terraform destroy
popd

pushd infra-gcp-aws-az-tf
terraform destroy
popd
```