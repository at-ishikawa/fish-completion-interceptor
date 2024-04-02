set -g __FCI_PLUGIN_1PASSWORD_FZF_1PASSWORD_CLI mock_1password
set -g FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_1password_test \
    -a commandline_arg \
    -a expected_status \
    -a expected_stdout

    set -l commandline_args (string split " " $commandline_arg)

    set temp_file (mktemp)
    set -l actual_stdout (fci_plugin_op_fzf $commandline_args 2>$temp_file)
    set -l actual_status $status
    set -l actual_stderr (cat $temp_file)
    rm $temp_file

    # @echo "actual_stdout: $actual_stdout, expected_stdout: $expected_stdout"
    # @echo "actual_stderr: $actual_stderr, expected_stderr: $expected_stderr"
    @test status $actual_status -eq $expected_status
    @test stdout "$actual_stdout" = "$expected_stdout"
    @test stderr -z "$actual_stderr"
end

function run_supported_command_test_cases
    set -l test_descriptions \
        "op items list doesn't return anything" \
        "op vaults list returns a single row with a fzf query" \
        "op vaults list returns multiple rows without a fzf query" \
        "op items list with account and vault options"

    set -l test_cases \
        "op item list " \
        "op vaults get 2nd" \
        "op --account=example vault get " \
        "op --account=example items get --vault=vault 4th"

    set -l vault_json_1 '{"id":"vault11","name":"Vault 11"}'
    set -l vault_json_2 '{"id": "vault12", "name":"Vault 12"}'
    set -l item_json_1 "{\"id\": \"abc11\", \"title\":\"Item 11\",\"vault\":$vault_json_1}"
    set -l item_json_2 "{\"id\": \"abc12\", \"title\":\"Item 12\",\"vault\":$vault_json_2}"
    set -g mock_1password_results \
        "" \
        "[$item_json_1]" \
        "[$vault_json_1, $vault_json_2]" \
        "[$item_json_1, $item_json_2]"
    set -l expected_1password_commands \
        "item list --format=json" \
        "vaults list --format=json" \
        "vault list --account=example --format=json" \
        "items list --account=example --vault=vault --format=json"

    set -l mock_fzf_results \
        "fzf result doesn't matter" \
        "abc11\tItem 11" \
        "vault11\tVault 11\nvault12\tVault 12" \
        "abc11\tItem 11\nabc12\tItem 12"
    set -l expected_fzf_options \
        "--header-lines=1 --preview=op item get {1} $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "--header-lines=1 --preview=op vaults get {1} --query=2nd $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "--header-lines=1 --preview=op vault get {1} --account=example $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "--header-lines=1 --preview=op items get {1} --account=example --vault=vault --query=4th $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS"

    set -l expected_statuses \
        1 \
        0 \
        0 \
        0
    set -l expected_stdouts \
        "" \
        '"Item 11"' \
        '"Vault 11"\n"Vault 12"' \
        '"Item 11"\n"Item 12"'

    for test_case_index in (seq 1 (count $test_cases))
        # global option is somehow required
        set -g expected_1password_command $expected_1password_commands[$test_case_index]
        set -g mock_1password_result $mock_1password_results[$test_case_index]

        function mock_1password
            if [ "$argv" != "$expected_1password_command" ]
                echo "op argv: (expected: $expected_1password_command, actual: $argv)" >&2
                return 255
            end

            echo -e "$mock_1password_result"
            return 0
        end

        set -g expected_fzf_option $expected_fzf_options[$test_case_index]
        set -g mock_fzf_result $mock_fzf_results[$test_case_index]
        function mock_fzf
            if [ "$expected_fzf_option" != "$argv" ]
                echo "fzf options: (expected $expected_fzf_option, actual: $argv)" >&2
                return 255
            end

            echo -e "$mock_fzf_result"
            return 0
        end

        set -l test_case $test_cases[$test_case_index]
        set -l expected_status $expected_statuses[$test_case_index]
        set -l expected_stdout (echo -e "$expected_stdouts[$test_case_index]")

        @echo "Supported command: $test_case_index: $test_descriptions[$test_case_index]"
        run_1password_test "$test_case" $expected_status "$expected_stdout"
    end
end

function run_error_test_cases
    set -l test_descriptions \
        "op login is required" \
        "fzf causes errors"

    set -l test_cases \
        "op item list " \
        "op vaults get 2nd"

    set -l vault_json_1 '{"id":"vault11","name":"Vault 11"}'
    set -l vault_json_2 '{"id": "vault12", "name":"Vault 12"}'
    set -l item_json_1 "{\"id\": \"abc11\", \"title\":\"Item 11\",\"vault\":$vault_json_1}"
    set -l item_json_2 "{\"id\": \"abc12\", \"title\":\"Item 12\",\"vault\":$vault_json_2}"
    set -g mock_1password_results \
        "[ERROR] 2024/04/01 21:22:29 You are not currently signed in. Please run `op signin --help` for instructions" \
        "[$vault_json_1, $vault_json_2]"
    set -g mock_1password_statuses \
        1 \
        0

    set -l mock_fzf_results \
        "fzf result doesn't matter" \
        ""
    set -l mock_fzf_statuses \
        0 \
        130

    set -l expected_statuses \
        1 \
        130
    set -l expected_stdouts \
        "[ERROR] 2024/04/01 21:22:29 You are not currently signed in. Please run `op signin --help` for instructions" \
        ''

    for test_case_index in (seq 1 (count $test_cases))
        # global option is somehow required
        set -g mock_1password_result $mock_1password_results[$test_case_index]
        set -g mock_1password_status $mock_1password_statuses[$test_case_index]
        function mock_1password
            if [ $mock_1password_status -ne 0 ]
                echo -e "$mock_1password_result" >&2
            else
                echo -e "$mock_1password_result" >&1
            end
            return $mock_1password_status
        end

        set -g mock_fzf_result $mock_fzf_results[$test_case_index]
        set -g mock_fzf_status $mock_fzf_statuses[$test_case_index]
        function mock_fzf
            if [ $mock_fzf_status -ne 0 ]
                echo -e "$mock_fzf_result" >&2
            else
                echo -e "$mock_fzf_result" >&1
            end
            echo -e "$mock_fzf_result"
            return $mock_fzf_status
        end

        set -l test_case $test_cases[$test_case_index]
        set -l expected_status $expected_statuses[$test_case_index]
        set -l expected_stdout (echo -e "$expected_stdouts[$test_case_index]")

        @echo "Error cases: $test_case_index: $test_descriptions[$test_case_index]"
        run_1password_test "$test_case" $expected_status "$expected_stdout"
    end
end

@echo == Supported commands
run_supported_command_test_cases
@echo == Error cases
run_error_test_cases
