set -U FISH_COMPLETION_INTERCEPTOR_PLUGINS \
    "kubectl=fci_plugin_kubectl_fzf" \
    "gh=fci_plugin_gh_fzf" \
    "gcloud=fci_plugin_gcloud_fzf" \
    "op=fci_plugin_op_fzf"
set -q FISH_COMPLETION_INTERCEPTOR_ENABLED; or set -U FISH_COMPLETION_INTERCEPTOR_ENABLED true

set FISH_COMPLETION_INTERCEPTOR_FZF_KEY_BINDINGS ctrl-k:kill-line,ctrl-alt-t:toggle-preview,ctrl-alt-n:preview-down,ctrl-alt-p:preview-up,ctrl-alt-v:preview-page-down
set -q FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS; or set FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS --inline-info --layout reverse --preview-window down:70% --bind $FISH_COMPLETION_INTERCEPTOR_FZF_KEY_BINDINGS

set FISH_COMPLETION_INTERCEPTOR_FZF_CLI fzf

if $FISH_COMPLETION_INTERCEPTOR_ENABLED
    bind \t fish_completion_interceptor
end
