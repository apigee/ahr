@include "amu-lib.awk"

BEGIN{


    print( "hi!")

    
}

NF==19 {
    
     print $1,$3, $5, $9
     


print "---"
print dek
    print "---"
    print aesdecrypt( $19, dek )
    if( NR==2) exit
}