function __fci_plugin_1password_fzf_1password_cli
    set -l args (string trim -- $argv | string split " " | string trim)
    $__FCI_PLUGIN_1PASSWORD_FZF_1PASSWORD_CLI $args
end

function __fci_plugin_1password_fzf_list \
    -a group \
    account \
    vault \
    fzf_query

    set -l cli_options $group
    set -a cli_options list
    set -l fzf_preview_command "op $group get {1}"
    if [ -n "$account" ]
        set -a cli_options "--account=$account"
        set fzf_preview_command "$fzf_preview_command --account=$account"
    end
    if [ -n "$vault" ]
        set -a cli_options "--vault=$vault"
        set fzf_preview_command "$fzf_preview_command --vault=$vault"
    end

    # TODO: Filter by vault's names or items' titles instead of ids
    fci_run_fzf \
        __fci_plugin_1password_fzf_1password_cli \
        "$cli_options" \
        "$fzf_query" \
        "$fzf_preview_command" \
        1 \
        --multi
end

function fci_plugin_op_fzf \
    --description "The plugin of fish-completion-interceptor to run 1password cli"

    # Only support some commands
    if [ (count $argv) -le 3 ]
        return 0
    end

    argparse --ignore-unknown "account=?" -- $argv
    set -l account $_flag_account

    # $argv[1]: op
    # $argv[2]: group
    # $argv[3]: command
    set -l group $argv[2]

    switch "$group"
        case vault vaults item items
            argparse --ignore-unknown "vault=?" -- $argv

            set -l query $argv[-1]

            __fci_plugin_1password_fzf_list \
                "$group" \
                "$account" \
                "$_flag_vault" \
                "$query"
            return $status
    end

    return 0
end
