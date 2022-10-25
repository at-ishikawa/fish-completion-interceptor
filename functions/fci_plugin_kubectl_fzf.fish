function fci_plugin_kubectl_fzf -d "The plugin of fish-completion-interceptor to run kubectl fzf"
    # TODO: Support options for each sub command
    argparse --ignore-unknown \
        'n/namespace=' \
        -- $argv

    set -l namespace "$_flag_namespace"
    set -l lastArg $argv[-1]

    set -f resource
    set -f query
    set -f i 2
    while [ $i -le (count $argv) ]
        set -l arg $argv[$i]
        switch $arg
            case "port-forward"
                # Check that current cursor is on this
                if [ "$arg" = "$lastArg" ]
                    return 1
                end
                set resource "pods,services"
            case "log" "logs"
                # Check that current cursor is on this
                if [ "$arg" = "$lastArg" ]
                    return 1
                end

                set resource "pods"
            case "get"  "describe" "delete"
                set i (math $i + 1)
                # TODO: Assuming no options between subcommand and resource
                set resource $argv[$i]
            # TODO support for other subcommands like rollout
            case '*'
                set query $arg
        end
        set i (math $i + 1)
    end

    if [ "$resource" = "" ]; or [ "$resource" = "$lastArg" ];
        return 1
    end

    set -l options
    if [ "$namespace" != "" ]
        set options -n $namespace
    end
    if [ "$query" != "" ]
        set options $options -q $query
    end
    echo (eval $__FCI_PLUGIN_KUBECTL_FZF_COMMAND $resource $options)
end
