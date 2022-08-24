#!/usr/bin/env awk
BEGIN{

    CONFIG_DIR = "."

    kek = "14DADC9F2E3E0D3CC774F07F5A0357F1"


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

function jqhas( json, property,     cmd ){

    cmd = "echo '" json "' | jq 'has(\"" property "\")' -r"
    cmd | getline result
    close(cmd)
    return result
}

function jqget( json, filter,     cmd ){

    cmd = "echo '" json "' | jq '" filter "' -r"
    cmd | getline result
    close(cmd)
    return result
}

function aesdecrypt( datab64, keyhex,     cmd ){

    cmd = "echo " datab64 "| openssl enc -aes-128-ecb -d -K " keyhex " -base64"
    cmd | getline result
    close(cmd)

    return result
}

function b64tohex( datab64,     cmd ){

    cmd = "echo " datab64 "| base64 -d | xxd -ps"
    cmd | getline result
    close(cmd)

    return result
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

        dek = aesdecrypt( dekb64, kek )
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

        system( "mkdir -p " CONFIG_DIR folder)

        file = CONFIG_DIR folder "/kvms.json"

        # catenate arrays in an var and a file
        system( "echo '" json "' | if [ -f " file " ]; then cat - " file "; else cat -; fi |jq -s 'add' > " file ".tmp && mv " file ".tmp " file )
    }
}
