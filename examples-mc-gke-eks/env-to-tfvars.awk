

# Example:
#   export GCP_VPC_CIDR=10.0.0.0/14
/export /{
  split( $2, a, "=" )

  printf( "%s = \"%s\"\n", tolower( a[1] ), ENVIRON[ a[1] ] )

}

/^$/
