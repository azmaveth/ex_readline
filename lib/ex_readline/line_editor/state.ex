defmodule ExReadline.LineEditor.State do
  @moduledoc """
  State management for the line editor.

  This module handles the internal state of the line editor including
  the current buffer, cursor position, history navigation, and more.
  """

  defstruct [
    :buffer,
    :cursor,
    :history,
    :history_index,
    :prompt,
    :saved_line,
    :completion_fn,
    :kill_ring
  ]

  @type t :: %__MODULE__{
    buffer: binary(),
    cursor: non_neg_integer(),
    history: [binary()],
    history_index: non_neg_integer(),
    prompt: binary(),
    saved_line: binary() | nil,
    completion_fn: (binary() -> [binary()]) | nil,
    kill_ring: [binary()]
  }

  @doc """
  Creates a new line editor state.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      buffer: "",
      cursor: 0,
      history: Keyword.get(opts, :history, []),
      history_index: length(Keyword.get(opts, :history, [])),
      prompt: Keyword.get(opts, :prompt, "> "),
      saved_line: nil,
      completion_fn: Keyword.get(opts, :completion_fn),
      kill_ring: []
    }
  end

  @doc """
  Inserts a character at the current cursor position.
  """
  @spec insert_char(t(), char()) :: t()
  def insert_char(state, char) when is_integer(char) do
    {before, after_} = String.split_at(state.buffer, state.cursor)
    new_buffer = before <> <<char>> <> after_
    %{state | buffer: new_buffer, cursor: state.cursor + 1}
  end

  @doc """
  Deletes the character before the cursor (backspace).
  """
  @spec backspace(t()) :: t()
  def backspace(state) do
    if state.cursor > 0 do
      {before, after_} = String.split_at(state.buffer, state.cursor)
      new_buffer = String.slice(before, 0..-2//1) <> after_
      %{state | buffer: new_buffer, cursor: state.cursor - 1}
    else
      state
    end
  end

  @doc """
  Deletes the character at the cursor position.
  """
  @spec delete_char(t()) :: t()
  def delete_char(state) do
    if state.cursor < String.length(state.buffer) do
      {before, after_} = String.split_at(state.buffer, state.cursor)
      new_buffer = before <> String.slice(after_, 1..-1//1)
      %{state | buffer: new_buffer}
    else
      state
    end
  end

  @doc """
  Moves the cursor left by one position.
  """
  @spec move_left(t()) :: t()
  def move_left(state) do
    if state.cursor > 0 do
      %{state | cursor: state.cursor - 1}
    else
      state
    end
  end

  @doc """
  Moves the cursor right by one position.
  """
  @spec move_right(t()) :: t()
  def move_right(state) do
    if state.cursor < String.length(state.buffer) do
      %{state | cursor: state.cursor + 1}
    else
      state
    end
  end

  @doc """
  Moves the cursor to the beginning of the line.
  """
  @spec move_to_start(t()) :: t()
  def move_to_start(state) do
    %{state | cursor: 0}
  end

  @doc """
  Moves the cursor to the end of the line.
  """
  @spec move_to_end(t()) :: t()
  def move_to_end(state) do
    %{state | cursor: String.length(state.buffer)}
  end

  @doc """
  Kills (cuts) text from cursor to end of line.
  """
  @spec kill_to_end(t()) :: t()
  def kill_to_end(state) do
    killed = String.slice(state.buffer, state.cursor..-1//1)
    new_buffer = String.slice(state.buffer, 0, state.cursor)
    
    new_kill_ring = 
      if killed != "" do
        [killed | state.kill_ring] |> Enum.take(10)
      else
        state.kill_ring
      end
      
    %{state | buffer: new_buffer, kill_ring: new_kill_ring}
  end

  @doc """
  Kills (cuts) text from beginning of line to cursor.
  """
  @spec kill_to_start(t()) :: t()
  def kill_to_start(state) do
    killed = String.slice(state.buffer, 0, state.cursor)
    new_buffer = String.slice(state.buffer, state.cursor..-1//1)
    
    new_kill_ring = 
      if killed != "" do
        [killed | state.kill_ring] |> Enum.take(10)
      else
        state.kill_ring
      end
      
    %{state | buffer: new_buffer, cursor: 0, kill_ring: new_kill_ring}
  end

  @doc """
  Navigates to the previous history entry.
  """
  @spec history_prev(t()) :: t()
  def history_prev(state) do
    if state.history_index > 0 do
      # Save current line if moving from the end
      saved_line =
        if state.history_index == length(state.history) do
          state.buffer
        else
          state.saved_line
        end

      new_index = state.history_index - 1
      new_buffer = Enum.at(state.history, new_index, "")

      %{state | 
        buffer: new_buffer,
        cursor: String.length(new_buffer),
        history_index: new_index,
        saved_line: saved_line
      }
    else
      state
    end
  end

  @doc """
  Navigates to the next history entry.
  """
  @spec history_next(t()) :: t()
  def history_next(state) do
    if state.history_index < length(state.history) do
      new_index = state.history_index + 1

      new_buffer =
        if new_index == length(state.history) do
          state.saved_line || ""
        else
          Enum.at(state.history, new_index, "")
        end

      %{state | 
        buffer: new_buffer, 
        cursor: String.length(new_buffer), 
        history_index: new_index
      }
    else
      state
    end
  end
end