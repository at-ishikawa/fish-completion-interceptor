function __fci_plugin_kubectl_fzf_run_kubectl -a resource -a namespace -a has_header
    set -l kubectl_options
    if [ "$namespace" != "" ]
        set kubectl_options $kubectl_options --namespace=$namespace
    end
    if not $has_header
        set kubectl_options $kubectl_options --no-headers=true
    end
    $__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get $resource $kubectl_options
    return $status
end

# Because fzf uses stderr to show its interface
# This function doesn't use stderr to show an error message
function __fci_plugin_kubectl_fzf_run_fzf
    set -l resource $argv[1]
    set -l namespace $argv[2]
    set -l query $argv[3]
    set -l has_header $argv[4]
    set -l candidates $argv[5..-1]

    set -l fzf_options $FCI_PLUGIN_KUBECTL_FZF_FZF_OPTION
    if [ "$query" != "" ]
        set fzf_options $fzf_options -q $query
    end
    set -l preview_command
    if $has_header
        set fzf_options $fzf_options --header-lines 1
        set preview_command "kubectl describe $resource {1}"
    else
        # if there is no header, it means kubectl runs againts multiple resources or all
        set preview_command "kubectl describe {1}"
    end
    if [ "$namespace" != "" ]
        set preview_command "$preview_command" "--namespace=$namespace"
    end

    set -l fzf_result (string split0 $candidates | $__FCI_PLUGIN_KUBECTL_FZF_FZF_CLI $fzf_options --preview="$preview_command")
    set -l fzf_status $status
    if [ $fzf_status -ne 0 ]
        echo "$fzf_result"
        return $fzf_status
    end

    string split0 -- $fzf_result | awk '{ print $1 }' | string trim
    return 0
end

function fci_plugin_kubectl_fzf -d "The plugin of fish-completion-interceptor to run kubectl fzf"
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
    case "exec"
        argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_exec_options -- $argv
        set resource "pods"
    case "edit"
        argparse --ignore-unknown $__fci_plugin_kubectl_fzf_kubectl_edit_options -- $argv
        set resource $argv[3]
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

    string match -q "*,*" "$resource"; or [ "$resource" = "all" ]
    if [ "$resource" = "" ]; or [ "$resource" = "$argv[-1]" ]
        return 0
    end
    set -l has_header true
    if string match -q "*,*" "$resource"; or [ "$resource" = "all" ]
        set has_header false
    end

    set -l query $argv[-1]

    set -l candidates (__fci_plugin_kubectl_fzf_run_kubectl $resource "$namespace" $has_header 2>&1)
    set -l kubectl_status $status
    if [ $status -ne 0 ]
        echo "$candidates" >&2
        return $kubectl_status
    end
    if [ (string split0 $candidates | wc -l) -lt 2 ]
        echo "$candidates" >&2
        return 1
    end

    set -l result (__fci_plugin_kubectl_fzf_run_fzf $resource "$namespace" "$query" $has_header $candidates)
    set -l fzf_status $status
    if [ $fzf_status -ne 0 ];
        echo $result >&2
        return $fzf_status
    end
    if [ "$result" = "" ]
        return 1
    end
    echo $result
    return 0
end
