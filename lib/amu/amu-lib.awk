
function jqhas( json, property,     cmd, result ){

    cmd = "echo '" json "' | jq 'has(\"" property "\")' -r"
    cmd | getline result
    close(cmd)
    return result
}

function jqget( json, filter,     cmd, result ){

    cmd = "echo '" json "' | jq '" filter "' -r"
    cmd | getline result
    close(cmd)
    return result
}

function aesdecrypt( datab64, keyhex,     cmd, result){

    cmd = "bash -c 'echo -n " datab64 "| openssl enc -aes-128-ecb -d -K " keyhex " -base64 -A'"
    result = ""
    sep = ""
    while( cmd | getline line ){
        result = result sep line
        sep="\n"
    }
    close(cmd)

    return result
}

function b64tohex( datab64,     cmd, result ){

    cmd = "echo " datab64 "| base64 -d | xxd -ps"
    cmd | getline result
    close(cmd)

    return result
}


function ltrim( s ){ sub(/^[ ]+/, "", s); return s }

function rtrim( s ){ sub(/[ ]+$/, "", s); return s }

function trim( s ){ return rtrim(ltrim(s)); }


function jsonescape( s ){ 
    r = s
    gsub( /"/, "\\\"", r)
    gsub( /\n/, "\\n", r)
    return r
}

