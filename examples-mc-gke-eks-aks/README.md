# GCP/AWS or GCP/AWS/Azure VPN Topologies

This terraform project allows you to install non-default networking on either GCP/AWS or GCP/AWS/Azure combo with jumpboxes on each cloud and a sample 7000,7001 ports allowed to communication across clouds.

Of course, you need an active account at each of the two or three clouds.

## Terminal

 Use your working computer terminal or a VM  to overcome the timeout limit of CloudShell. We recommend to provision a default VM in your GCP project.

?. Create a VM. Doesn't matter which OS you're using. The only difference is usage of apt vs yum for installing required packages. We accept defaults to speed up this step, thus we are using Debian.

?. SSH into it

?. Install utilites required by cloud cli utilities

```sh
sudo apt -y install mc jq git python3-pip
```

?. 

```sh
git clone https://github.com/yuriylesyuk/tf-multi-cloud-infra.git
```

?. CLIs

```sh
cd tf-multi-cloud-infra

./cli-terraform.sh
./cli-aws.sh
./cli-az.sh

source ~/.profile
```

### Cloud Logins

?. GCP: For Qwiklabs/CloudShell:

```sh
## for operator
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
export AWS_PAGER=
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_REGION=us-east-1
```

?. user-wide

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

## Create Infrastructure

?. to install gcp/aws, execute

```sh
./install-gcp-aws.sh
```

?. to install gcp/aws/azure, execute

```sh
install-gcp-aws-az.sh
```

> NOTE: to see the plan, use
> ```sh
> terraform plan 2>&1| less -r
> ```

### Validate connectivity

After the install finished, you can use provisioned jumpboxes and suggested commands to check connectivity bewtween VPCs.

```sh
# to define jumpboxes IP address
source <(terraform output |awk '{printf( "export %s=%s\n", toupper($1), $3)}')

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
