_apigeectl() {

    declare -a ACTIONS

    ACTIONS=(apply check-ready delete help init version)

    local action i
    for (( i=1; i < ${#COMP_WORDS[@]}-1; i++ )); do
        if [[ ${ACTIONS[@]} =~ ${COMP_WORDS[i]} ]]; then
            action=${COMP_WORDS[i]}
            break
        fi
    done

    local cur prev
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case $prev in 
        -c|--components)
           COMPREPLY=( $( compgen -W '
                cassandra logger mart metrics runtime synchronizer udca
             '  -- "$cur" ) )
           return 0
           ;;
        -f|--file-override-config)
           COMPREPLY=( $( compgen -o default -A file -A directory -- "$cur" ) )
           return 0
           ;;
    esac

    if [[ "$cur" =~ ^-.* ]]; then
        COMPREPLY=( $( compgen -W '
          -c --components --dry-run -f --file-override-config --help --print-yaml --settings
           ' -- "$cur" ) )
        return 0
    fi

    # no action yet, show what actions we have
    if [[ "$action" = "" ]]; then
       COMPREPLY=( $( compgen -W '${ACTIONS[@]}' -- "$cur" ) )
       return 0
    fi


} &&
complete -F _apigeectl apigeectl
