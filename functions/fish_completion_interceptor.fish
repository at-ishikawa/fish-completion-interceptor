# Some code is from https://github.com/jethrokuan/fzf/blob/12557ee6359c6d4d25dd1e64945e31e18c8198d7/functions/__fzf_complete.fish
function fish_completion_interceptor -d "Intercept to run some commands during completion"
    set -l args (commandline -opc)
    set -l lastArg (string escape -- (commandline -ct))
    set -l cmd "$args[1] $args[2..-1]"

    for plugin in $FISH_COMPLETION_INTERCEPTOR_PLUGINS
        set definition (string split "=" $plugin)
        set -l commandName $definition[1]
        set -l functionName $definition[2]
        if [ "$commandName" != "$args[1]" ]
            continue
        end

        # Dynamically call a function
        set -l result (eval "$functionName" $args $lastArg)
        if [ $status -ne 0 ]
            break
        end

        # TODO: Replacing a current token instead of inserting
        # For example, if current token is fis, and fish is selected,
        # then instead of outputting fisfish, output fish
        commandline -i (echo $result)
        commandline -f repaint
        return 0
    end

    if type -q fish_completion_interceptor_fallback
        fish_completion_interceptor_fallback
        return $status
    end
    complete -C$cmd
    commandline -f repaint
    return 0
end

# function fish_completion_interceptor_fallback
#     __fzf_complete
# end
