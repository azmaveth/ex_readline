defmodule ExReadline.LineEditor do
  @moduledoc """
  Advanced line editor with full readline functionality.

  This implementation provides comprehensive line editing features including:
  - Emacs-style keybindings
  - Arrow key navigation
  - Command history with search
  - Tab completion
  - Word-based movement
  - Line killing and yanking

  ## Keybindings

  ### Movement
  - `Ctrl-A` / `Home` - Move to beginning of line
  - `Ctrl-E` / `End` - Move to end of line
  - `Ctrl-B` / `←` - Move backward one character
  - `Ctrl-F` / `→` - Move forward one character
  - `Alt-B` - Move backward one word
  - `Alt-F` - Move forward one word

  ### Editing
  - `Ctrl-D` - Delete character under cursor (or EOF if line is empty)
  - `Backspace` - Delete character before cursor
  - `Ctrl-K` - Kill to end of line
  - `Ctrl-U` - Kill to beginning of line
  - `Ctrl-W` - Kill previous word
  - `Alt-D` - Delete next word

  ### History
  - `Ctrl-P` / `↑` - Previous history entry
  - `Ctrl-N` / `↓` - Next history entry

  ### Other
  - `Ctrl-L` - Clear screen and redraw line
  - `Tab` - Trigger completion
  - `Ctrl-C` - Cancel current line
  - `Enter` - Accept line
  """

  use GenServer
  require Logger

  alias ExReadline.{LineEditor.State, Terminal, Keybindings, History}

  @behaviour ExReadline.Behaviour

  @default_history_file "~/.config/ex_readline/history"
  @default_max_history_size 1_000

  # Client API

  @doc """
  Starts the line editor GenServer.
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Reads a line with full editing capabilities.
  """
  @impl ExReadline.Behaviour
  def read_line(prompt, opts \\ []) do
    GenServer.call(__MODULE__, {:read_line, prompt, opts}, :infinity)
  end

  @doc """
  Adds a line to the history.
  """
  @impl ExReadline.Behaviour
  def add_to_history(line) do
    GenServer.cast(__MODULE__, {:add_to_history, line})
  end

  @doc """
  Sets the completion function for tab completion.
  """
  @impl ExReadline.Behaviour
  def set_completion_fn(fun) when is_function(fun, 1) do
    GenServer.cast(__MODULE__, {:set_completion_fn, fun})
  end

  # Server callbacks

  @impl true
  def init(opts) do
    history_file = 
      Keyword.get(opts, :history_file, @default_history_file)
      |> normalize_path()
      
    max_history_size = Keyword.get(opts, :max_history_size, @default_max_history_size)

    # Load history
    history = if history_file, do: History.load(history_file), else: []

    state = %{
      history: history,
      history_file: history_file,
      max_history_size: max_history_size,
      completion_fn: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:read_line, prompt, _opts}, _from, state) do
    # Set up terminal for raw input
    {:ok, terminal_mode} = Terminal.setup_raw_mode()
    
    # Initialize line state
    line_state = State.new(
      prompt: prompt,
      history: state.history,
      completion_fn: state.completion_fn
    )

    # Show prompt
    IO.write(prompt)

    # Read input
    result = read_loop(line_state, terminal_mode)

    # Restore terminal settings
    Terminal.restore_mode(terminal_mode)
    
    handle_result(result, state)
  end
  
  defp handle_result(result, state) do

    # Handle result
    case result do
      {:ok, line} when line != "" ->
        new_history = History.add(line, state.history, state.max_history_size)
        
        if state.history_file do
          History.save(new_history, state.history_file)
        end
        
        {:reply, line, %{state | history: new_history}}

      {:ok, line} ->
        {:reply, line, state}

      {:error, :interrupted} ->
        {:reply, :eof, state}
    end
  end

  @impl true
  def handle_cast({:add_to_history, line}, state) do
    new_history = History.add(line, state.history, state.max_history_size)
    
    if state.history_file do
      History.save(new_history, state.history_file)
    end
    
    {:noreply, %{state | history: new_history}}
  end

  @impl true
  def handle_cast({:set_completion_fn, fun}, state) do
    {:noreply, %{state | completion_fn: fun}}
  end

  # Private functions

  defp normalize_path(nil), do: nil
  defp normalize_path(path), do: Path.expand(path)

  defp read_loop(state, terminal_mode) do
    case Terminal.read_key(terminal_mode) do
      {:ok, key} ->
        case Keybindings.handle_key(key, state, terminal_mode) do
          {:continue, new_state} ->
            read_loop(new_state, terminal_mode)
            
          {:done, result} ->
            result
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end