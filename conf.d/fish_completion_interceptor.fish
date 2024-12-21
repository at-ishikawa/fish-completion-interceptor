set -q FISH_COMPLETION_INTERCEPTOR_ENABLED; or set -U FISH_COMPLETION_INTERCEPTOR_ENABLED true

set FISH_COMPLETION_INTERCEPTOR_FZF_KEY_BINDINGS ctrl-k:kill-line,ctrl-alt-t:toggle-preview,ctrl-alt-n:preview-down,ctrl-alt-p:preview-up,ctrl-alt-v:preview-page-down
set -q FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS; or set FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS --inline-info --layout reverse --preview-window down:70% --bind $FISH_COMPLETION_INTERCEPTOR_FZF_KEY_BINDINGS

set FISH_COMPLETION_INTERCEPTOR_FZF_CLI fzf

if $FISH_COMPLETION_INTERCEPTOR_ENABLED
    bind \t fish_completion_interceptor
end

set -U FISH_COMPLETION_INTERCEPTOR_PLUGINS kubectl=fci_plugin_kubectl_fzf
set -a FISH_COMPLETION_INTERCEPTOR_PLUGINS gh=fci_plugin_gh_fzf
set -a FISH_COMPLETION_INTERCEPTOR_PLUGINS gcloud=fci_plugin_gcloud_fzf
set -a FISH_COMPLETION_INTERCEPTOR_PLUGINS op=fci_plugin_op_fzf
set -a FISH_COMPLETION_INTERCEPTOR_PLUGINS ghq=fci_plugin_ghq_fzf
set -a FISH_COMPLETION_INTERCEPTOR_PLUGINS aws=fci_plugin_aws_fzf
