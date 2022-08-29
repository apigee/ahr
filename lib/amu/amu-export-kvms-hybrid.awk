@include "amu-lib.awk"

BEGIN{
    FS="|"

    # expected variables:
    # DEK EXPORT_DIR

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
     scope = trim($2)
     kvm = trim($3)
     entry = trim($5)

     value = aesdecrypt( trim($10)   , DEK )

    # scope processing
    split( scope, scopearr, "###"  )
    env = scopearr[2]


    kvms[ kvm ][ entry ] = value

    scopes[ "env" ][env][ kvm ][ entry ] = value
}

END{
    #scopes iterator:
    for( scope in scopes ){
        if( scope == "env" ){

            for( env in scopes[ scope ] ){
                print "  env: " env

                folder = "/env/" env


                json = ""
                jsonsep = ""

                for ( kvm in scopes[scope][env]){
                    print "        kvm: " kvm

                    jsonentry = ""
                    jsonentrysep = ""
                    for ( entry in scopes[scope][env][kvm] ){
                        
                        value = scopes[scope][env][kvm][entry]

                        # export: maven
                        jsonentry = jsonentry jsonentrysep "{\"name\": \"" entry "\",\"value\":\"" jsonescape( value ) "\"}"

                        jsonentrysep = ", "

                    }
                    
                    json = json jsonsep "{ \"entry\": [ " jsonentry "], \"name\": \"" kvm "\" }"

                    jsonsep = ","
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
