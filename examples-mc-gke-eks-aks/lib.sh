# source-me



function lif(){
  local file=$1
  local find=$2
  local replace=$3

  sed -i -E "s/^($find).*/\1$replace/g" $file
#  sed -i '/$find/{h;s/=.*/='"$replace"'/};${x;/^$/{s//'"$find"'='"$replace"'/;H};x}' $file


# sed -i '/^[ \t]*'"RUNTIME_IP2"'=/{h;s/=.*/='"$RUNTIME_IP2"'/};${x;/^$/{s//'"RUNTIME_IP2"'='"$RUNTIME_IP2"'/;H};x}' $HYBRID_ENV
# sed -i '\!^'"$FOOBAR"'=!{h;s!=.*!='"$newvalue"'!};${x;\!^$!{s!!'"$FOOBAR"'='"$newvalue"'!;H};x}' /home/pi/Public/test.txt

}

function check_files() {
    local filelist=$1

    local filenotset="F"

    for v in $filelist; do
        if [ -f "${!f}" ]; then
            >&2 echo "Required file $f is not found."
            filesnotset="T"
        fi
    done

    if [ "$filesnotset" = "T" ]; then
        >&2 echo ""
        >&2 echo "ABEND. Please make sure those files exist."
        return 1
    fi
}

# from: https://github.com/apigee/ahr/blob/main/bin/ahr-lib.sh
function check_envvars() {
    local varlist=$1

    local varsnotset="F"

    for v in $varlist; do
        if [ -z "${!v}" ]; then
            >&2 echo "Required environment variable $v is not set."
            varsnotset="T"
        fi
    done

    if [ "$varsnotset" = "T" ]; then
        >&2 echo ""
        >&2 echo "ABEND. Please set up required variables."
        return 1
    fi
}


function check_commands() {
    local comlist=$1

    local comsnotset="F"

    for c in $comlist; do
        if ! [ -x "$(command -v $c)" ]; then
            >&2 echo "Required command is not on your PATH: $c."
            comsnotset="T"
        fi
    done

    if [ "$comsnotset" = "T" ]; then
        >&2 echo ""
        >&2 echo "ABEND. Please make sure required commands are set and accesible via PATH."
        return 1
    fi
}


