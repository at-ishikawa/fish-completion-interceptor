__fci_functions

function __fci_plugin_kubectl_fzf \
    --argument-names resource
    argparse "namespace=?" "query=?" -- $argv; or return 1

    set -l has_header true
    set -l is_pod false
    if string match -q "*,*" "$resource"; or [ "$resource" = all ]
        set has_header false
    else if contains "$resource" pod pods
        set is_pod true
    end

    set -l kubectl_options
    set -l fzf_kubectl_describe_preview_command
    set -l fzf_kubectl_log_preview_command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI logs --follow {1}"
    set -l header_lines 1

    if $has_header
        set fzf_kubectl_describe_preview_command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe $resource {1}"
    else
        set kubectl_options $kubectl_options --no-headers=true
        # if there is no header, it means kubectl runs againts multiple resources or all
        set header_lines 0
        set fzf_kubectl_describe_preview_command "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI describe {1}"
    end

    set -l namespace $_flag_namespace
    if [ "$namespace" != "" ]
        set kubectl_options $kubectl_options --namespace=$namespace
        set fzf_kubectl_describe_preview_command "$fzf_kubectl_describe_preview_command" "--namespace=$namespace"
        set fzf_kubectl_log_preview_command "$fzf_kubectl_log_preview_command" "--namespace=$namespace"
    end

    set -l kubectl_list_command (echo "$__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get $resource $kubectl_options" | string trim)
    set -l fzf_options --multi \
        "--preview=$fzf_kubectl_describe_preview_command" \
        "--query=$_flag_query" \
        "--header-lines=$header_lines" \
        "--bind=ctrl-r:reload($kubectl_list_command)"
    if $is_pod
        # Change a preview and run tail a log
        # https://github.com/junegunn/fzf/blob/4e85f72f0ee237bef7a1617e0cf8c811a4091d72/ADVANCED.md#log-tailing
        set -a fzf_options "--header=Ctrl-l: kubectl logs / Ctrl-d: kubectl describe / Ctrl-r: Reload" \
            "--bind=ctrl-l:change-preview($fzf_kubectl_log_preview_command)+change-preview-window(follow)" \
            "--bind=ctrl-d:change-preview($fzf_kubectl_describe_preview_command)+change-preview-window(nofollow)"
    else
        set -a fzf_options "--header=Ctrl-r: Reload"
    end

    FZF_DEFAULT_COMMAND="$kubectl_list_command" \
        __fci_fzf $fzf_options |
        awk '{ print $1 }' |
        string trim
    return $pipestatus[1] # fzf status
end

function __fci_plugin_kubectl_fzf_namespace_mode \
    --argument-names commandline_args
    set -l args (string split " " -- $commandline_args)

    if string match --quiet --regex -- "^(-n|--namespace)=?(?<namespace>.*)" "$args[-1]"
        echo "$namespace"
        return 0
    end
    if string match --quiet --regex -- "^(-n|--namespace)" "$args[-2]"
        echo "$args[-1]"
        return 0
    end

    return 1
end

function fci_plugin_kubectl_fzf \
    --description "The plugin of fish-completion-interceptor to run kubectl fzf"

    if [ (count $argv) -lt 2 ]
        return 0
    end

    set -l namespace_query (__fci_plugin_kubectl_fzf_namespace_mode "$argv")
    if [ $status -eq 0 ]
        __fci_plugin_kubectl_fzf namespace "--query=$namespace_query"
        return $status
    end

    argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_global_options -- $argv
    set -l namespace "$_flag_namespace"

    # $argv[1]: kubectl
    # $argv[2]: sub command
    set -l subcommand $argv[2]
    if [ "$subcommand" = "$argv[-1]" ]
        return 0
    end

    set -l resource
    switch $subcommand
        case port-forward
            argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_port_forward_options -- $argv
            set resource "pods,services"
        case log logs
            argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_logs_options -- $argv
            set resource pods
        case exec
            argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_exec_options -- $argv
            set resource pods
        case edit
            argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_edit_options -- $argv
            set resource $argv[3]
        case get
            argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_get_options -- $argv
            set resource $argv[3]
        case describe
            argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_describe_options -- $argv
            set resource $argv[3]
        case delete
            argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_delete_options -- $argv
            set resource $argv[3]
            # TODO support for other subcommands like rollout
        case view-secret
            set resource secrets
        case '*'
            return 0
    end

    if [ "$resource" = "" ]; or [ "$resource" = "$argv[-1]" ]
        return 0
    end

    set -l query $argv[-1]

    __fci_plugin_kubectl_fzf "$resource" "--namespace=$namespace" "--query=$query"
end
