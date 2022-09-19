

### AMU -- Apigee Migration Utility

* also: Atomic Mass Unit, or Dalton https://en.wikipedia.org/wiki/Dalton_(unit).


```diff
- *BIG RED NOTICE:* Multiple pieces of data processed by this utility are
- sensitive and are either encrypted data or encryption mateial. 
- Be careful and conscious when and how you keep
- and store the data.
```

The recommended way is to use 0600 directory.

## AMU Commands and Options


### Options

To pass a required parameter value, you can mix-and-match two styles of options. Either provide an `--` option, with  dash-separated multiple words or define an environment variable with underscore-separated multiple words. 

For example, those to fragments are equivalent:

```sh
# passing parameters implicitly

export ORG=apigee-hybrid-org
export SRC=hybrid
export SRC_VAR 1.4
    
export EMIGRATE_DIR=~/amu/hybrid-org/hybrid-1.4
export EXPORT_DIR=~/amu/hybrid-org/maven
export 

amu kvms export
```

```sh
# passing parameters explicitely

amu kvms export --org apigee-hybrid-org \
    --src hybrid
    --src-var 1.4
    --tgt maven
    --emigrate-dir=~/amu/hybrid-org/hybrid-1.4 \
    --export_dir ~/amu/hybrid-org/maven
```

### AMU Commands

```sh
# for opdk
amu organizations list --org $ORG --src $SRC --cass-ip $CASS_IP

# for hybrid 
amu organizations list --org $ORG --src $SRC

# for opdk
amu kek export --src $SRC --vault $VAULT --storepass $STOREPASS

# for hybrid
amu kek export --src $SRC --env $ENV

# for opdk or hybrid
amu kvms emigrate --org $ORG --src $SRC --emigrate-dir $EMIGRATE_DIR

# for opdk
amu kvms export --org $ORG --src $SRC --kek $KEK --emigrate-dir $EMIGRATE_DIR 

for hybrid
amu kvms export --org $ORG --src $SRC --dek $DEK --emigrate-dir $EMIGRATE_DIR --export-dir $EXPORT_DIR


amu cassandra backup --org $ORG --src $SRC --backup-dir $BACKUP_DIR

amu cassandra cqlsh --hybrid-version $HYBRID_VERSION
```

### Cassandra cqlsh command

`amu` provides a convenience operation to start a cassandra client pod and log into its cqlsh utility. `amu' checks for status of the cassandra client pod and if it's not `RUNNING`, deletes the finished one and starts another instance for 3600 seconds.

### Emigration and Export

`amu` has an `emigrate` operation that takes the relevant contents of Cassandra Apigee tables and stores them in an $EMIGRATE_DIR directly

The `export` operation processes files located in the $EMIGRATE_DIR directory and generates a target output, the file structures suitable for further importing by either apigee config maven plugin or apigeecli utility. As sackmesser is compatible with config maven input files, you can use sackmesser to import the data.


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

Another important consideration to use environment variables is security: you do not want to flash the sensitive data at the terminal. Passing them implicitly allows you to avoid it.

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
export STOREPASS=$(awk -F= '/^vault.passphrase/{FS="=";print($2)}' /opt/apigee/edge-management-server/conf/credentials.properties)
export VAULT=$(awk -F= '/^vault.filepath/{FS="=";print($2)}' /opt/apigee/edge-management-server/conf/credentials.properties)

export KEK=$(amu kek export --src $SRC --storepass $STOREPASS --vault VAULT)

```

## Hybrid: KEK

```
export KEK=$(amu kek export --src $SRC --org $ORG --env $ENV)
```



## KVM Migration

```sh
amu kvms emigrate --org $ORG 
```

```sh
amu kvms export --org $ORG







