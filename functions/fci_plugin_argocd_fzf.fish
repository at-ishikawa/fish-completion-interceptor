__fci_functions

function __fci_plugin_argocd_fzf_context_list
    argparse "query=?" -- $argv; or return 1

    set -l fzf_options --header-lines=1
    if [ -n "$_flag_query" ]
        set -a fzf_options "--query=$_flag_query"
    end

    set -l argocd_context_command "$__FCI_PLUGIN_ARGOCD_FZF_ARGOCD_CLI context"

    FZF_DEFAULT_COMMAND="$argocd_context_command" \
        __fci_fzf $fzf_options |
        awk '{ print $1 }' |
        string trim
    return $pipestatus[1]
end

function __fci_plugin_argocd_fzf_app_list \
    --argument-names subcommand

    argparse "context=?" "query=?" -- $argv; or return 1

    set -l argocd_options
    if [ -n "$_flag_context" ]
        set -a argocd_options "--context=$_flag_context"
    end

    set -l fzf_options --header-lines=1
    if [ -n "$_flag_query" ]
        set -a fzf_options "--query=$_flag_query"
    end

    set -l argocd_list_command (echo "$__FCI_PLUGIN_ARGOCD_FZF_ARGOCD_CLI app list $argocd_options" | string trim)
    set -l fzf_preview_command (echo "$__FCI_PLUGIN_ARGOCD_FZF_ARGOCD_CLI app $subcommand {1} $argocd_options" | string trim)

    set -a fzf_options "--preview=$fzf_preview_command"

    FZF_DEFAULT_COMMAND="$argocd_list_command" \
        __fci_fzf $fzf_options |
        awk '{ print $1 }' |
        string trim
    return $pipestatus[1]
end

function __fci_plugin_argocd_fzf_context_mode \
    --argument-names commandline_args
    set -l args (string split " " -- $commandline_args)

    if string match --quiet --regex -- "^(--context)=?(?<context>.*)" "$args[-1]"
        echo "$context"
        return 0
    end
    if string match --quiet --regex -- "^(--context)" "$args[-2]"
        echo "$args[-1]"
        return 0
    end

    return 1
end

function fci_plugin_argocd_fzf \
    --description "The plugin for argocd CLI"

    if [ (count $argv) -lt 2 ]
        return 0
    end

    # Context mode: when user is typing --context value, suggest contexts
    set -l context_query (__fci_plugin_argocd_fzf_context_mode "$argv")
    if [ $status -eq 0 ]
        __fci_plugin_argocd_fzf_context_list "--query=$context_query"
        return $status
    end

    argparse --ignore-unknown \
        'context=' \
        -- $argv

    # $argv[1]: argocd
    # $argv[2]: sub command
    set -l subcommand $argv[2]

    switch "$subcommand"
        case app
            # $argv[3]: app sub command
            if [ (count $argv) -lt 3 ]
                return 0
            end
            set -l app_subcommand $argv[3]
            if [ "$app_subcommand" = "$argv[-1]" ]
                return 0
            end

            switch "$app_subcommand"
                case get
                    set -l query $argv[-1]
                    __fci_plugin_argocd_fzf_app_list get "--context=$_flag_context" "--query=$query"
                    return $status
                case '*'
                    return 0
            end
        case login
            set -l query $argv[-1]
            if [ "$subcommand" = "$query" ]
                set query ''
            end
            __fci_plugin_argocd_fzf_context_list "--query=$query"
            return $status
        case '*'
            return 0
    end
end
