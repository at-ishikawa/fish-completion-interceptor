function fci_plugin_kubectl_fzf -d "The plugin of fish-completion-interceptor to run kubectl fzf"
    # TODO: Support options for each sub command
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
    case "port-forward"
        argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_port_forward_options -- $argv
        set resource "pods,services"
    case "log" "logs"
        argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_logs_options -- $argv
        set resource "pods"
    case "get"
        argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_get_options -- $argv
        set resource $argv[3]
    case "describe"
        argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_describe_options -- $argv
        set resource $argv[3]
    case "delete"
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

    set -l options
    if [ "$namespace" != "" ]
        set options $options -n $namespace
    end
    if [ "$query" != "" ]
        set options $options -q $query
    end

    # TODO: Handle an error. fzf shows interface on stderr so redirect stderr stops it working
    # set -l result (eval $__FCI_PLUGIN_KUBECTL_FZF_COMMAND $resource $options 2>&1)
    set -l result (eval $__FCI_PLUGIN_KUBECTL_FZF_COMMAND $resource $options)
    if [ $status -ne 0 ]
        # echo "$result" >&2
        return 1
    end
    if [ "$result" = "" ]
        return 1
    end
    echo $result
    return 0
end
