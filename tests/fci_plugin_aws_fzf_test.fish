set __FCI_PLUGIN_AWS_FZF_AWS_CLI mock_aws
set FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_aws_test
    __fci_plugin_run_test \
        --plugin-function=fci_plugin_aws_fzf \
        $argv
end

function run_ec2_describe_instances_test_cases
    @echo EC2 instances supported commands

    set -l mock_ec2_describe_instances (jq -n '[{"InstanceId": "i-1", "Name": "instance-1", "PublicIpAddress": "", "PrivateIpAddress": ""},{"InstanceId": "i-2", "Name": "instance-2", "PublicIpAddress": "", "PrivateIpAddress": ""}]')

    run_aws_test \
        --description "aws ec2 describe-instances without an argument" \
        --command "aws ec2 describe-instances " \
        --expected-fzf-default-command "mock_aws ec2 describe-instances --query='Reservations[*].Instances[*].{InstanceId: InstanceId, Name: Tags[?Key == `Name`].Value | [0], PublicIpAddress: PublicIpAddress, PrivateIpAddress: PrivateIpAddress}[]' | jq -r '[\"InstanceId\", \"Name\", \"PublicIpAddress\", \"PrivateIpAddress\"], (.[] | [.InstanceId, .Name, .PublicIpAddress, .PrivateIpAddress]) | @csv' | tr -d '\"' | column -t -s ','" \
        --expected-fzf-option "--multi --header-lines=1 $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "i-1\tinstance-1\t\t" \
        --expected-stdout '--instance-ids i-1'
    run_aws_test \
        --description "aws ec2 describe-instances with an argument" \
        --command "aws --profile user1 --region us-east-1 ec2 describe-instances val" \
        --expected-fzf-default-command "mock_aws ec2 describe-instances --profile=user1 --region=us-east-1 --query='Reservations[*].Instances[*].{InstanceId: InstanceId, Name: Tags[?Key == `Name`].Value | [0], PublicIpAddress: PublicIpAddress, PrivateIpAddress: PrivateIpAddress}[]' | jq -r '[\"InstanceId\", \"Name\", \"PublicIpAddress\", \"PrivateIpAddress\"], (.[] | [.InstanceId, .Name, .PublicIpAddress, .PrivateIpAddress]) | @csv' | tr -d '\"' | column -t -s ','" \
        --expected-fzf-option "--multi --header-lines=1 --query=val $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "i-1\tinstance-1\t\t\ni-2\tinstance-2\t\t" \
        --expected-stdout '--instance-ids i-1 i-2'

    @echo Error cases
    run_aws_test \
        --description "fzf was canceled" \
        --command "aws ec2 describe-instances val" \
        --mock-fzf-status 130 \
        --expected-status 130
end

function run_secrets_manager_test_cases
    @echo Secrets Manager cases
    @echo Supported commands cases
    set -l mock_secret_list (jq -n '[{"Name": "secret-1", "Description": "description 1"},{ "Name": "secret-2", "Description": "description 2"}]')

    set -l expected_secretsmanager_query 'SecretList[*].{Name: Name,Description: Description, Tags: Tags}'
    set -l expected_jq_query '["Name", "Description", "Tags"], (.[] | [.Name, .Description, (.Tags | select(. != null) | map(.Key + "=" + .Value) | join(", "))]) | @csv'
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
        --expected-fzf-default-command "mock_aws secretsmanager list-secrets --query='$expected_secretsmanager_query' | jq -r '$expected_jq_query' | tr -d '\"' | column -t -s ','" \
        --expected-fzf-option "--header-lines=1 $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "secret-1\tdescription 1\tkey1=val1" \
        --expected-stdout '--secret secret-1'
    run_aws_test \
        --description "aws secretsmanager with all options" \
        --command "aws --profile user1 --region us-west-1 secretsmanager get-secret-values val" \
        --expected-fzf-default-command "mock_aws secretsmanager list-secrets --profile=user1 --region=us-west-1 --query='$expected_secretsmanager_query' | jq -r '$expected_jq_query' | tr -d '\"' | column -t -s ','" \
        --expected-fzf-option "--header-lines=1 --query=val $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "secret-1\tdescription 1\tkey1=val1,key2=val2" \
        --expected-stdout '--secret secret-1'

    @echo Error cases
    run_aws_test \
        --description "fzf was canceled" \
        --command "aws secretsmanager list-secrets val" \
        --mock-fzf-status 130 \
        --expected-status 130
end

run_ec2_describe_instances_test_cases
run_secrets_manager_test_cases
