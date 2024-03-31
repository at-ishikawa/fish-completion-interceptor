# Fish Completion Interceptor (FCI)

> This plugin is under development and can have breaking changes in the future.

This plugin is to run a command for specific commands instead of showing regular completions of fish.

The next demo shows for the usage of `kubectl get pods` with fzf for a completion by this plugin.

![Demo](./docs/videos/kubectl_demo.gif)

## Install

Install this plugin using a [fisher](https://github.com/jorgebucaran/fisher).

```fish
fisher install at-ishikawa/fish-completion-interceptor
```

## Configurations

If you try to use completion by a tab key, this plugin is used automatically for specific commands.

If you want to use other completions, define `fish_completion_interceptor_fallback` function in your config file and call it.
For example, if you want to use [jethrokuan/fzf](https://github.com/jethrokuan/fzf) as default, you can still use that plugin by defining the next function in `~/.config/fish/config.fish`.

```fish
function fish_completion_interceptor_fallback
    __fzf_complete
end
```

There are some variables that can be defined:

* `FISH_COMPLETION_INTERCEPTOR_PLUGINS`: The commands to intercept by which function.
* `FISH_COMPLETION_INTERCEPTOR_ENABLED`: true if the interceptor is enabled.
* `FISH_COMPLETION_INTERCEPTOR_FZF_KEY_BINDINGS`: The options to run fzf. The default is `--inline-info --layout reverse --preview-window down:70% --bind ctrl-k:kill-line,ctrl-alt-t:toggle-preview,ctrl-alt-n:preview-down,ctrl-alt-p:preview-up,ctrl-alt-v:preview-page-down`.


## FCI plugins

Currently, there are 2 plugins supported by this plugin.
Note that not all subcommands have been supported.

- [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/)
- [GitHub CLI](https://github.com/cli/cli)


## Customize

If you want to run a command in for a particular command, let's say `foo`, then you can add it by

```fish
function your_command_interceptor
    # Add your logic
    # $argv is arguments from commandline
end

set -U FISH_COMPLETION_INTERCEPTOR_PLUGINS $FISH_COMPLETION_INTERCEPTOR_PLUGINS "foo=your_command_interceptor"
```

For more details, see [the plugin spec doc](./docs/plugin_spec).

## Development

### Dependencies

- [fishtape](https://github.com/jorgebucaran/fishtape)

### Commmands

- `make install`: Install this plugin into `~/.config/fish` using `fisher`
- `make dependencies`: Install dependencies to develop this plugin
- `make generate:`: Generate configuration files that are supposed to be generated automatically. `kubectl` is required.
- `make test`: Run test cases
