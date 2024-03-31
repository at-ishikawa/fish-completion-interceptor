function fci_run_fzf \
    --description "Run fzf from CLI" \
    --argument-names cli \
    cli_options \
    fzf_query \
    fzf_preview_command \
    fzf_options

    set -l candidates ($cli $cli_options 2>&1)
    set -l cli_status $status

    if [ $cli_status -ne 0 ]
        echo -n -s -e "$candidates" >&2
        return $cli_status
    end
    if [ -z "$candidates" ]
        return 0
    end

    # `echo -e "$candidates" | wc -l` doesn't when multiple lines are assigned to a variable
    set -l candidate_count (string split0 -- $candidates | wc -l)
    set -l result "$candidates"

    # Show fzf if
    # 1. there are multiple candidates, or
    # 2. there is a string on a command line
    if [ -n "$fzf_query" ]; or [ $candidate_count -ge 2 ]
        set fzf_options (string split " " -- $fzf_options)
        if [ -n "$fzf_preview_command" ]
            set -a fzf_options "--preview=$fzf_preview_command"
        end
        if [ -n "$fzf_query" ]
            set -a fzf_options "--query=$fzf_query"
        end
        for option in $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS
            set -a fzf_options $option
        end

        set -l fzf_result (string split0 -- $candidates | $FISH_COMPLETION_INTERCEPTOR_FZF_CLI $fzf_options)
        set -l fzf_status $status
        if [ $fzf_status -ne 0 ]
            echo -n -e "$fzf_result" >&2
            return $fzf_status
        end
        if [ -z "$fzf_result" ]
            return $fzf_status
        end

        set result $fzf_result
    end

    # echo -e "$result" cannot be used for multiple lines
    string split "\n" -- $result | awk '{ print $1 }' | string trim
    return 0
end
