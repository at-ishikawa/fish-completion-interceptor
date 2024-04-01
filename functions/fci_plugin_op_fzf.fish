__fci_functions

function __fci_plugin_1password_cli \
    --argument-names group
    argparse "account=?" "vault=?" -- $argv

    set -l cli_options
    if [ -n "$_flag_account" ]
        set -a cli_options "--account=$_flag_account"
    end
    if [ -n "$_flag_vault" ]
        set -a cli_options "--vault=$_flag_vault"
    end
    set -a cli_options --format=json

    set -l jq_expression "[.id, .title]"
    set -l jq_header '["id", "title"]'
    if [ "$group" = vault ]; or [ "$group" = vaults ]
        set jq_expression "[.id, .name]"
        set jq_header '["id", "name"]'
    end

    set -l result ($__FCI_PLUGIN_1PASSWORD_FZF_1PASSWORD_CLI $group list $cli_options 2>| read -z stderr_output | jq -r "$jq_header, (.[] | $jq_expression) | @tsv")
    set -l cli_status $pipestatus[1]
    if [ $cli_status -ne 0 ]
        echo -n -e "$stderr_output" >&2
        return $cli_status
    end
    if [ -z "$result" ]
        return 1
    end

    string split "\n" -- $result
    return 0
end


function __fci_plugin_1password_fzf_list \
    --argument-names group
    argparse "account=?" "vault=?" "query=?" -- $argv; or return 1

    set -l account "$_flag_account"
    set -l vault "$_flag_vault"
    set -l fzf_query "$_flag_query"
    set -l fzf_preview_command "op $group get {1}"
    if [ -n "$account" ]
        set fzf_preview_command "$fzf_preview_command --account=$account"
    end
    if [ -n "$vault" ]
        set fzf_preview_command "$fzf_preview_command --vault=$vault"
    end

    # __fci_plugin_1password_cli $group list $cli_options | __fci_fzf $fzf_options | cut -f 2- -d ' ' | string trim | awk '{ printf "\"%s\"\n", $0 }'
    set -l selections (__fci_plugin_1password_cli "$group" "--vault=$vault" "--account=$account" |
        __fci_fzf "--header-lines=1" "--preview=$fzf_preview_command" "--query=$fzf_query")
    for st in $pipestatus
        if [ $st -ne 0 ]
            return $st
        end
    end

    string split "\n" -- $selections | cut -f 2- | string trim | awk '{ printf "\"%s\"\n", $0 }'
    return 0
end

function fci_plugin_op_fzf \
    --description "The plugin of fish-completion-interceptor to run 1password cli"

    # Only support some commands
    if [ (count $argv) -le 3 ]
        return 0
    end

    argparse --ignore-unknown "account=?" -- $argv
    # $argv[1]: op
    # $argv[2]: group
    set -l group $argv[2]

    switch "$group"
        case vault vaults item items
            argparse --ignore-unknown "vault=?" -- $argv
            set -l query $argv[-1]

            __fci_plugin_1password_fzf_list \
                "$group" \
                "--query=$query" \
                "--account=$_flag_account" \
                "--vault=$_flag_vault"
            return $status
    end
    return 0
end
