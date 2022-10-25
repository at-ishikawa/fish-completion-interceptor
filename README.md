Fish Completion Interceptor
===

**This tool is still unstable and immature, and under development without any plans**

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
There are numerous unsupported use cases by this tool.

- Replace the current argument with selected element instead of inserting

There are also a lot of unsupported features on a kubectl fzf plugin

### kubectl fzf
- Options are not recognized except -n/--namespace
    - And in many cases, options are not supported well. For example, there should be no option between `get/describe/delete` and resource.
- There are some subcommands that completion do not work, like `rollout`


Development
----

### Dependencies
* [fishtape](https://github.com/jorgebucaran/fishtape)

### Commmands

* `make test`: Run test cases
