
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
    while( cmd | getline line ) result = result "\n" line
    close(cmd)

    return result
}

function b64tohex( datab64,     cmd, result ){

    cmd = "echo " datab64 "| base64 -d | xxd -ps"
    cmd | getline result
    close(cmd)

    return result
}


