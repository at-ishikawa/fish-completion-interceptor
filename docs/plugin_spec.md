# Interface

The plugin of fish-completion-interceptor should follow following interface.

## Input

The `$argv` array contains the command line arguments.

## Stdout

### status = 0

1. If stdout is empty, use other fish completion.
1. If there is stdout, replace the current argument on the cursor of a command line with the plugin's output. If there are multiple rows, concatenate them with a space.

### status != 0

From stdout of the plugin, output them on the next line.

## Stderr

The plugin needs to capture stderr and handle correctly for an interceptor.
The recommendation is to capture stderr and output them into stdout, to handle by the interceptor.
The interceptor intentionally doesn't capture stderr at all because capturing stderr causes disabling fzf in some cases.
For example, if it were to be enabled, `set -l var (cli | fzf)` would still work but `cli | fzf` would stop working.
