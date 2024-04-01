set -g __FCI_PLUGIN_1PASSWORD_FZF_1PASSWORD_CLI mock_1password
set -g FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_1password_test \
    -a commandline_arg \
    -a expected_status \
    -a expected_stdout \
    -a expected_stderr

    set -l commandline_args (string split " " $commandline_arg)

    set temp_file (mktemp)
    set -l actual_stdout (fci_plugin_op_fzf $commandline_args 2>$temp_file)
    set -l actual_status $status
    set -l actual_stderr (cat $temp_file)
    rm $temp_file

    @echo "actual_stdout: $actual_stdout, expected_stdout: $expected_stdout"
    @test status $actual_status -eq $expected_status
    @test stdout "$actual_stdout" = "$expected_stdout"
    @test stderr "$actual_stderr" = "$expected_stderr"
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

    set -g mock_1password_results \
        "" \
        "ID TITLE VAULT\nabc11 Item11 Vault1" \
        "ID NAME\nvault11 Vault 11\nvault12 Vault 12" \
        "ID TITLE VAULT\nabc11 Item11 vault\nabc12 Item12 vault"
    set -l expected_1password_commands \
        "item list" \
        "vaults list" \
        "vault list --account=example" \
        "items list --account=example --vault=vault"

    set -l mock_fzf_results \
        "fzf shouldn't be used" \
        "abc11 Item11 Vault1" \
        "vault11 Vault11\nvault12 Vault12" \
        "abc11 Item11 vault\nabc12 Item12 vault"
    set -l expected_fzf_options \
        "fzf shouldn't be used" \
        "--multi --header-lines=1 --preview=op vaults get {1} --query=2nd $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "--multi --header-lines=1 --preview=op vault get {1} --account=example $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "--multi --header-lines=1 --preview=op items get {1} --account=example --vault=vault --query=4th $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS"

    set -l expected_statuses \
        0 \
        0 \
        0 \
        0
    set -l expected_stdouts \
        "" \
        abc11 \
        "vault11\nvault12" \
        "abc11\nabc12"
    set -l expected_stderrs \
        "" \
        "" \
        "" \
        ""

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
        set -l expected_stderr $expected_stderrs[$test_case_index]

        @echo "Supported command: $test_case_index: $test_descriptions[$test_case_index]"
        run_1password_test "$test_case" $expected_status "$expected_stdout" "$expected_stderr"
    end
end

@echo == Supported commands
run_supported_command_test_cases
