set -g __FCI_PLUGIN_GHQ_FZF_GHQ_CLI mock_ghq
set FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf
set __FCI_PLUGIN_GH_FZF_GH_CLI mock_gh
set __FCI_PLUGIN_GH_FZF_DEFAULT_ORG mock_org

function run_ghq_test
    __fci_plugin_run_test \
        --plugin-function=fci_plugin_ghq_fzf \
        $argv
end

function run_supported_command_test_cases
    set option \
        "--header=Type \$ORGANIZATION/\$REPOSITORY format as a query and search repositories under the \$ORGANIZATION"
    set command "$__FCI_PLUGIN_GH_FZF_GH_CLI search repos --owner (echo {q} | cut -f 1 -d '/') (echo {q} | cut -f 2- -d '/')"
    set bind_option \
        "--bind=start:reload($command)" \
        "--bind=change:reload($command)"
    run_ghq_test \
        --description="ghq get without an organization argument" \
        --command "ghq get fish" \
        --expected-fzf-option "$option --preview=gh repo view {1} --query=$__FCI_PLUGIN_GH_FZF_DEFAULT_ORG/fish $bind_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "fish/fish fish shell" \
        --expected-stdout "fish/fish"
    run_ghq_test \
        --description="unsupported ghq subcommand" \
        --command "ghq list " \
        --expected-status 0
end

function run_error_test_cases
    run_ghq_test \
        --description="fzf was canceled" \
        --command "ghq get fish" \
        --mock-fzf-status 130 \
        --expected-status 130
end

@echo == Supported commands
run_supported_command_test_cases
@echo == Error cases
run_error_test_cases
