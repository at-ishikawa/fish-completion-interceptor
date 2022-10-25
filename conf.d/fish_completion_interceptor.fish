set -U FISH_COMPLETION_INTERCEPTOR_PLUGINS "kubectl=fci_plugin_kubectl_fzf"

bind \t fish_completion_interceptor
