set -U FISH_COMPLETION_INTERCEPTOR_PLUGINS "kubectl=fci_plugin_kubectl_fzf" "gh=fci_plugin_gh_fzf"
set -q FISH_COMPLETION_INTERCEPTOR_ENABLED; or set -U FISH_COMPLETION_INTERCEPTOR_ENABLED true

if $FISH_COMPLETION_INTERCEPTOR_ENABLED
    bind \t fish_completion_interceptor
end
