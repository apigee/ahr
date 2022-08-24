#!/bin/sh
# This scripts sets up peering to the Apigee tenant project where Apigee SaaS GKE cluster runs.
endpoint=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/ENDPOINT -H "Metadata-Flavor: Google")


# https://www.envoyproxy.io/docs/envoy/latest/start/install
sudo apt update
sudo apt install debian-keyring debian-archive-keyring apt-transport-https curl lsb-release
curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | sudo gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg

# Verify the keyring - this should yield "OK"
echo a077cb587a1b622e03aa4bf2f3689de14658a9497a9af2c427bba5f4cc3c4723 /usr/share/keyrings/getenvoy-keyring.gpg | sha256sum --check
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/debian $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/getenvoy.list

sudo apt update
sudo apt install getenvoy-envoy

# https://www.envoyproxy.io/docs/envoy/latest/start/quick-start/run-envoy
envoy -c /opt/apigee/config.yaml