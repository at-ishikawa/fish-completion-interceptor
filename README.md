Fish Completion Interceptor
===

This tool is to run a command for specific commands instead of showing regular completions of fish.


Install
---

Note that this plugin requires [at-ishikawa/kubectl-fzf](https://github.com/at-ishikawa/kubectl-fzf).
Install the plugin at first.

Next, install this plugin by [fisher](https://github.com/jorgebucaran/fisher)
```
fisher install at-ishikawa/fish-completion-interceptor
```


Configuration
---
If you try to use completion by a tab key, this tool is used automatically for specific commands.
Define `set -U FISH_COMPLETION_INTERCEPTOR_ENABLED = false` in your config.fish if you want to disable this package.

If you want to use some completions if there is no that command instead of normal completion, define `fish_completion_interceptor_fallback` function in your config file.
For example, if you use [jethrokuan/fzf](https://github.com/jethrokuan/fzf), you can still use that plugin by defining the next function in `~/.config/fish/config.fish`.

```fish
function fish_completion_interceptor_fallback
    __fzf_complete
end
```

If you want to run a command in for a particular command, let's say `foo`, then you can add it by

```fish
function your_command_interceptor
    # Add your logic
    # $argv is arguments from commandline
end

set -U FISH_COMPLETION_INTERCEPTOR_PLUGINS $FISH_COMPLETION_INTERCEPTOR_PLUGINS "foo=your_command_interceptor"
```

TODOs
---
There are some unsupported features of this tool.

### kubectl fzf
- There are some subcommands that completion do not work, like `rollout`.


Development
----

### Dependencies
* [fishtape](https://github.com/jorgebucaran/fishtape)

### Commmands

* `make generate:`: Generate configuration files that are supposed to be generated automatically. `kubectl` is required.
* `make test`: Run test cases
