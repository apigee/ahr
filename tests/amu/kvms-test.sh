#!/usr/bin/env bash


# hybrid 1.5
# kvms-test-populate.sh hybrid test ping 1

# x
# kvms-test-populate.sh hybrid bap-emea-apigee-3 default-dev ping 1

# opdk
# kvms-test-populate.sh opdk org test ping 1


TYPE=$1
ORG=$2
ENV=$3

API=$4
REV=$5

function request(){
    # authn: token:creds:
    # mapihost: 
    local $
}


# Tests for kvmaps
# https://apidocs.apigee.com/docs/key-value-maps/1/overview


if [ "$TYPE" = "hybrid" ]; then
    MAPI=https://apigee.googleapis.com

    function token() { echo -n "$(gcloud config config-helper --force-auth-refresh | grep access_token | grep -o -E '[^ ]+$')" ; }
    export token


    AUTHN="-H \"Authorization: Bearer $(token)\""

else
    MAPI=http://10.128.0.22:8080
    #/oauth/token
    #MAPI=http://10.154.0.4:8080
fi





# kvm list
curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/environments/$ENV/keyvaluemaps


exit

# org

curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/keyvaluemaps -H "content-type: application/json" -d @- <<EOF
{
  "name": "amu-test-kvm-org",
  "encrypted": true
}
EOF

curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/keyvaluemaps/amu-test-kvm-org/entries -H "content-type: application/json" -d @- <<EOF
{
  "name": "keyname",
  "value": "keyvalue"
}
EOF
    
curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/keyvaluemaps/amu-test-kvm-org/entries -H "content-type: application/json" -d @- <<EOF
{
  "name": "keyname2",
  "value": "keyvalue2"
}
EOF


# scope: env
curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/environments/$ENV/keyvaluemaps -H "content-type: application/json" -d @- <<EOF
{
  "name": "amu-test-kvm-env",
  "encrypted": true
}
EOF

# scope: env, no encrypt
curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/environments/$ENV/keyvaluemaps/amu-test-kvm-env/entries -H "content-type: application/json" -d @- <<EOF
{
  "name": "keyname",
  "value": "keyvalue"
}
EOF

curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/environments/$ENV/keyvaluemaps/amu-test-kvm-env/entries -H "content-type: application/json" -d @- <<EOF
{
  "name": "keyname2",
  "value": "keyvalue2"
}
EOF


# get 
curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/environments/$ENV/keyvaluemaps/amu-test-kvm-env/entries

# scope: proxy
# https://api.enterprise.apigee.com/v1/organizations/{org_name}/apis/{api_name}/keyvaluemaps

curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/apis/$API/keyvaluemaps  -H "content-type: application/json" -d @- <<EOF
{
  "encrypted": true,
  "name": "amu-test-api-kvm"
}
EOF

curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/apis/$API/keyvaluemaps/amu-test-api-kvm/entries  -H "content-type: application/json" -d @- <<EOF
{
  "name": "keyname",
  "value": "keyvalue"
}
EOF

curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/apis/$API/keyvaluemaps/amu-test-api-kvm/entries  -H "content-type: application/json" -d @- <<EOF
{
  "name": "keyname2",
  "value": "keyvalue2"
}
EOF


# get
curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/apis/$API/keyvaluemaps 


# scope: to an API proxy revision.
https://api.enterprise.apigee.com/v1/organizations/{org_name}/apis/{api_name}/revisions/{revision_number}/keyvaluemaps

curl -H "Authorization: Bearer $(token)" $MAPI/v1/organizations/$ORG/apis/$API/revisions/1/keyvaluemaps  -H "content-type: application/json" -d @- <<EOF
{
  "encrypted": true,
  "entry": [
    {
      "name": "keyname",
      "value": "keyvalue"
    },
    {
      "name": "keyname2",
      "value": "keyvalue2"
    }
  ],
  "name": "amu-test-kvm-rev"
}
EOF