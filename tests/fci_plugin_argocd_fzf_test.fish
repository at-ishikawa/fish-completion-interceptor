set __FCI_PLUGIN_ARGOCD_FZF_ARGOCD_CLI mock_argocd
set FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_argocd_test
    __fci_plugin_run_test \
        --plugin-function=fci_plugin_argocd_fzf \
        $argv
end

function run_app_get_test_cases
    @echo ArgoCD app get supported commands

    run_argocd_test \
        --description "argocd app get without an argument" \
        --command "argocd app get " \
        --expected-fzf-default-command "mock_argocd app list" \
        --expected-fzf-option "--header-lines=1 --preview=mock_argocd app get {1} $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "my-app" \
        --expected-stdout "my-app"
    run_argocd_test \
        --description "argocd app get with a query" \
        --command "argocd app get my-" \
        --expected-fzf-default-command "mock_argocd app list" \
        --expected-fzf-option "--header-lines=1 --preview=mock_argocd app get {1} --query=my- $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "my-app" \
        --expected-stdout "my-app"
    run_argocd_test \
        --description "argocd app get with context" \
        --command "argocd --context prod app get " \
        --expected-fzf-default-command "mock_argocd app list --context=prod" \
        --expected-fzf-option "--header-lines=1 --preview=mock_argocd app get {1} --context=prod $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "my-app" \
        --expected-stdout "my-app"

    @echo Error cases
    run_argocd_test \
        --description "fzf was canceled" \
        --command "argocd app get my-" \
        --mock-fzf-status 130 \
        --expected-status 130
end

function run_login_test_cases
    @echo ArgoCD login supported commands

    # argocd context output: CURRENT  NAME  SERVER
    # login extracts column 3 (SERVER)
    run_argocd_test \
        --description "argocd login without an argument" \
        --command "argocd login " \
        --expected-fzf-default-command "mock_argocd context" \
        --expected-fzf-option "--header-lines=1 $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "*\tprod-context\thttps://argocd.example.com" \
        --expected-stdout "https://argocd.example.com"
    run_argocd_test \
        --description "argocd login with a query" \
        --command "argocd login prod" \
        --expected-fzf-default-command "mock_argocd context" \
        --expected-fzf-option "--header-lines=1 --query=prod $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "*\tprod-context\thttps://argocd.example.com" \
        --expected-stdout "https://argocd.example.com"

    @echo Error cases
    run_argocd_test \
        --description "fzf was canceled" \
        --command "argocd login prod" \
        --mock-fzf-status 130 \
        --expected-status 130
end

function run_context_mode_test_cases
    @echo ArgoCD context mode

    # argocd context output: CURRENT  NAME  SERVER
    # context mode extracts column 2 (NAME)
    run_argocd_test \
        --description "argocd app get --context suggests contexts" \
        --command "argocd app get --context " \
        --expected-fzf-default-command "mock_argocd context" \
        --expected-fzf-option "--header-lines=1 $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "*\tprod\thttps://argocd.example.com" \
        --expected-stdout "prod"
    run_argocd_test \
        --description "argocd app get --context with partial query" \
        --command "argocd app get --context pro" \
        --expected-fzf-default-command "mock_argocd context" \
        --expected-fzf-option "--header-lines=1 --query=pro $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "*\tprod\thttps://argocd.example.com" \
        --expected-stdout "prod"
    run_argocd_test \
        --description "argocd --context= with equals syntax" \
        --command "argocd app get --context=pro" \
        --expected-fzf-default-command "mock_argocd context" \
        --expected-fzf-option "--header-lines=1 --query=pro $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "*\tprod\thttps://argocd.example.com" \
        --expected-stdout "prod"
end

function run_unsupported_command_test_cases
    @echo Unsupported commands fall through

    run_argocd_test \
        --description "argocd without subcommand" \
        --command "argocd " \
        --expected-stdout ""
    run_argocd_test \
        --description "argocd app without sub-subcommand" \
        --command "argocd app " \
        --expected-stdout ""
    run_argocd_test \
        --description "argocd app sync is unsupported" \
        --command "argocd app sync " \
        --expected-stdout ""
end

run_app_get_test_cases
run_login_test_cases
run_context_mode_test_cases
run_unsupported_command_test_cases
