defmodule ExReadline.Terminal do
  @moduledoc """
  Terminal control functions for the line editor.

  This module handles low-level terminal operations including:
  - Setting raw mode for character-by-character input
  - Reading individual keystrokes
  - Cursor movement
  - Screen clearing
  - ANSI escape sequence handling
  """

  # ANSI escape sequences
  @cursor_right "\e[C"
  @cursor_left "\e[D"
  @clear_line "\r\e[2K"
  @clear_screen "\e[2J\e[H"

  @doc """
  Sets up the terminal for raw input mode.

  Returns the previous terminal settings which should be
  restored when done.
  """
  @spec setup_raw_mode() :: keyword()
  def setup_raw_mode() do
    old_settings = :io.getopts(:standard_io)
    # Ensure we flush any pending output first
    IO.write("")
    :io.setopts(:standard_io, binary: true, echo: false)
    old_settings
  end

  @doc """
  Restores the terminal to its previous mode.
  """
  @spec restore_mode(keyword()) :: :ok
  def restore_mode(old_settings) do
    :io.setopts(:standard_io, old_settings)
    :ok
  end

  @doc """
  Reads a single key from the terminal.

  Returns `{:ok, byte}` or `{:error, reason}`.
  """
  @spec read_key() :: {:ok, byte()} | {:error, term()}
  def read_key() do
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