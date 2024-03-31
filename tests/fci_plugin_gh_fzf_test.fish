set __FCI_PLUGIN_GH_FZF_GH_CLI mock_gh
set FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_gh_test \
    -a commandline_arg \
    -a expected_status \
    -a expected_stdout \
    -a expected_stderr
    set -l commandline_args (string split " " $commandline_arg)

    set -l actual_stdout (fci_plugin_gh_fzf $commandline_args 2>/dev/null)
    set -l actual_stderr (fci_plugin_gh_fzf $commandline_args 2>&1)
    set -l actual_status $status
    set -l actual_stderr (string replace "$actual_stdout" "" "$actual_stderr")

    @test "command status" $actual_status -eq $expected_status
    @test "command stdout" "$actual_stdout" = "$expected_stdout"
    @test "command stderr" "$actual_stderr" = "$expected_stderr"
end

function run_successful_test_cases
    set -l mock_repo org/repo

    set -l test_descriptions \
        "gh pr list doesn't return anything" \
        "gh pr view without an argument. gh returns a single row" \
        "gh pr view with an argument. gh returns multiple row" \
        "gh pr view with a R option" \
        "gh pr view with a repo option" \
        "gh pr diff with a repo option"

    set -l test_cases \
        "gh pr view " \
        "gh pr view " \
        "gh pr view 1" \
        "gh pr view -R $mock_repo " \
        "gh pr view --repo $mock_repo 12" \
        "gh pr diff --repo $mock_repo "

    set -g mock_gh_results \
        "" \
        "12    PR TITLE 12 branch12" \
        "12    PR TITLE 12 branch12\n11    PR TITLE 11 branch11" \
        "13    PR TITLE 13 branch13\n12    PR TITLE 12 branch12" \
        "13    PR TITLE 13 branch13\n12    PR TITLE 12 branch12" \
        "13    PR TITLE 13 branch13\n12    PR TITLE 12 branch12"

    set -l expected_gh_commands \
        "pr list" \
        "pr list" \
        "pr list" \
        "pr list --repo=$mock_repo" \
        "pr list --repo=$mock_repo" \
        "pr list --repo=$mock_repo"

    set -l expected_fzf_options \
        "fzf shouldn't be used" \
        "fzf shouldn't be used" \
        "--preview=gh pr view {1} --query=1 $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "--preview=gh pr view {1} --repo=$mock_repo $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "--preview=gh pr view {1} --repo=$mock_repo --query=12 $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "--preview=gh pr view {1} --repo=$mock_repo $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS"

    set -l expected_stdouts \
        "" \
        12 \
        12 \
        12 \
        12 \
        12 \
        12

    for test_case_index in (seq 1 (count $test_cases))
        # global option is somehow required
        set -g expected_gh_command $expected_gh_commands[$test_case_index]
        set -g mock_gh_result $mock_gh_results[$test_case_index]

        function mock_gh
            if [ "$argv" != "$expected_gh_command" ]
                echo "gh argv: (expected: $expected_gh_command, actual: $argv)" >&2
                return 255
            end

            echo -e "$mock_gh_result"
            return 0
        end

        set -g expected_fzf_option $expected_fzf_options[$test_case_index]
        function mock_fzf
            if [ "$expected_fzf_option" != "$argv" ]
                echo "fzf options: (expected $expected_fzf_option, actual: $argv)" >&2
                return 255
            end

            echo "12    PR TITLE 12 branch12"
            return 0
        end

        set -l test_case $test_cases[$test_case_index]
        set -l expected_status 0
        set -l expected_stdout $expected_stdouts[$test_case_index]
        set -l expected_stderr ""

        @echo "Successful test case $test_case_index: $test_descriptions[$test_case_index]"
        run_gh_test $test_case $expected_status $expected_stdout $expected_stderr
    end
end

function run_error_test_cases
    set -l mock_repo org/repo

    set -l test_descriptions \
        "gh pr list returns an error" \
        "fzf was canceled"

    set -g mock_gh_command_results \
        "GraphQL: Could not resolve to a Repository with the name 'org/repo'. (repository)" \
        "13 PR TITLE 13 branch13\n12 PR TITLE 12 branch12"
    set -l mock_gh_command_statuses \
        1 \
        0
    set -g expected_gh_commands \
        "pr list" \
        "pr list"

    set -g mock_fzf_command_results \
        "isn't used" \
        ""
    set -g mock_fzf_command_statuses \
        0 \
        130

    set -l test_cases \
        "gh pr view " \
        "gh pr view "

    set -l expected_statuses \
        1 \
        130

    set -l expected_stdouts \
        "" \
        ""

    set -l expected_stderrs \
        "GraphQL: Could not resolve to a Repository with the name 'org/repo'. (repository)" \
        ""

    for test_case_index in (seq 1 (count $test_cases))
        functions -e mock_gh mock_fzf
        set -g expected_gh_command $expected_gh_commands[$test_case_index]

        set -g mock_gh_command_result $mock_gh_command_results[$test_case_index]
        set -g mock_gh_command_status $mock_gh_command_statuses[$test_case_index]
        function mock_gh
            if [ "$argv" != "$expected_gh_command" ]
                echo "gh argv: (expected: $expected_gh_command, actual: $argv)" >&2
                return 255
            end

            if [ $mock_gh_command_status -eq 0 ]
                echo -e "$mock_gh_command_result"
                return 0
            end
            echo -e "$mock_gh_command_result" >&2
            return $mock_gh_command_status
        end

        set -g mock_fzf_command_result $mock_fzf_command_results[$test_case_index]
        set -g mock_fzf_command_status $mock_fzf_command_statuses[$test_case_index]
        function mock_fzf
            if [ $mock_fzf_command_status -eq 0 ]
                echo -e "$mock_fzf_command_result"
                return 0
            end

            echo -e "$mock_fzf_command_result" >&2
            return $mock_fzf_command_status
        end

        set -l test_case $test_cases[$test_case_index]
        set -l expected_status $expected_statuses[$test_case_index]
        set -l expected_stdout $expected_stdouts[$test_case_index]
        set -l expected_stderr $expected_stderrs[$test_case_index]

        @echo "Error test case $test_case_index: $test_descriptions[$test_case_index]"
        run_gh_test $test_case $expected_status $expected_stdout $expected_stderr
    end

end

@echo == Supported commands
run_successful_test_cases

@echo == Error cases
run_error_test_cases
