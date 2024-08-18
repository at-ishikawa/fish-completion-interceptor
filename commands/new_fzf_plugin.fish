echo -n "Type a command name for new plugin:"
read command

set upper_command_name (string upper $command)

echo set __FCI_PLUGIN_"$upper_command_name"_FZF_"$upper_command_name"_CLI $command > conf.d/__fci_plugin_"$command"_fzf.fish

# https://github.com/fish-shell/fish-shell/issues/540#issuecomment-52779637
printf "\
__fci_functions

function fci_plugin_%s_fzf
    --description \"The plugin for %s\"
end
" $command $command > functions/fci_plugin_"$command"_fzf.fish

echo set -a FISH_COMPLETION_INTERCEPTOR_PLUGINS "$command"=fci_plugin_"$command"_fzf >> conf.d/fish_completion_interceptor.fish

printf "\
set -g __FCI_PLUGIN_%s_FZF_%s_CLI mock_%s
set FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_%s_test
    __fci_plugin_run_test \
        --plugin_function=fci_plugin_%s_fzf \
        $argv
end

function run_supported_command_test_cases
end

function run_error_test_cases
end

@echo == Supported commands
run_supported_command_test_cases
@echo == Error cases
run_error_test_cases
" $upper_command_name $upper_command_name $command \
    $command $command > tests/fci_plugin_"$command"_fzf_test.fish
