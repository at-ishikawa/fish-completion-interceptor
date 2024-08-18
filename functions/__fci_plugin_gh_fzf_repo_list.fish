function __fci_plugin_gh_fzf_repo_list

    argparse "query=?" -- $argv

    if not string match -q "*/*" "$_flag_query"
        set _flag_query "$__FCI_PLUGIN_GH_FZF_DEFAULT_ORG/$_flag_query"
    end

    set -l fzf_preview_command "gh repo view {1}"

    # https://github.com/junegunn/fzf?tab=readme-ov-file#2-switch-between-sources-by-pressing-ctrl-d-or-ctrl-f
    # https://github.com/junegunn/fzf/issues/2423#issuecomment-814577418
    FZF_DEFAULT_COMMAND="$__FCI_PLUGIN_GH_FZF_GH_CLI search repos --owner (echo {q} | cut -f 1 -d '/') (echo {q} | cut -f 2- -d '/')" \
        __fci_fzf \
        "--bind=start:reload($FZF_DEFAULT_COMMAND)" \
        "--bind=change:reload($FZF_DEFAULT_COMMAND)" \
        "--header=Type \$ORGANIZATION/\$REPOSITORY format as a query and search repositories under the \$ORGANIZATION" \
        "--query=$_flag_query" \
        "--preview=$fzf_preview_command" |
        awk '{ print $1 }'
    return $pipestatus[1]
end
