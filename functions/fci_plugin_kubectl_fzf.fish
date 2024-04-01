function __fci_plugin_kubectl_fzf_run_kubectl

    set -l args (string trim -- "$argv" | string split " " | string trim)
    set -l result ($__FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI get $args 2>&1)
    set -l cli_status $status

    if [ $cli_status -ne 0 ]
        echo -n -e "$result" >&2
        return $cli_status
    end
    # Assumes an error if there is no resource by kubectl
    if [ (string split "\n" -- $result | wc -l) -lt 2 ]
        echo -e "$result" >&2
        return 1
    end

    string split "\n" -- $result
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

    string match -q "*,*" "$resource"; or [ "$resource" = all ]
    if [ "$resource" = "" ]; or [ "$resource" = "$argv[-1]" ]
        return 0
    end
    set -l has_header true
    if string match -q "*,*" "$resource"; or [ "$resource" = all ]
        set has_header false
    end

    set -l query $argv[-1]

    set -l kubectl_options
    set -l fzf_options --multi
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
    if [ "$namespace" != "" ]
        set kubectl_options $kubectl_options --namespace=$namespace
        set fzf_preview_command "$fzf_preview_command" "--namespace=$namespace"
    end

    fci_run_fzf \
        __fci_plugin_kubectl_fzf_run_kubectl \
        "$resource $kubectl_options" \
        "$query" \
        "$fzf_preview_command" \
        $header_lines \
        "$fzf_options"
end
