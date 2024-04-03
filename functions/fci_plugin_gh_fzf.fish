__fci_functions

function __fci_plugin_gh_fzf_pr_list

    argparse "repo=?" "query=?" -- $argv
    set -l fzf_preview_command "gh pr view {1}"
    set -l cli_options
    if [ -n $_flag_repo ]
        set a cli_options "--repo=$_flag_repo"
        set -a fzf_preview_command "--repo=$_flag_repo"
    end

    # https://github.com/junegunn/fzf?tab=readme-ov-file#2-switch-between-sources-by-pressing-ctrl-d-or-ctrl-f
    # https://github.com/junegunn/fzf/issues/2423#issuecomment-814577418
    FZF_DEFAULT_COMMAND="$__FCI_PLUGIN_GH_FZF_GH_CLI pr list --search 'state:open author:@me' $cli_options" \
        __fci_fzf \
        "--prompt=Your PRs> " \
        "--bind=ctrl-s:change-prompt(Your PRs> )+reload($FZF_DEFAULT_COMMAND)" \
        "--bind=ctrl-r:change-prompt(Other PRs> )+reload($__FCI_PLUGIN_GH_FZF_GH_CLI pr list --search 'state:open review:required review-requested:@me' $clip_options)" \
        "--header=Ctrl-S: Show your PRs. Ctrl-R: Show other PRs you are requested to be reviewed" \
        "--query=$_flag_query" \
        "--preview=$fzf_preview_command" |
        awk '{ print $1 }'
    return $pipestatus[1]
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
