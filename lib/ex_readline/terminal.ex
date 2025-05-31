defmodule ExReadline.Terminal do
  @moduledoc """
  Terminal control functions for the line editor.

  This module handles low-level terminal operations including:
  - Setting raw mode for character-by-character input
  - Reading individual keystrokes
  - Cursor movement
  - Screen clearing
  - ANSI escape sequence handling

  Automatically detects and adapts to different runtime environments:
  - IEx/Interactive mode: Uses standard Erlang IO
  - Escript mode: Uses direct TTY access via system commands and file I/O
  """

  # ANSI escape sequences
  @cursor_right "\e[C"
  @cursor_left "\e[D"
  @clear_line "\r\e[2K"
  @clear_screen "\e[2J\e[H"

  # Terminal mode detection
  defp is_escript_mode?() do
    # Check if we're running in an escript by examining terminal availability
    case :io.getopts(:standard_io) do
      opts when is_list(opts) ->
        terminal_status = Keyword.get(opts, :terminal, :undefined)
        terminal_status == :ebadf
      _ ->
        true
    end
  end

  @doc """
  Sets up the terminal for raw input mode.

  Returns the previous terminal settings which should be
  restored when done.
  """
  @spec setup_raw_mode() :: {:ok, term()} | {:error, term()}
  def setup_raw_mode() do
    if is_escript_mode?() do
      setup_raw_mode_escript()
    else
      setup_raw_mode_standard()
    end
  end

  defp setup_raw_mode_standard() do
    old_settings = :io.getopts(:standard_io)
    # Ensure we flush any pending output first
    IO.write("")
    :io.setopts(:standard_io, binary: true, echo: false)
    {:ok, {:standard, old_settings}}
  end

  defp setup_raw_mode_escript() do
    # For escript mode, we try multiple approaches:
    # 1. First try direct TTY access (works in some environments)
    # 2. Fall back to standard IO with escape sequence parsing (works everywhere)
    
    case try_tty_access() do
      {:ok, tty_mode} ->
        {:ok, tty_mode}
      {:error, _reason} ->
        # Fall back to standard IO with escape sequence parsing
        old_settings = :io.getopts(:standard_io)
        :io.setopts(:standard_io, binary: true, echo: false)
        {:ok, {:escript_fallback, old_settings}}
    end
  end
  
  defp try_tty_access() do
    # Try to use stty and /dev/tty if available
    case System.cmd("stty", ["-g"], stderr_to_stdout: true) do
      {settings, 0} ->
        settings = String.trim(settings)
        
        # Set raw mode
        case System.cmd("stty", ["raw", "-echo", "-isig", "-icanon"], stderr_to_stdout: true) do
          {_, 0} ->
            # Try to open /dev/tty for reading
            case File.open("/dev/tty", [:binary, :read]) do
              {:ok, tty_handle} ->
                {:ok, {:escript, %{settings: settings, tty_handle: tty_handle}}}
              {:error, reason} ->
                # Restore settings on failure
                System.cmd("stty", [settings])
                {:error, {:tty_open_failed, reason}}
            end
          {error, _} ->
            {:error, {:stty_failed, error}}
        end
      {error, _} ->
        {:error, {:stty_get_failed, error}}
    end
  end

  @doc """
  Restores the terminal to its previous mode.
  """
  @spec restore_mode(term()) :: :ok
  def restore_mode({:standard, old_settings}) do
    :io.setopts(:standard_io, old_settings)
    :ok
  end

  def restore_mode({:escript, %{settings: settings, tty_handle: tty_handle}}) do
    File.close(tty_handle)
    System.cmd("stty", [settings])
    :ok
  end

  def restore_mode({:escript_fallback, old_settings}) do
    :io.setopts(:standard_io, old_settings)
    :ok
  end

  def restore_mode(_), do: :ok

  @doc """
  Reads a single key from the terminal.

  Returns `{:ok, byte}` or `{:error, reason}`.
  """
  @spec read_key(term()) :: {:ok, byte()} | {:error, term()}
  def read_key(mode \\ nil)

  def read_key(nil) do
    # Auto-detect mode and read
    if is_escript_mode?() do
      case setup_raw_mode() do
        {:ok, mode} ->
          result = read_key(mode)
          restore_mode(mode)
          result
        error ->
          error
      end
    else
      read_key_standard()
    end
  end

  def read_key({:standard, _}) do
    read_key_standard()
  end

  def read_key({:escript, %{tty_handle: tty_handle}}) do
    case IO.binread(tty_handle, 1) do
      :eof -> 
        {:error, :eof}
      {:error, reason} -> 
        {:error, reason}
      data when is_binary(data) -> 
        {:ok, :binary.first(data)}
    end
  end

  def read_key({:escript_fallback, _}) do
    read_key_standard()
  end

  defp read_key_standard() do
    case IO.getn("", 1) do
      :eof -> 
        {:error, :eof}
      {:error, reason} -> 
        {:error, reason}
      data when is_binary(data) -> 
        {:ok, :binary.first(data)}
    end
  end

  @doc """
  Moves the cursor left by n positions.
  """
  @spec move_cursor_left(non_neg_integer()) :: :ok
  def move_cursor_left(0), do: :ok
  def move_cursor_left(1) do
    IO.write(@cursor_left)
    :ok
  end
  def move_cursor_left(n) when n > 1 do
    IO.write("\e[#{n}D")
    :ok
  end

  @doc """
  Moves the cursor right by n positions.
  """
  @spec move_cursor_right(non_neg_integer()) :: :ok
  def move_cursor_right(0), do: :ok
  def move_cursor_right(1) do
    IO.write(@cursor_right)
    :ok
  end
  def move_cursor_right(n) when n > 1 do
    IO.write("\e[#{n}C")
    :ok
  end

  @doc """
  Clears the current line and moves cursor to beginning.
  """
  @spec clear_line() :: :ok
  def clear_line() do
    IO.write(@clear_line)
    :ok
  end

  @doc """
  Clears the entire screen and moves cursor to top-left.
  """
  @spec clear_screen() :: :ok
  def clear_screen() do
    IO.write(@clear_screen)
    :ok
  end

  @doc """
  Redraws the current line with the given state.
  """
  @spec redraw_line(ExReadline.LineEditor.State.t()) :: :ok
  def redraw_line(state) do
    clear_line()
    IO.write(state.prompt <> state.buffer)
    
    # Move cursor to correct position
    buffer_length = String.length(state.buffer)
    if state.cursor < buffer_length do
      move_cursor_left(buffer_length - state.cursor)
    end
    
    :ok
  end

  @doc """
  Rings the terminal bell.
  """
  @spec bell() :: :ok
  def bell() do
    IO.write("\a")
    :ok
  end
end