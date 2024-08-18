set __FCI_PLUGIN_GH_FZF_GH_CLI mock_gh
set __FCI_PLUGIN_GH_FZF_DEFAULT_ORG test-org
set FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_gh_test
    __fci_plugin_run_test \
        --plugin-function=fci_plugin_gh_fzf \
        $argv
end

function run_test_cases
    function pr_run_successful_test_cases
        set -l mock_repo org/repo

        set option \
            "--prompt=Your PRs> " \
            "--header=Ctrl-S: Show your PRs. Ctrl-R: Show other PRs you are requested to be reviewed"
        set bind_option \
            "--bind=ctrl-s:change-prompt(Your PRs> )+reload(mock_gh pr list --search 'state:open author:@me' )" \
            "--bind=ctrl-r:change-prompt(Other PRs> )+reload(mock_gh pr list --search 'state:open review:required review-requested:@me' )"

        run_gh_test \
            --description "gh pr view with an argument" \
            --command "gh pr view 1" \
            --expected-fzf-option "$option --preview=gh pr view {1} --query=1 $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
            --mock-fzf-stdout "12    PR TITLE 12 branch12" \
            --expected-stdout "12"
        run_gh_test \
            --description "gh pr view with a R option" \
            --command "gh pr -R $mock_repo " \
            --expected-fzf-option "$option --preview=gh pr view {1} --repo=$mock_repo $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
            --mock-fzf-stdout "12    PR TITLE 12 branch12" \
            --expected-stdout "12"
        run_gh_test \
            --description "gh pr view with a repo option" \
            --command "gh pr view --repo $mock_repo 12" \
            --expected-fzf-option "$option --preview=gh pr view {1} --repo=$mock_repo --query=12 $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
            --mock-fzf-stdout "12    PR TITLE 12 branch12" \
            --expected-stdout "12"
        run_gh_test \
            --description "gh pr diff with a repo option" \
            --command "gh pr diff --repo $mock_repo " \
            --expected-fzf-option "$option --preview=gh pr view {1} --repo=$mock_repo $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
            --mock-fzf-stdout "12    PR TITLE 12 branch12" \
            --expected-stdout "12"
    end

    function pr_run_error_test_cases
        run_gh_test \
            --description="fzf was canceled" \
            --command "gh pr view " \
            --mock-fzf-status 130 \
            --expected-status 130
    end

    @echo == gh pr: Supported commands
    pr_run_successful_test_cases

    @echo == gh pr: Error cases
    pr_run_error_test_cases

    function repo_run_successful_test_cases
        set -l mock_repo org/repo

        set option \
            "--header=Type \$ORGANIZATION/\$REPOSITORY format as a query and search repositories under the \$ORGANIZATION"
        set command "$__FCI_PLUGIN_GH_FZF_GH_CLI search repos --owner (echo {q} | cut -f 1 -d '/') (echo {q} | cut -f 2- -d '/')"
        set bind_option \
            "--bind=start:reload($command)" \
            "--bind=change:reload($command)"

        set -l mock_fzf_stdout "org/repo    description    public    about 4 days ago"
        set -l expected_stdout "org/repo"
        run_gh_test \
            --description "gh repo view without an argument" \
            --command "gh repo view " \
            --expected-fzf-option "$option --preview=gh repo view {1} --query=$__FCI_PLUGIN_GH_FZF_DEFAULT_ORG/ $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
            --mock-fzf-stdout $mock_fzf_stdout \
            --expected-stdout $expected_stdout
        run_gh_test \
            --description "gh repo view with an option" \
            --command "gh repo view -b branch" \
            --expected-fzf-option "$option --preview=gh repo view {1} --query=$__FCI_PLUGIN_GH_FZF_DEFAULT_ORG/branch $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
            --mock-fzf-stdout $mock_fzf_stdout \
            --expected-stdout $expected_stdout
        run_gh_test \
            --description "gh repo view with an organization arg" \
            --command "gh repo view org/r" \
            --expected-fzf-option "$option --preview=gh repo view {1} --query=org/r $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
            --mock-fzf-stdout $mock_fzf_stdout \
            --expected-stdout $expected_stdout
        run_gh_test \
            --description "gh repo view with a full repository" \
            --command "gh repo view org/repo" \
            --expected-fzf-option "$option --preview=gh repo view {1} --query=org/repo $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
            --mock-fzf-stdout $mock_fzf_stdout \
            --expected-stdout $expected_stdout
    end

    function repo_run_error_test_cases
        run_gh_test \
            --description="fzf was canceled" \
            --command "gh repo view test/" \
            --mock-fzf-status 130 \
            --expected-status 130
    end

    @echo == gh repo: Supported commands
    repo_run_successful_test_cases

    @echo == gh repo: Error cases
    repo_run_error_test_cases
end

run_test_cases
