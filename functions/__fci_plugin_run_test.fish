function __fci_plugin_run_test \
    --description "This function is used for a fishtape for testing a plugin"

    argparse 'plugin-function=' \
        'description=' \
        'command=' \
        'mock-fzf-stdout=' \
        'mock-fzf-status=' \
        'expected-fzf-option=' \
        'expected-status=' \
        'expected-stdout=' \
        'expected-stderr=' \
        -- $argv

    set -l expected_fzf_option $_flag_expected_fzf_option
    function mock_fzf \
        --inherit-variable expected_fzf_option \
        --inherit-variable _flag_mock_fzf_stdout \
        --inherit-variable _flag_mock_fzf_status

        if test -n "$expected_fzf_option"; and [ "$expected_fzf_option" != "$argv" ]
            echo "fzf argv diff: $(diff (echo $argv | string split ' ' | psub) (echo $expected_fzf_option | string split ' ' | psub))" >&2
            return 255
        end
        echo -e "$_flag_mock_fzf_stdout"
        return $_flag_mock_fzf_status
    end

    set -l command $_flag_command
    @echo "Test case $_flag_description: $command"

    set -l commandline_args (string split " " $command)
    set -l actual_stdout ($_flag_plugin_function $commandline_args 2>| read -z actual_stderr)
    set -l actual_status $pipestatus[1]

    set -q _flag_expected_status; or set _flag_expected_status 0
    @test "command status" $actual_status -eq $_flag_expected_status
    set -q _flag_expected_stdout; or set _flag_expected_stdout ""
    @test "command stdout" "$actual_stdout" = "$_flag_expected_stdout"
    set -q _flag_expected_stderr; or set _flag_expected_stderr ""
    @test "command stderr" "$actual_stderr" = $_flag_expected_stderr
end
