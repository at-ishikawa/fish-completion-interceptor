__fci_functions

function __fci_plugin_aws_fzf_secretsmanager \
    --argument-names groups

    argparse "fzf-query=?" \
        "profile=?" \
        "region=?" \
        "aws-query=" \
        "jq-query=" \
        "output-prefix=" \
        -- $argv; or return 1

    set -l aws_query $_flag_aws_query
    set -l jq_query $_flag_jq_query

    set -l fzf_options --multi \
        --query=$_flag_fzf_query \
        --header-lines=1

    set -l aws_options
    if [ -n "$_flag_profile" ]
        set -a aws_options "--profile=$_flag_profile"
    end
    if [ -n "$_flag_region" ]
        set -a aws_options "--region=$_flag_region"
    end
    if [ -n "$aws_query" ]
        set -a aws_options "--query=$aws_query"
    end

    FZF_DEFAULT_COMMAND="$__FCI_PLUGIN_AWS_FZF_AWS_CLI $groups $aws_options | jq -r '$jq_query' | column -t" \
        __fci_fzf $fzf_options |
        awk '{ print $1 }' |
        string trim |
        read -l -d '' selected
    set -l result_status $pipestatus[1]
    if [ $result_status -ne 0 ]
        return $result_status
    end

    echo "$_flag_output_prefix $selected"
    return $result_status
end


function fci_plugin_aws_fzf \
    --description "The plugin for aws CLI"

    argparse --ignore-unknown \
        'profile=' \
        'region=' \
        -- $argv

    # only support sub commands
    if [ (count $argv) -le 3 ]
        return 0
    end
    # $argv[1]: aws
    # $argv[2]: group
    # $argv[3]: command
    # $argv[4]: arguments
    set -l group $argv[2]

    switch "$group"
        case secretsmanager
            set -l fzf_query $argv[-1]

            # Use query = 'SecretList[*].[Name,ARN,Description]'
            __fci_plugin_aws_fzf_secretsmanager \
                "$group list-secrets" \
                --fzf-query="$fzf_query" \
                --profile=$_flag_profile \
                --region=$_flag_region \
                --aws-query="'SecretList[*].{Name: Name,Description: Description, Tags: Tags}'" \
                --jq-query='["Name", "Description", "Tags"], (.[] | [.Name, .Description, (.Tags | select(. != null) | map(.Key + "=" + .Value) | join(", "))]) | @tsv' \
                --output-prefix='--secret'
    end
end
