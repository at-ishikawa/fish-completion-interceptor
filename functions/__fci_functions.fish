function __fci_functions \
    --description "Declare functions not exposed publicly"

    # fzf during the pipe doesn't work even with a redirection of stdout to stderr and stderr to stdout
    function __fci_fzf
        argparse multi \
            "header=?" \
            "header-lines=?" \
            "preview=?" \
            "query=?" \
            "bind=+" \
            "prompt=?" \
            -- $argv
        set -l fzf_options
        if set -ql _flag_multi
            set -a fzf_options --multi
        end
        if [ -n "$_flag_prompt" ]
            set -a fzf_options "--prompt=$_flag_prompt"
        end
        if [ -n "$_flag_header" ]
            set -a fzf_options "--header=$_flag_header"
        end
        if [ -n "$_flag_header_lines" ]; and [ $_flag_header_lines -gt 0 ]
            set -a fzf_options "--header-lines=$_flag_header_lines"
        end
        if [ -n "$_flag_preview" ]
            set -a fzf_options "--preview=$_flag_preview"
        end
        if [ -n "$_flag_query" ]
            set -a fzf_options "--query=$_flag_query"
        end
        if set -ql _flag_bind
            for bind in $_flag_bind
                set -a fzf_options "--bind=$bind"
            end
        end
        for option in $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS
            set -a fzf_options $option
        end

        $FISH_COMPLETION_INTERCEPTOR_FZF_CLI $fzf_options
    end
end
