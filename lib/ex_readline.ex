defmodule ExReadline do
  @moduledoc """
  A pure Elixir readline implementation with support for history, keybindings, and tab completion.

  This module provides a unified interface to different readline implementations.
  By default, it uses the simple reader, but you can switch to the advanced line editor
  for more features.

  ## Example

      # Start with default implementation (simple reader)
      {:ok, _pid} = ExReadline.start_link()

      # Read a line
      line = ExReadline.read_line("> ")

      # Start with advanced line editor
      {:ok, _pid} = ExReadline.start_link(implementation: :line_editor)

      # Set up tab completion (only works with :line_editor)
      ExReadline.set_completion_fn(fn partial ->
        ~w[help quit list] |> Enum.filter(&String.starts_with?(&1, partial))
      end)
  """

  @doc """
  Starts the readline server.

  ## Options

  - `:implementation` - Which implementation to use: `:simple_reader` (default) or `:line_editor`
  - `:history_file` - Path to history file (default: ~/.config/ex_readline/history)
  - `:max_history_size` - Maximum number of history entries (default: 1000)
  - `:name` - GenServer name (default: based on implementation)

  ## Examples

      # Default simple reader
      {:ok, _pid} = ExReadline.start_link()

      # Advanced line editor
      {:ok, _pid} = ExReadline.start_link(implementation: :line_editor)

      # Custom history location
      {:ok, _pid} = ExReadline.start_link(history_file: "/tmp/myapp_history")
  """
  def start_link(opts \\ []) do
    implementation = Keyword.get(opts, :implementation, :simple_reader)
    
    case implementation do
      :simple_reader ->
        ExReadline.SimpleReader.start_link(opts)
        
      :line_editor ->
        ExReadline.LineEditor.start_link(opts)
        
      module when is_atom(module) ->
        if function_exported?(module, :start_link, 1) do
          module.start_link(opts)
        else
          {:error, {:invalid_implementation, module}}
        end
        
      _ ->
        {:error, {:invalid_implementation, implementation}}
    end
  end

  @doc """
  Reads a line from the user with the given prompt.

  Returns the line as a string (without trailing newline) or `:eof` if
  the user types Ctrl-D on an empty line or Ctrl-C.

  ## Examples

      iex> ExReadline.read_line("> ")
      "hello world"

      iex> ExReadline.read_line("$ ")
      :eof  # User pressed Ctrl-D
  """
  @spec read_line(binary(), keyword()) :: binary() | :eof
  def read_line(prompt, opts \\ []) do
    # Determine which implementation is running
    cond do
      Process.whereis(ExReadline.SimpleReader) ->
        ExReadline.SimpleReader.read_line(prompt, opts)
        
      Process.whereis(ExReadline.LineEditor) ->
        ExReadline.LineEditor.read_line(prompt, opts)
        
      true ->
        # Fallback to basic IO.gets
        case IO.gets(prompt) do
          :eof -> :eof
          {:error, _} -> :eof
          line -> String.trim_trailing(line, "\n")
        end
    end
  end

  @doc """
  Adds a line to the history.

  This is useful for programmatically adding entries to history.

  ## Examples

      ExReadline.add_to_history("previous command")
  """
  @spec add_to_history(binary()) :: :ok
  def add_to_history(line) do
    cond do
      pid = Process.whereis(ExReadline.SimpleReader) ->
        GenServer.cast(pid, {:add_to_history, line})
        
      pid = Process.whereis(ExReadline.LineEditor) ->
        GenServer.cast(pid, {:add_to_history, line})
        
      true ->
        :ok
    end
  end

  @doc """
  Sets the completion function for tab completion.

  Only works with the `:line_editor` implementation.

  The completion function receives a partial string and should return
  a list of possible completions.

  ## Examples

      ExReadline.set_completion_fn(fn partial ->
        commands = ~w[help quit list show]
        Enum.filter(commands, &String.starts_with?(&1, partial))
      end)
  """
  @spec set_completion_fn((binary() -> [binary()])) :: :ok
  def set_completion_fn(fun) when is_function(fun, 1) do
    if pid = Process.whereis(ExReadline.LineEditor) do
      GenServer.cast(pid, {:set_completion_fn, fun})
    else
      :ok
    end
  end
end