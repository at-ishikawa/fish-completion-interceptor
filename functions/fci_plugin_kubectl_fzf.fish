__fci_functions

function __fci_plugin_kubectl_fzf_run_kubectl \
    --description "Run kubectl and handle an error"
    set -l result ($__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get $argv 2>&1)
    set -l cli_status $status

    if [ $cli_status -ne 0 ]
        echo -n -e "$result"
        return $cli_status
    end
    # Assumes an error if there is no resource by kubectl
    if [ (string split "\n" -- $result | wc -l) -lt 2 ]
        echo -n -e "$result"
        return 1
    end

    string split "\n" -- $result
    return 0
end

function __fci_plugin_kubectl_fzf \
    --argument-names resource
    argparse "namespace=?" "query=?" -- $argv; or return 1

    set -l has_header true
    if string match -q "*,*" "$resource"; or [ "$resource" = all ]
        set has_header false
    end

    set -l kubectl_options
    set -l fzf_preview_command
    set -l header_lines 1

    if $has_header
        set fzf_preview_command "kubectl describe $resource {1}"
    else
        set kubectl_options $kubectl_options --no-headers=true
        # if there is no header, it means kubectl runs againts multiple resources or all
        set header_lines 0
        set fzf_preview_command "kubectl describe {1}"
    end
    set -l namespace $_flag_namespace
    if [ "$namespace" != "" ]
        set kubectl_options $kubectl_options --namespace=$namespace
        set fzf_preview_command "$fzf_preview_command" "--namespace=$namespace"
    end

    set -l cli_result (__fci_plugin_kubectl_fzf_run_kubectl $resource $kubectl_options)
    set -l cli_status $status
    if [ $cli_status -ne 0 ]
        echo -e -n "$cli_result"
        return $cli_status
    end

    string split "\n" -- $cli_result |
        __fci_fzf --multi "--preview=$fzf_preview_command" "--query=$_flag_query" "--header-lines=$header_lines" |
        awk '{ print $1 }' |
        string trim
    return $pipestatus[2] # fzf status
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
        case '*'
            return 0
    end

    if [ "$resource" = "" ]; or [ "$resource" = "$argv[-1]" ]
        return 0
    end

    set -l query $argv[-1]

    __fci_plugin_kubectl_fzf "$resource" "--namespace=$namespace" "--query=$query"
end
