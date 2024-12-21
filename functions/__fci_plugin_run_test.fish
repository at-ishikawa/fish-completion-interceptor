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
        'expected-fzf-default-command=' \
        -- $argv

    set -l expected_fzf_option $_flag_expected_fzf_option
    set -l expected_fzf_default_command $_flag_expected_fzf_default_command

    function mock_fzf \
        --inherit-variable expected_fzf_option \
        --inherit-variable _flag_mock_fzf_stdout \
        --inherit-variable _flag_mock_fzf_status \
        --inherit-variable expected_fzf_default_command

        if [ -n "$expected_fzf_default_command" ]; and [ "$expected_fzf_default_command" != "$FZF_DEFAULT_COMMAND" ]
            # @test FZF_DEFAULT_COMMAND "$FZF_DEFAULT_COMMAND" = "$expected_fzf_default_command"
            set -l actual "$FZF_DEFAULT_COMMAND"
            set -l expected "$expected_fzf_default_command"

            echo "not ok - FZF_DEFAULT_COMMAND" >&2
            echo "  ---" >&2
            echo "    expected: $expected" >&2
            echo "    actual: $actual" >&2
            echo "  ..." >&2

            # set -l diff (diff (echo $FZF_DEFAULT_COMMAND | string split ' ' | psub) (echo $expected_fzf_default_command | string split ' ' | psub))
            # echo "FZF_DEFAULT_COMMAND diff: $diff" >&2
            return 255
        end

        if test -n "$expected_fzf_option"; and [ "$expected_fzf_option" != "$argv" ]
            set -l diff (diff (echo $argv | string split ' ' | psub) (echo $expected_fzf_option | string split ' ' | psub))
            echo "fzf argv diff: $diff" >&2
            return 255
        end
        echo -e "$_flag_mock_fzf_stdout"
        return $_flag_mock_fzf_status
    end

    set -l command $_flag_command
    @echo "Test case: $_flag_description: $command"

    set -l commandline_args (string split " " $command)
    set -l actual_stdout ($_flag_plugin_function $commandline_args 2>| read -z actual_stderr)
    set -l actual_status $pipestatus[1]

    set -q _flag_expected_status; or set _flag_expected_status 0
    @test "command status" $actual_status -eq $_flag_expected_status
    set -q _flag_expected_stdout; or set _flag_expected_stdout ""
    @test "command stdout" "$actual_stdout" = "$_flag_expected_stdout"
    set -q _flag_expected_stderr; or set _flag_expected_stderr ""

    if [ -n "$expected_fzf_default_command" ]; and [ -n "$actual_stderr" ]
        echo -e "$actual_stderr" >&2
        return 1
    else
        @test "command stderr" "$actual_stderr" = $_flag_expected_stderr
    end
end
