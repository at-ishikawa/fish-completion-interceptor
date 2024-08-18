__fci_functions

function fci_plugin_ghq_fzf --description "The plugin for ghq"

    # Use gh cli for this plugin to get the list of GitHub repositories
    if ! type -q gh
        return 0
    end

    # $argv[1]: ghq
    # $argv[2]: subcommand
    set -l subcommand $argv[2]

    switch $subcommand
    case get
        argparse --ignore-unknown -- $argv
        set -l query $argv[-1]
        __fci_plugin_gh_fzf_repo_list "--query=$query"
        return $status
    end

    return 0
end
