set __FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI kubectl
set __FCI_PLUGIN_KUBECTL_FZF_FZF_CLI fzf
set __FCI_PLUGIN_KUBECTL_FZF_FZF_KEY_BINDINGS ctrl-k:kill-line,ctrl-alt-t:toggle-preview,ctrl-alt-n:preview-down,ctrl-alt-p:preview-up,ctrl-alt-v:preview-page-down

set -q FCI_PLUGIN_KUBECTL_FZF_FZF_OPTION; or set FCI_PLUGIN_KUBECTL_FZF_FZF_OPTION --inline-info --multi --layout reverse --preview-window down:70% --header-lines 1 --bind $__FCI_PLUGIN_KUBECTL_FZF_FZF_KEY_BINDINGS
