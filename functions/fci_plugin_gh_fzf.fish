function __fci_plugin_gh_fzf_run_gh
    $__FCI_PLUGIN_GHL_FZF_GH_CLI pr list
    return $status
end

function __fci_plugin_gh_fzf_gh_pr_cli \
    --description "" \
    --argument-names cli_options

    if [ -z $cli_options ]
        set -e cli_options
    end

    $__FCI_PLUGIN_GH_FZF_GH_CLI pr list $cli_options
    return $status
end

function __fci_plugin_gh_fzf_pr_list -d "The list of PRs" \
    -a repository \
    -a fzf_query

    set -l cli_options
    if [ -n "$repository" ]
        set cli_options --repo=$repository
    end

    set -l fzf_preview_command "gh pr view {1}"
    if [ -n $repository ]
        set -a fzf_preview_command "--repo=$repository"
    end

    fci_run_fzf \
        __fci_plugin_gh_fzf_gh_pr_cli \
        "$cli_options" \
        "$fzf_query" \
        "$fzf_preview_command"

    return $status
end

function fci_plugin_gh_fzf \
    --description "The plugin of fish-completion-interceptor to run gh"

    # $argv[1]: gh
    # $argv[2]: subcommand
    set -l subcommand $argv[2]

    switch $subcommand
        case pr
            argparse --ignore-unknown 'R/repo=' -- $argv
            # Get a last command line argument as a query
            set -l query $argv[-1]
            __fci_plugin_gh_fzf_pr_list "$_flag_repo" "$query"
            return $status
    end

    return 0
end
