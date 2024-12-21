set __FCI_PLUGIN_AWS_FZF_AWS_CLI mock_aws
set FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_aws_test
    __fci_plugin_run_test \
        --plugin-function=fci_plugin_aws_fzf \
        $argv
end

function run_supported_command_test_cases
    set -l mock_secret_list (jq -n '[{"Name": "secret-1", "Description": "description 1"},{ "Name": "secret-2", "Description": "description 2"}]')

    set -l expected_secretsmanager_query 'SecretList[*].{Name: Name,Description: Description, Tags: Tags}'
    set -l expected_jq_query '["Name", "Description", "Tags"], (.[] | [.Name, .Description, (.Tags | select(. != null) | map(.Key + "=" + .Value) | join(", "))]) | @tsv'
    # I don't know what is an expected response here
    # run_aws_test \
    #     --description "aws secretsmanager doesn't return anything" \
    #     --command "aws secretsmanager list-secrets" \
    #     --expected-aws-argv "secretsmanager list-secrets" \
    #     --mock-aws-stdout "[]" \
    #     --expected-status 1 \
    #     --expected-stdout ""
    run_aws_test \
        --description "aws secretsmanager get-secret-values without an argument. aws secretsmanager list-secrets returns a single row" \
        --command "aws secretsmanager get-secret-values " \
        --expected-fzf-default-command "mock_aws secretsmanager list-secrets --query='$expected_secretsmanager_query' | jq -r '$expected_jq_query' | column -t" \
        --expected-fzf-option "--multi --header-lines=1 $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "secret-1\tdescription 1\tkey1=val1" \
        --expected-stdout '--secret secret-1'
    run_aws_test \
        --description "aws secretsmanager with all options" \
        --command "aws --profile user1 --region us-west-1 secretsmanager get-secret-values val" \
        --expected-fzf-default-command "mock_aws secretsmanager list-secrets --profile=user1 --region=us-west-1 --query='$expected_secretsmanager_query' | jq -r '$expected_jq_query' | column -t" \
        --expected-fzf-option "--multi --header-lines=1 --query=val $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "secret-1\tdescription 1\tkey1=val1,key2=val2" \
        --expected-stdout '--secret secret-1'
end

function run_error_test_cases
    run_aws_test \
        --description "fzf was canceled" \
        --command "aws secretsmanager list-secrets val" \
        --mock-fzf-status 130 \
        --expected-status 130
end

@echo == Supported commands
run_supported_command_test_cases

@echo == Error cases
run_error_test_cases
