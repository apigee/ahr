# GCP/AWS or GCP/AWS/Azure VPN Topologies

This terraform project allows you to install non-default networking on either GCP/AWS or GCP/AWS/Azure combo with jumpboxes on each cloud and a sample 7000,7001 ports allowed to communication across clouds.

Of course, you need an active account at each of the two or three clouds.

## Terminal

 Use your working computer terminal or a VM  to overcome the timeout limit of CloudShell. We recommend to provision a default VM in your GCP project.

?. Create a VM. Doesn't matter which OS you're using. The only difference is usage of apt vs yum for installing required packages. We accept defaults to speed up this step, thus we are using Debian.

?. SSH into it

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
cd $HYBRID_HOME

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
## for operator
# TODO: [] move to bastion 
gcloud auth login --quiet

# use those pre-canned commands if you're using qwiklabs
export PROJECT=$(gcloud projects list|grep qwiklabs-gcp|awk '{print $1}')
export GCP_OS_USERNAME=$(gcloud config get-value account | awk -F@ '{print $1}' ) 


# otherwise, insert values:
export PROJECT=
export GCP_OS_USERNAME=

# gcp login for for scripts:
gcloud auth application-default login --quiet
```


?. AWS

?. for a current session

```sh
export AWS_ACCESS_KEY_ID=<access-key>
export AWS_SECRET_ACCESS_KEY=<secret-access-key>
export AWS_REGION=us-east-1
export AWS_PAGER=
```

?. Define AWS user-wide credencials file

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
./install-apigee-hybrid-gke-eks-aws.sh |& tee mc-install-`date -u +"%Y-%m-%dT%H:%M:%SZ"`.log
``` 


### Validate connectivity

After the install finished, you can use provisioned jumpboxes and suggested commands to check connectivity bewtween VPCs.

```sh
# to define jumpboxes IP address
pushd infra-cluster-az-tf
source <(terraform output |awk '{printf( "export %s=%s\n", toupper($1), $3)}')
popd

gcloud compute config-ssh
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