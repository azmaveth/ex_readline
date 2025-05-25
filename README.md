# ExReadline

Enhanced line editing library for Elixir with history, completion, and keybindings.

> ⚠️ **Alpha Quality Software**: This library is in early development (v0.x.x). APIs may change without notice until version 1.0.0 is released. Use in production at your own risk.

## Features

- **Two implementation modes**: Simple (Erlang IO) and Advanced (full readline)
- **Command history**: Persistent history with configurable file location
- **Tab completion**: Customizable completion functions (advanced mode only)
- **Emacs keybindings**: Basic navigation and editing commands
- **Arrow key support**: Navigate through history and within lines
- **Kill ring**: Cut and paste functionality
- **Terminal control**: Clear screen, cursor movement
- **Pure Elixir**: No external dependencies or NIFs

## Installation

Add `ex_readline` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_readline, "~> 0.1.0"}
  ]
end
```

## Usage

### Basic Usage

```elixir
# Start with default simple reader
{:ok, _pid} = ExReadline.start_link()

# Read a line with prompt
line = ExReadline.read_line("> ")
```

### Advanced Mode with Tab Completion

```elixir
# Start with advanced line editor
{:ok, _pid} = ExReadline.start_link(implementation: :line_editor)

# Set up tab completion
ExReadline.set_completion_fn(fn partial ->
  commands = ~w[help quit list show status]
  Enum.filter(commands, &String.starts_with?(&1, partial))
end)

# Read with completion support
command = ExReadline.read_line("$ ")
```

### Custom History File

```elixir
{:ok, _pid} = ExReadline.start_link(
  history_file: "~/.myapp_history",
  max_history_size: 500
)
```

## Keybindings

### Navigation
- `Ctrl-A` / `Home`: Move to beginning of line
- `Ctrl-E` / `End`: Move to end of line
- `Ctrl-B` / `←`: Move back one character
- `Ctrl-F` / `→`: Move forward one character
- `Alt-B`: Move back one word
- `Alt-F`: Move forward one word

### Editing
- `Ctrl-D`: Delete character under cursor (or exit on empty line)
- `Backspace`: Delete character before cursor
- `Ctrl-K`: Kill (cut) from cursor to end of line
- `Ctrl-U`: Kill (cut) from beginning to cursor
- `Ctrl-W`: Kill (cut) previous word
- `Ctrl-Y`: Yank (paste) killed text

### History
- `Ctrl-P` / `↑`: Previous history entry
- `Ctrl-N` / `↓`: Next history entry

### Other
- `Ctrl-L`: Clear screen
- `Ctrl-C`: Cancel current line
- `Tab`: Trigger completion (advanced mode only)
- `Enter`: Accept line

## Implementation Modes

### Simple Reader
- Uses Erlang's built-in IO system
- Basic line editing capabilities
- History support
- Good for simple use cases

### Line Editor (Advanced)
- Full readline implementation
- Tab completion support
- Advanced cursor movement
- Better keybinding support
- Raw terminal mode handling

## Configuration

### Options for `start_link/1`

- `:implementation` - `:simple_reader` (default) or `:line_editor`
- `:history_file` - Path to history file (default: `~/.config/ex_readline/history`)
- `:max_history_size` - Maximum history entries (default: 1000)
- `:name` - GenServer name (default: based on implementation)

## Known Issues

- Arrow keys and Ctrl-P/N show escape sequences in escript mode
- Terminal handling differs between IEx and escript environments
- These issues are specific to how escripts handle terminal I/O

## Examples

### Building a Simple REPL

```elixir
defmodule MyREPL do
  def start do
    {:ok, _} = ExReadline.start_link(implementation: :line_editor)
    
    ExReadline.set_completion_fn(&complete/1)
    
    loop()
  end
  
  defp loop do
    case ExReadline.read_line("myrepl> ") do
      :eof -> 
        IO.puts("\nGoodbye!")
        
      line ->
        process_command(line)
        loop()
    end
  end
  
  defp complete(partial) do
    ~w[help quit list show]
    |> Enum.filter(&String.starts_with?(&1, partial))
  end
  
  defp process_command("quit"), do: System.halt(0)
  defp process_command("help"), do: IO.puts("Available commands: help, quit, list, show")
  defp process_command(cmd), do: IO.puts("Unknown command: #{cmd}")
end
```

### Programmatic History Management

```elixir
# Add entries to history programmatically
ExReadline.add_to_history("previous command")
ExReadline.add_to_history("another command")

# History is automatically saved to disk
```

## Development

```bash
# Run tests
mix test

# Run formatter
mix format

# Run static analysis
mix credo

# Run type checking
mix dialyzer

# Generate documentation
mix docs
```

## License

MIT License - see LICENSE file for details.