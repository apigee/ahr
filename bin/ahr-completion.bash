_ahr() {

    declare -a ACTIONS

    local command=$1
    case $command in
    ahr-runtime-ctl)
        ACTIONS=(get home template apigeectl delete setsync setproperty org-validate-name org-create org-config env-create env-group-create env-group-assign)
        ;;
    ahr-cluster-ctl)
        ACTIONS=(create context template delete enable asm-get asm-template)
        ;;
    ahr-sa-ctl)
        ACTIONS=(create config delete rebind)
        ;;
    ahr-cs-ctl)
        ACTIONS=(keyspaces-list keyspaces-expand nodetool)
        ;;
    ahr-verify-ctl)
        ACTIONS=(cert-create-ssc cert-is-valid host-ip sa-key api-check api-enable all)
        ;;
    esac

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
        --ax-region)
           COMPREPLY=( $( compgen -W '
                australia-southeast1 europe-west1 europe-west2
                us-central1 us-east1 us-east4 us-west1
             '  -- "$cur" ) )
           return 0
           ;;
    esac


    # no action yet, show what actions we have
    if [[ "$action" = "" ]]; then
       COMPREPLY=( $( compgen -W '${ACTIONS[@]}' -- "$cur" ) )
       return 0
    fi

    if [[ "$cur" =~ ^-.* ]]; then
        case $command in
            ahr-runtime-ctl)
                case $action in
                    org-create)
                        COMPREPLY=( $( compgen -W '--ax-region' -- "$cur" ) )
                        return 0
                    ;;
                esac
                ;;
            ahr-verify-ctl)
                case $action in
                    all)
                        COMPREPLY=( $( compgen -W '--stop-on-error' -- "$cur" ) )
                        return 0
                    ;;
               esac
               ;;
        esac
    fi

} &&
complete -F _ahr ahr-runtime-ctl &&
complete -F _ahr ahr-cluster-ctl &&
complete -F _ahr ahr-sa-ctl &&
complete -F _ahr ahr-verify-ctl &&
complete -F _ahr ahr-cs-ctl

