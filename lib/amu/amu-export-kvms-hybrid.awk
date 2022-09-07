@include "amu-lib.awk"

BEGIN{
    FS="|"

    # expected variables:
    # DEK EXPORT_DIR TGT

    header = 0
}
NF==10 {
    if( !header ){
        # skip header row, which is the first data one
        header = 1
        next
    }

# TODO: [ ] refactor to header columns offsets
#     print trim($1),$2, $3, $5  #, ">>", trim($10)
     org = trim($1)
     scopetoken = trim($2)
     kvm = trim($3)
     entry = trim($5)

     value = aesdecrypt( trim($10)   , DEK )

    # scope processing
    split( scopetoken, scopearr, "###"  )
    if ( scopetoken ~ /^$/ ){
        env = "-"

        scopetype = "org"
    }else if(  scopetoken ~ /^environments###/) {
        env = scopearr[2]

        scopetype = "env"
    }else{
        print "Scope is not recognised: " scopetoken
    }

    print( "INFO: Processing org: " org ", env: " env ", kvm: " kvm "..." )

    kvms[ kvm ][ entry ] = value

    scopes[ scopetype ][env][ kvm ][ entry ] = value
}

END{
    #scopes iterator:
    for( scope in scopes ){

        for( env in scopes[ scope ] ){

            json = ""
            jsonsep = ""

            for ( kvm in scopes[scope][env]){
                print( "INFO: Exporting org: " org ", env: " env ", kvm: " kvm "..." )

                jsonentry = ""
                jsonentrysep = ""
                for ( entry in scopes[scope][env][kvm] ){
                    
                    value = scopes[scope][env][kvm][entry]

                    # export: maven
                    jsonentry = jsonentry jsonentrysep "{\"name\": \"" entry "\",\"value\":\"" jsonescape( value ) "\"}"

                    jsonentrysep = ", "

                }
                
                if( TGT == "maven" ){
                    ## TGT=maven: accumulate kvm objects

                    json = json jsonsep "{ \"entry\": [ " jsonentry "], \"name\": \"" kvm "\" }"
                }else{
                    ## TGT=apigeecli: emit kvm object to kvm file

                    json = "{ \"keyValueEntries\": [ " jsonentry "], \"nextPageToken\": \"\" }"
                    # TODO: [ ] paging!!
                    page = 0

                    if( scope == "env" ){
                        file = EXPORT_DIR "/env_" env "_" kvm "_kvmfile_" page ".json"
                    }else if( scope == "org" ){
                        file = EXPORT_DIR "/org_" kvm "_kvmfile_" page ".json"
                    }

                    system( "mkdir -p " EXPORT_DIR )

                    cmd =  "jq '.' <<< '" json "' > '" file "'"
                    system( cmd  )
                }

                jsonsep = ","
            }

            ## TGT=maven: 
            # array of entry objects
            if( TGT == "maven" ){

                if( scope == "env" ){
                    folder = "/env/" env
                }else if( scope == "org" ){
                    folder = "/org"
                }

                json = "[" json "]"

                file = EXPORT_DIR folder "/kvms.json"

                system( "mkdir -p " EXPORT_DIR folder)

                cmd =  "jq '.' <<< '" json "' > '" file "'"
                system( cmd  )
            }
        }
    }
}
