set __FCI_PLUGIN_GH_FZF_GH_CLI mock_gh
set FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_gh_test \
    -a commandline_arg \
    -a expected_status \
    -a expected_stdout
    set -l commandline_args (string split " " $commandline_arg)

    set -l actual_stdout (fci_plugin_gh_fzf $commandline_args 2>| read -z actual_stderr)
    set -l actual_status $pipestatus[1]

    @test "command status" $actual_status -eq $expected_status
    @test "command stdout" "$actual_stdout" = "$expected_stdout"
    @test "command stderr" -z "$actual_stderr"
end

function run_successful_test_cases
    set -l mock_repo org/repo

    set -l test_descriptions \
        "gh pr view with an argument" \
        "gh pr view with a R option" \
        "gh pr view with a repo option" \
        "gh pr diff with a repo option"

    set -l test_cases \
        "gh pr view 1" \
        "gh pr view -R $mock_repo " \
        "gh pr view --repo $mock_repo 12" \
        "gh pr diff --repo $mock_repo "

    set option \
        "--prompt=Your PRs> " \
        "--header=Ctrl-S: Show your PRs. Ctrl-R: Show other PRs you are requested to be reviewed"
    set bind_option \
        "--bind=ctrl-s:change-prompt(Your PRs> )+reload(mock_gh pr list --search 'state:open author:@me' )" \
        "--bind=ctrl-r:change-prompt(Other PRs> )+reload(mock_gh pr list --search 'state:open review:required review-requested:@me' )"

    set -l expected_fzf_options \
        "$option --preview=gh pr view {1} --query=1 $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "$option --preview=gh pr view {1} --repo=$mock_repo $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "$option --preview=gh pr view {1} --repo=$mock_repo --query=12 $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "$option --preview=gh pr view {1} --repo=$mock_repo $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS"

    set -l expected_stdouts \
        12 \
        12 \
        12 \
        12 \
        12

    for test_case_index in (seq 1 (count $test_cases))
        set expected_fzf_option $expected_fzf_options[$test_case_index]
        function mock_fzf --inherit-variable expected_fzf_option
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

        @echo "Successful test case $test_case_index: $test_descriptions[$test_case_index]"
        run_gh_test $test_case $expected_status $expected_stdout
    end
end

function run_error_test_cases
    function mock_fzf
        return 130
    end
    @echo === "Error test case fzf was canceled"
    run_gh_test "gh pr view " 130 ""
end

@echo == Supported commands
run_successful_test_cases

@echo == Error cases
run_error_test_cases
