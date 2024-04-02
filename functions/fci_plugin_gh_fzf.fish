__fci_functions

function __fci_plugin_gh_fzf_gh_cli

    argparse "repo=?" -- $argv
    set -l cli_options
    if [ -n "$_flag_repo" ]
        set -a cli_options "--repo=$_flag_repo"
    end

    $__FCI_PLUGIN_GH_FZF_GH_CLI pr list $cli_options
    return $status
end

function __fci_plugin_gh_fzf_pr_list

    argparse "repo=?" "query=?" -- $argv
    set -l fzf_preview_command "gh pr view {1}"
    if [ -n $_flag_repo ]
        set -a fzf_preview_command "--repo=$_flag_repo"
    end

    set -l cli_result (__fci_plugin_gh_fzf_gh_cli "--repo=$_flag_repo" 2>&1)
    set -l cli_status $status
    if [ $cli_status -ne 0 ]
        echo -n -e "$cli_result"
        return $cli_status
    end

    string split "\n" -- $cli_result |
        __fci_fzf "--query=$_flag_query" "--preview=$fzf_preview_command" |
        awk '{ print $1 }'
    return $pipestatus[2]
end

function fci_plugin_gh_fzf \
    --description "The plugin of fish-completion-interceptor to run gh with fzf"

    # $argv[1]: gh
    # $argv[2]: subcommand
    set -l subcommand $argv[2]

    switch $subcommand
        case pr
            argparse --ignore-unknown 'R/repo=' -- $argv
            # Get a last command line argument as a query
            set -l query $argv[-1]
            __fci_plugin_gh_fzf_pr_list "--repo=$_flag_repo" "--query=$query"
            return $status
    end

    return 0
end
