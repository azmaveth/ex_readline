defmodule ExReadline.SimpleReader do
  @moduledoc """
  Simple line reader that uses Erlang's built-in line editing.
  
  This implementation provides basic line editing functionality
  by leveraging Erlang's IO system. It's simpler and more portable
  than the full line editor, but has fewer features.

  ## Features

  - Basic line editing (provided by Erlang)
  - Command history with persistence
  - Simple and reliable
  - Good terminal compatibility

  ## Limitations

  - No custom keybindings
  - No tab completion
  - Limited control over terminal
  """

  use GenServer
  require Logger

  @behaviour ExReadline.Behaviour

  @default_history_file "~/.config/ex_readline/history"
  @default_max_history_size 1_000

  defstruct [:history, :history_file, :max_history_size]

  # Client API

  @doc """
  Starts the simple reader GenServer.
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Reads a line using Erlang's built-in IO system.
  """
  @impl ExReadline.Behaviour
  def read_line(prompt, _opts \\ []) do
    # Use Erlang's IO system which has built-in line editing
    input = IO.gets(prompt)

    case input do
      :eof ->
        :eof

      {:error, _reason} ->
        :eof

      line when is_binary(line) ->
        line = String.trim_trailing(line, "\n")

        # Add to history if not empty
        if line != "" do
          add_to_history(line)
        end

        line
    end
  end

  @doc """
  Adds a line to the history.
  """
  @impl ExReadline.Behaviour
  def add_to_history(line) do
    GenServer.cast(__MODULE__, {:add_to_history, line})
  end

  @doc """
  Sets the completion function (no-op for simple reader).
  """
  @impl ExReadline.Behaviour
  def set_completion_fn(_fun) do
    # Simple reader doesn't support tab completion
    :ok
  end

  # Server callbacks

  @impl true
  def init(opts) do
    history_file = 
      Keyword.get(opts, :history_file, @default_history_file)
      |> normalize_path()
      
    max_history_size = Keyword.get(opts, :max_history_size, @default_max_history_size)

    # Load history
    history = if history_file, do: load_history(history_file), else: []

    # Set up readline-like behavior using Erlang's edlin
    # This gives us arrow keys and basic line editing
    Application.put_env(:elixir, :ansi_enabled, true)

    state = %__MODULE__{
      history: history,
      history_file: history_file,
      max_history_size: max_history_size
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:add_to_history, line}, state) do
    new_history = add_line_to_history(line, state.history, state.max_history_size)
    
    if state.history_file do
      save_history(new_history, state.history_file)
    end
    
    {:noreply, %{state | history: new_history}}
  end

  # Private functions

  defp normalize_path(nil), do: nil
  defp normalize_path(path), do: Path.expand(path)

  defp add_line_to_history(line, history, max_size) do
    # Don't add duplicates of the last entry
    if history == [] or hd(history) != line do
      [line | history]
      |> Enum.take(max_size)
    else
      history
    end
  end

  defp load_history(path) do
    case File.read(path) do
      {:ok, content} ->
        content
        |> String.split("\n", trim: true)
        |> Enum.reverse()
        |> Enum.take(@default_max_history_size)

      {:error, _} ->
        []
    end
  end

  defp save_history(history, path) do
    dir = Path.dirname(path)

    # Ensure directory exists
    File.mkdir_p!(dir)

    # Write history (newest first in file)
    content =
      history
      |> Enum.reverse()
      |> Enum.join("\n")

    File.write!(path, content <> "\n")
  rescue
    e ->
      Logger.warning("Failed to save history: #{Exception.message(e)}")
  end
end