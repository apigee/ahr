# Apigee ngSaaS Trial Install Wrapper Script

This script creates an ng-saas trial instance. It uses gcloud command to create a hybrid runtime and add an enovoy load balancer for external exposure.

The script follows the documentation installation steps. The relevant step numbers are added for easier cross-reference.



You need to set up a PROJECT environment variable.

Here is an example of fetching a Qwiklabs project id if you're using QwikLabs.
```
export PROJECT=$(gcloud projects list|grep qwiklabs-gcp|awk '{print $1}')
```

You can control script execution by overriding some environment variables.

For flexibility, you can override `REGION` and `AX_REGION` variables:

```
export REGION=europe-west1
export AX_REGION=europe-west1
```

Script invocation:

```
./bin/apigee-ngsaas-trial-install.sh
```

> NOTE: To invoke the script directly from the github repo, use
> ```
> curl -L https://raw.githubusercontent.com/apigee/ahr/main/bin/apigee-ngsaas-trial-install.sh | bash -
> ```

After the script runs, it displays LB IP, certificate location and generated `RUNTIME_HOST_ALIAS`, as well as a way to send a test request.

Sample Output:
```
export RUNTIME_IP=35.227.201.175

export RUNTIME_SSL_CERT=~/mig-cert.pem
export RUNTIME_SSL_KEY=~/mig-key.pem
export RUNTIME_HOST_ALIAS=$PROJECT-eval.apigee.net 

curl --cacert $RUNTIME_SSL_CERT https://$RUNTIME_HOST_ALIAS/hello-world -v --resolve "$RUNTIME_HOST_ALIAS:443:$RUNTIME_IP"
```

A self-signed certificate is generated for your convenience. 

The curl command above uses --resolve for ip address resolution and --cacert for trusting the certificate.

To be able to execute requests transparantly at your development machine, you need:

1. Add the `RUNTIME_SSL_CERT` certificate your machine truststore;
2. Add the `RUNTIME_IP` with the `RUNTIME_HOST_ALIAS` to your machine's `/etc/hosts` file.



