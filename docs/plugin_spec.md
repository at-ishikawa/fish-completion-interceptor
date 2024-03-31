# Interface

The plugin of fish-completion-interceptor should follow following interface.

## Input

The `$argv` array contains the command line arguments.

## Output

### status = 0

1. If both of stdout and stderr is empty, use other fish completion.
1. If there is stdout and stderr, replace the current argument on the cursor of a command line with the plugin's output. If there are multiple rows, concatenate them with a space.

### status != 0

1. From stdout and stderr of the plugin, output them on the next line.
