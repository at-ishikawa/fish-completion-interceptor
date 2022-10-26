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

    set -l kubectl_options
    if [ "$namespace" != "" ]
        set kubectl_options $kubectl_options --namespace=$namespace
    end
    if string match -q "*,*" $resource; or [ "$resource" = "all" ]
        set -l kubectl_options $kubectl_options --no-headers=true
    end
    set -l candidates (kubectl get $resource $kubectl_options 2>&1)
    set -l kubectl_status $status
    if [ $status -ne 0 ]
        echo "$candidates" 2>&1
        return $kubectl_status
    end
    if [ (string split0 $candidates | wc -l) -lt 2 ]
        echo "$candidates" 2>&1
        return 1
    end

    set -l fzf_options $__FCI_PLUGIN_KUBECTL_FZF_FZF_OPTION --preview="kubectl describe $resource {1}"
    if [ "$query" != "" ]
        set fzf_options $fzf_options -q $query
    end

    set -l fzf_result (string split0 $candidates | fzf $fzf_options)
    set -l fzf_status $status
    if [ $status -ne 0 ];
        echo $fzf_result >&2
        return $fzf_status
    end

    set -l result (string split0 $fzf_result | awk '{ print $1 }' | string trim)
    if [ "$result" = "" ]
        return 1
    end
    echo $result
    return 0
end
