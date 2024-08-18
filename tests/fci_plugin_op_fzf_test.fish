set -g __FCI_PLUGIN_1PASSWORD_FZF_1PASSWORD_CLI mock_1password
set -g FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_1password_test
    argparse --ignore-unknown \
        "expected_1password_argv=" \
        "mock_1password_stdout=" \
        "mock_1password_stderr=" \
        "mock_1password_status=" \
        -- $argv

    function mock_1password \
        --inherit-variable _flag_expected_1password_argv \
        --inherit-variable _flag_mock_1password_stdout \
        --inherit-variable _flag_mock_1password_stderr \
        --inherit-variable _flag_mock_1password_status

        set -q _flag_mock_1password_status; or set _flag_mock_1password_status 0
        if test -n "$_flag_expected_1password_argv"; and [ "$argv" != "$_flag_expected_1password_argv" ]
            echo "op argv: (expected: $_flag_expected_1password_argv, actual: $argv)" >&2
            return 255
        end

        if [ $_flag_mock_1password_status -ne 0 ]
            echo -e "$_flag_mock_1password_stderr" >&2
            return $_flag_mock_1password_status
        end

        echo -e "$_flag_mock_1password_stdout"
        return $_flag_mock_1password_status
    end

    __fci_plugin_run_test \
        --plugin-function=fci_plugin_op_fzf \
        $argv
end

function run_supported_command_test_cases
    set -l vault_json_1 '{"id":"vault11","name":"Vault 11"}'
    set -l vault_json_2 '{"id": "vault12", "name":"Vault 12"}'
    set -l item_json_1 "{\"id\": \"abc11\", \"title\":\"Item 11\",\"vault\":$vault_json_1}"
    set -l item_json_2 "{\"id\": \"abc12\", \"title\":\"Item 12\",\"vault\":$vault_json_2}"

    run_1password_test \
        --description "op items list doesn't return anything" \
        --command "op item list " \
        --expected_1password_argv "item list --format=json" \
        --mock_1password_stdout "" \
        --expected-fzf-option "--header-lines=1 --preview=op item get {1} $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --expected-status 1
    run_1password_test \
        --description "op vaults list returns a single row with a fzf query" \
        --command "op vaults get 2nd" \
        --expected_1password_argv "vaults list --format=json" \
        --mock_1password_stdout "[$item_json_1]" \
        --mock-fzf-stdout "abc11\tItem 11" \
        --expected-fzf-option "--header-lines=1 --preview=op vaults get {1} --query=2nd $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --expected-stdout '"Item 11"'
    run_1password_test \
        --description "op vaults list returns multiple rows without a fzf query" \
        --command "op --account=example vault get " \
        --expected_1password_argv "vault list --account=example --format=json" \
        --mock_1password_stdout "[$vault_json_1, $vault_json_2]" \
        --mock-fzf-stdout "vault11\tVault 11\nvault12\tVault 12" \
        --expected-fzf-option "--header-lines=1 --preview=op vault get {1} --account=example $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --expected-stdout '"Vault 11" "Vault 12"'
    run_1password_test \
        --description "op vaults list returns multiple rows without a fzf query" \
        --command "op --account=example vault get " \
        --expected_1password_argv "vault list --account=example --format=json" \
        --mock_1password_stdout "[$vault_json_1, $vault_json_2]" \
        --mock-fzf-stdout "vault11\tVault 11\nvault12\tVault 12" \
        --expected-fzf-option "--header-lines=1 --preview=op vault get {1} --account=example $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --expected-stdout '"Vault 11" "Vault 12"'
    run_1password_test \
        --description "op items list with account and vault options" \
        --command "op --account=example items get --vault=vault 4th" \
        --expected_1password_argv "items list --account=example --vault=vault --format=json" \
        --mock_1password_stdout "[$item_json_1, $item_json_2]" \
        --mock-fzf-stdout "abc11\tItem 11\nabc12\tItem 12" \
        --expected-fzf-option "--header-lines=1 --preview=op items get {1} --account=example --vault=vault --query=4th $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --expected-stdout '"Item 11" "Item 12"'
end

function run_error_test_cases
    set -l vault_json_1 '{"id":"vault11","name":"Vault 11"}'
    set -l vault_json_2 '{"id": "vault12", "name":"Vault 12"}'
    set -l item_json_1 "{\"id\": \"abc11\", \"title\":\"Item 11\",\"vault\":$vault_json_1}"
    set -l item_json_2 "{\"id\": \"abc12\", \"title\":\"Item 12\",\"vault\":$vault_json_2}"

    run_1password_test \
        --description "op login is required" \
        --command "op item list " \
        --expected_1password_argv "item list --format=json" \
        --mock_1password_status 1 \
        --mock_1password_stderr "[ERROR] 2024/04/01 21:22:29 You are not currently signed in. Please run `op signin --help` for instructions" \
        --expected-stdout '[ERROR] 2024/04/01 21:22:29 You are not currently signed in. Please run `op signin --help` for instructions' \
        --expected-status 1
    run_1password_test \
        --description "fzf was canceled" \
        --command "op vaults get 2nd" \
        --mock_1password_stdout "[$vault_json_1, $vault_json_2]" \
        --mock-fzf-status 130 \
        --expected-status 130
end

@echo == Supported commands
run_supported_command_test_cases
@echo == Error cases
run_error_test_cases
