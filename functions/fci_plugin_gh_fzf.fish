function __fci_plugin_gh_fzf_run_gh
    $__FCI_PLUGIN_GHL_FZF_GH_CLI pr list
    return $status
end

function __fci_plugin_gh_fzf_pr_list -d "The list of PRs" \
    -a repository \
    -a fzf_query

    set -l cli_options
    if [ -n "$repository" ]
        set cli_options $cli_options --repo=$repository
    end

    set -l candidates ($__FCI_PLUGIN_GH_FZF_GH_CLI pr list $cli_options 2>&1)
    set -l cli_status $status
    if [ $cli_status -ne 0 ]
        echo -n -e "$candidates" >&2
        return $cli_status
    end
    if [ -z "$candidates" ]
        # echo "There are no open pull requests"
        return 1
    end

    # `echo -e "$candidates" | wc -l` doesn't when multiple lines are assigned to a variable
    set -l candidate_count (string split0 $candidates | wc -l)
    set -l result "$candidates"

    # Show fzf if
    # 1. there are multiple candidates, or
    # 2. there is a string on a command line
    if [ -n "$fzf_query" ]; or [ $candidate_count -ge 2 ]
        set -l preview_command "gh pr view {1}"
        if [ -n $repository ]
            set -a preview_command "--repo=$repository"
        end

        set -l fzf_options $FCI_PLUGIN_GH_FZF_FZF_OPTION "--preview=$preview_command"
        if [ -n "$fzf_query" ]
            set fzf_options $fzf_options "--query=$fzf_query"
        end

        set -l fzf_result (string split0 "$candidates" | $__FCI_PLUGIN_GH_FZF_FZF_CLI $fzf_options)
        set -l fzf_status $status
        if [ $fzf_status -ne 0 ]
            echo -n -e "$fzf_result" >&2
            return $fzf_status
        end
        if [ -z "$fzf_result" ]
            return $fzf_status
        end

        set result $fzf_result
    end

    set result (echo -e "$result" | awk '{ print $1 }' | string trim)
    echo $result
    return 0
end

function fci_plugin_gh_fzf -d "The plugin of fish-completion-interceptor to run gh"
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
