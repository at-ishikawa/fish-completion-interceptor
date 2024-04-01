function __fci_functions
    # fzf during the pipe doesn't work even with a redirection of stdout to stderr and stderr to stdout
    function __fci_fzf
        argparse multi "header-lines=?" "preview=?" "query=?" -- $argv
        set -l fzf_options
        if set -ql _flag_multi
            set -a fzf_options --multi
        end
        if [ -n "$_flag_header_lines" ]
            set -a fzf_options "--header-lines=$_flag_header_lines"
        end
        if [ -n "$_flag_preview" ]
            set -a fzf_options "--preview=$_flag_preview"
        end
        if [ -n "$_flag_query" ]
            set -a fzf_options "--query=$_flag_query"
        end
        for option in $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS
            set -a fzf_options $option
        end

        $FISH_COMPLETION_INTERCEPTOR_FZF_CLI $fzf_options
    end
end
