#!/usr/bin/env -S awk -f

#
# WARNING: this script has a side effect:
#  * it generates resolved module resource to stdout
#  * it copies variable .tf file into a module file location [side effect]
#

//

/source += +"[^"]+"/ {

  # tfi_dir
  tfi_dir_cmd = "dirname " FILENAME
  tfi_dir_cmd | getline tfi_dir
  close(cur_dir_cmd)

  match( $0, /"[^"]+"/ )
  var_dir = substr( $0, RSTART+1, RLENGTH-2 )

}

/# +include: / {
  var_file = $3

  match( $0, /^[ ]*#/ )
  tfi_indent =  substr( $0, RSTART, RLENGTH-1 )
  var_file_fp = tfi_dir "/" var_dir "/" var_file

  tfi_var_file = var_file
  gsub( /.tf$/, ".tfi.tf", tfi_var_file )
  tfi_var_file_fp = tfi_dir "/" tfi_var_file

  system( "cp " var_file_fp " " tfi_var_file_fp )

  tfi_file_cmd = "cat " tfi_var_file_fp
  while( (tfi_file_cmd | getline line) > 0) {
    if( match( line, /variable +"?[^"]+"?/ ) ) {
      split( line, tokens )
      var = tokens[2]
      gsub(/"/, "", var )
      print tfi_indent var " = var." var
    }
  }
  close( tfi_file_cmd )

}
