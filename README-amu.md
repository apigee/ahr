

### AMU -- Apigee Migration Utility

* also: Atomic Mass Unit, or Dalton https://en.wikipedia.org/wiki/Dalton_(unit).



BIG RED NOTICE: Multiple pieces of data processed by this utility are sensitive and encrypted. Be careful and conscious when and how you keep and store the data.
The recommended way is to use 0600 directory.

## AMU Commands and operation


emigrate -- dumps of cassandra <tables???>

export -- process emigrated file and produce target formats


## AMU Install Setup and Execution

Install

```sh
cd ~
git clone https://github.com/apigee/ahr.git
```

Session variables:

```sh
export AHR_HOME=~/ahr
export PATH=$AHR_HOME/bin:$PATH
```

the executable script is in ahr/bin folder.
the auxillary files are in ahr/lib/amu.
some useful test data are in ahr/tests/amu.


to operate



you can provide option values either implicitly or explicitly.

multiple options clutter the command line. for many common options it makes sense to use environment variables to pass them. 

Also, you can re-use commands that operate in hybrid and opdk, if you configure opdk/hybrid values via env variables.

Those syntaxes are equivalent:

implicit via env var
```
export CASS_IP=x.y.z.w
```

explicit via CLI option
```
--cass-ip=x.y.z.w
```



```sh
# opdk or hybrid
export SRC=opdk
export SRC_VER=4.51
# apigeecli or maven
export TGT=maven

# for opdk
export CASS_IP=10.154.0.4
export MAPI=http://10.154.0.4:8080

# for hybrid
# kubectl....TODO: [ ]
# MAPI=https://apigee.googleapis.com

export ORG=org
export ENV=dev

export API=ping
export REV=1

export EMIGRATE_DIR=~/amu-$ORG/$SRC-$SRC_VER
export EXPORT_DIR=~/amu-$ORG/$TGT
```


```sh
mkdir -p $EMIGRATE_DIR
mkdir -p $EXPORT_DIR
```

## OPDK: KEK

opdk 4.50 contains vault as a secret key entry in a JKS.

The vault location and a keystore and secret password are soft-coded in /opt/apigee/edge-management-server/conf

to extract a KEK for your installation, execute:

```sh
STOREPASS=$(awk -F= '/^vault.passphrase/{FS="=";print($2)}' /opt/apigee/edge-management-server/conf/credentials.properties)
VAULT=$(awk -F= '/^vault.filepath/{FS="=";print($2)}' /opt/apigee/edge-management-server/conf/credentials.properties)

KEK=$(amu kek export)

```



## KVM Migration

```sh
amu kvms emigrate --org $ORG 
```

```sh
amu kvms export --org $ORG







