
function lif(){
  local file=$1
  local find=$2
  local replace=$3

  sed -i -E "s/^($find).*/\1$replace/g" $file
#  sed -i '/$find/{h;s/=.*/='"$replace"'/};${x;/^$/{s//'"$find"'='"$replace"'/;H};x}' $file


# sed -i '/^[ \t]*'"RUNTIME_IP2"'=/{h;s/=.*/='"$RUNTIME_IP2"'/};${x;/^$/{s//'"RUNTIME_IP2"'='"$RUNTIME_IP2"'/;H};x}' $HYBRID_ENV
# sed -i '\!^'"$FOOBAR"'=!{h;s!=.*!='"$newvalue"'!};${x;\!^$!{s!!'"$FOOBAR"'='"$newvalue"'!;H};x}' /home/pi/Public/test.txt

}
