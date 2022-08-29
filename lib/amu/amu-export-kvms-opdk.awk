#!/usr/bin/env awk

@include "awk-lib.awk"

BEGIN{

    # stderr: cassandra-cli output for an org
    # expected variables:
    # KER EXPORT_DIR


# scopes:
# org: name=s@kvmaps:s@__ apigee__kvm__.keystore
#      s@kvmaps:s@kvmorg
# env: name=s@env:s@dev:s@kvmaps:s@__ apigee__kvm__.keystore
#      s@env:s@dev:s@kvmaps:s@encryptedkvm
# api: name=s@apis:s@ping:s@kvmaps:s@__ apigee__kvm__.keystore
#      name=s@apis:s@ping:s@kvmaps:s@kvmproxy
# rev: name=s@apis:s@ping:s@revision:s@1:s@kvmaps:s@__ apigee__kvm__.keystore
#      name=s@apis:s@ping:s@revision:s@1:s@kvmaps:s@kvmprev
#
# sieve: apis:<api>:@revision:<rev>; apis<api>; s@env:s@<env>; <org>;


    # keystores{}
    # kvmaps{}

}

/^=> \([^)]*\)$/{

    match( $0, /^=> \(([^)]*)\)$/, ms)
    split( ms[1], ts, ", " )
    for( i = 0; i < length(ts); i++ ){
        idx = index( ts[i], "=" )
        tokens[ substr( ts[i], 0, idx-1 ) ] = substr( ts[i], idx+1, length( ts[i] ))
    }

    if( jqhas( tokens["value"], "__ apigee__kvm__.keystore" ) == "true" ){
        # extract dek and store dekhex and scope

        keystore = jqget( tokens["value"], ".\"__ apigee__kvm__.keystore\"" )

        dekb64 = jqget( keystore, ".[]|select(.name==\"key1\").value" )

        dek = aesdecrypt( dekb64, KEK )
        dekhex = b64tohex( dek )

        keystores[ tokens["name"] ] = dekhex
    }else{
        # kvmap
        kvmaps[ tokens["name"] ] = tokens["value"]

    }
}

END{

    for (scopename in kvmaps){

        json = ""

        split( scopename, ts, "s@kvmaps:s@" )

        scope = ts[1]
        kvm = ts[2]
print "  kvm: " kvm        
print "  scope: " scope
        if( scope ~ /^$/ ){

            scopetype = "org"
            folder = "/org"
        }else if( scope ~ /^s@apis:s@([^:]+):s@revision:s@([^:]+):$/ ){

            scopetype = "rev"
            match( scope, /^s@apis:s@([^:]+):s@revision:s@([^:]+):$/, ts )
            api = ts[1]            
            rev = ts[2]
            folder = "/api/" api "/rev/" rev
        }else if( scope ~ /^s@apis:s@([^:]+):$/ ){
            scopetype = "api"
            match( scope, /^s@apis:s@([^:]+):$/, ts )
            api = ts[1]            
            folder = "/api/" api
        }else if( scope ~ /^s@env:s@([^:]+):$/ ){
            scopetype = "env"

            match( scope, /^s@env:s@([^:]+):$/, ts )
            env = ts[1]
            folder = "/env/" env
        }else{
            print "Scope is not recognised: " scope
        }
print "  scopetype: " scopetype
print " folder: " folder

        dekhex = keystores[ scope "s@kvmaps:s@__ apigee__kvm__.keystore"  ]
        # process kvm entries

        encrypted = jqget( kvmaps[ scopename ], ".__apigee__encrypted"  )
        
        entries = jqget( kvmaps[ scopename ], "." kvm )

        if( encrypted == "null" ){

            json = json entries
        }else{

            sep = ""

            json = json "["

            # reassemble while decrypt
            cmd = "echo '" entries "' | jq '.[]|[.name, .value]|@csv' -r"
            while( cmd | getline csv > 0 ){

                # assume: 2 tokens, on second element to be simple base64 and first element name syntax, so no need for a complex parser
                split(csv, csvarr, ",")

                name = csvarr[1]
                value = aesdecrypt( csvarr[2], dekhex )

                json = json sep "{\"name\":" name ",\"value\":\"" value "\"}"

                sep = ", "
            }
            close(cmd)
            json = json "]"

        }

        json = "[ { \"entry\": " json ", \"name\": \"" kvm "\" } ]"


        file = EXPORT_DIR folder "/kvms.json"

        # catenate arrays in an var and a file
        system( "mkdir -p " EXPORT_DIR folder)
        system( "echo '" json "' | if [ -f " file " ]; then cat - " file "; else cat -; fi |jq -s 'add' > " file ".tmp && mv " file ".tmp " file )
    }
}
