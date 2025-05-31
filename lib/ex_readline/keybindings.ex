defmodule ExReadline.Keybindings do
  @moduledoc """
  Keybinding handling for the line editor.

  This module processes keyboard input and maps keys to editing commands.
  It supports single-byte keys, control keys, and multi-byte escape sequences.
  """

  alias ExReadline.{LineEditor.State, Terminal}

  # Key codes
  @backspace 127
  @enter 13
  @escape 27
  @ctrl_a 1
  @ctrl_b 2
  @ctrl_c 3
  @ctrl_d 4
  @ctrl_e 5
  @ctrl_f 6
  @ctrl_k 11
  @ctrl_l 12
  @ctrl_n 14
  @ctrl_p 16
  @ctrl_u 21
  @ctrl_w 23
  @tab 9

  @doc """
  Handles a key press and returns the action to take.

  Returns either:
  - `{:continue, new_state}` to continue reading
  - `{:done, {:ok, line}}` when line is complete
  - `{:done, {:error, reason}}` on error
  """
  @spec handle_key(byte(), State.t(), term()) :: {:continue, State.t()} | {:done, {:ok, binary()} | {:error, term()}}
  def handle_key(@enter, state, _terminal_mode) do
    IO.write("\n")
    {:done, {:ok, state.buffer}}
  end

  def handle_key(@ctrl_c, _state, _terminal_mode) do
    IO.write("^C\n")
    {:done, {:error, :interrupted}}
  end

  def handle_key(@ctrl_d, state, _terminal_mode) do
    if state.buffer == "" do
      IO.write("\n")
      {:done, {:error, :interrupted}}
    else
      new_state = State.delete_char(state)
      Terminal.redraw_line(new_state)
      {:continue, new_state}
    end
  end

  def handle_key(@backspace, state, _terminal_mode) do
    new_state = State.backspace(state)
    Terminal.redraw_line(new_state)
    {:continue, new_state}
  end

  def handle_key(@escape, state, terminal_mode) do
    handle_escape_sequence(state, terminal_mode)
  end

  def handle_key(@ctrl_a, state, _terminal_mode) do
    new_state = State.move_to_start(state)
    Terminal.move_cursor_left(state.cursor)
    {:continue, new_state}
  end

  def handle_key(@ctrl_e, state, _terminal_mode) do
    new_state = State.move_to_end(state)
    move_count = String.length(state.buffer) - state.cursor
    Terminal.move_cursor_right(move_count)
    {:continue, new_state}
  end

  def handle_key(@ctrl_b, state, _terminal_mode) do
    new_state = State.move_left(state)
    if new_state.cursor != state.cursor do
      Terminal.move_cursor_left(1)
    end
    {:continue, new_state}
  end

  def handle_key(@ctrl_f, state, _terminal_mode) do
    new_state = State.move_right(state)
    if new_state.cursor != state.cursor do
      Terminal.move_cursor_right(1)
    end
    {:continue, new_state}
  end

  def handle_key(@ctrl_k, state, _terminal_mode) do
    new_state = State.kill_to_end(state)
    Terminal.redraw_line(new_state)
    {:continue, new_state}
  end

  def handle_key(@ctrl_u, state, _terminal_mode) do
    new_state = State.kill_to_start(state)
    Terminal.redraw_line(new_state)
    {:continue, new_state}
  end

  def handle_key(@ctrl_w, state, _terminal_mode) do
    new_state = kill_word(state)
    Terminal.redraw_line(new_state)
    {:continue, new_state}
  end

  def handle_key(@ctrl_l, state, _terminal_mode) do
    Terminal.clear_screen()
    Terminal.redraw_line(state)
    {:continue, state}
  end

  def handle_key(@ctrl_p, state, _terminal_mode) do
    new_state = State.history_prev(state)
    Terminal.redraw_line(new_state)
    {:continue, new_state}
  end

  def handle_key(@ctrl_n, state, _terminal_mode) do
    new_state = State.history_next(state)
    Terminal.redraw_line(new_state)
    {:continue, new_state}
  end

  def handle_key(@tab, state, _terminal_mode) do
    new_state = handle_tab_completion(state)
    {:continue, new_state}
  end

  def handle_key(char, state, _terminal_mode) when char >= 32 and char <= 126 do
    new_state = State.insert_char(state, char)
    Terminal.redraw_line(new_state)
    {:continue, new_state}
  end

  def handle_key(_char, state, _terminal_mode) do
    # Ignore unhandled keys
    {:continue, state}
  end

  # Private functions

  defp handle_escape_sequence(state, terminal_mode) do
    case Terminal.read_key(terminal_mode) do
      {:ok, ?[} ->
        case Terminal.read_key(terminal_mode) do
          # Up arrow
          {:ok, ?A} ->
            new_state = State.history_prev(state)
            Terminal.redraw_line(new_state)
            {:continue, new_state}

          # Down arrow
          {:ok, ?B} ->
            new_state = State.history_next(state)
            Terminal.redraw_line(new_state)
            {:continue, new_state}

          # Right arrow
          {:ok, ?C} ->
            new_state = State.move_right(state)
            if new_state.cursor != state.cursor do
              Terminal.move_cursor_right(1)
            end
            {:continue, new_state}

          # Left arrow
          {:ok, ?D} ->
            new_state = State.move_left(state)
            if new_state.cursor != state.cursor do
              Terminal.move_cursor_left(1)
            end
            {:continue, new_state}

          # Delete key sequence
          {:ok, ?3} ->
            case Terminal.read_key(terminal_mode) do
              {:ok, ?~} ->
                new_state = State.delete_char(state)
                Terminal.redraw_line(new_state)
                {:continue, new_state}
              _ ->
                {:continue, state}
            end

          _ ->
            {:continue, state}
        end

      # Alt-b (move word backward)
      {:ok, ?b} ->
        new_state = move_word_backward(state)
        move_count = state.cursor - new_state.cursor
        Terminal.move_cursor_left(move_count)
        {:continue, new_state}

      # Alt-f (move word forward)
      {:ok, ?f} ->
        new_state = move_word_forward(state)
        move_count = new_state.cursor - state.cursor
        Terminal.move_cursor_right(move_count)
        {:continue, new_state}

      # Alt-d (delete word forward)
      {:ok, ?d} ->
        new_state = delete_word_forward(state)
        Terminal.redraw_line(new_state)
        {:continue, new_state}

      _ ->
        {:continue, state}
    end
  end

  defp handle_tab_completion(state) do
    if state.completion_fn && String.starts_with?(state.buffer, "/") do
      # Extract the partial command
      partial = String.slice(state.buffer, 1..-1//1) |> String.split(" ") |> hd()

      case state.completion_fn.(partial) do
        [] ->
          # No completions
          Terminal.bell()
          state

        [single] ->
          # Single completion, complete it
          new_buffer = "/" <> single <> " "
          new_state = %{state | buffer: new_buffer, cursor: String.length(new_buffer)}
          Terminal.redraw_line(new_state)
          new_state

        multiple ->
          # Multiple completions, show them
          IO.write("\n")
          Enum.each(multiple, &IO.write("  /#{&1}\n"))
          IO.write(state.prompt)
          Terminal.redraw_line(state)
          state
      end
    else
      # Not a command or no completion function
      state
    end
  end

  defp kill_word(state) do
    word_start = find_word_boundary_backward(state.buffer, state.cursor)
    {before, rest} = String.split_at(state.buffer, word_start)
    after_ = String.slice(rest, (state.cursor - word_start)..-1//1)
    
    killed = String.slice(rest, 0, state.cursor - word_start)
    new_buffer = before <> after_
    
    new_kill_ring = 
      if killed != "" do
        [killed | state.kill_ring] |> Enum.take(10)
      else
        state.kill_ring
      end
    
    %{state | buffer: new_buffer, cursor: word_start, kill_ring: new_kill_ring}
  end

  defp move_word_backward(state) do
    new_cursor = find_word_boundary_backward(state.buffer, state.cursor)
    %{state | cursor: new_cursor}
  end

  defp move_word_forward(state) do
    new_cursor = find_word_boundary_forward(state.buffer, state.cursor)
    %{state | cursor: new_cursor}
  end

  defp delete_word_forward(state) do
    word_end = find_word_boundary_forward(state.buffer, state.cursor)
    {before, rest} = String.split_at(state.buffer, state.cursor)
    after_ = String.slice(rest, (word_end - state.cursor)..-1//1)
    new_buffer = before <> after_
    %{state | buffer: new_buffer}
  end

  defp find_word_boundary_backward(buffer, pos) do
    chars = String.graphemes(buffer)
    before = Enum.take(chars, pos)

    # Skip non-word chars, then skip word chars
    before
    |> Enum.reverse()
    |> Enum.drop_while(&(!word_char?(&1)))
    |> Enum.drop_while(&word_char?/1)
    |> length()
  end

  defp find_word_boundary_forward(buffer, pos) do
    chars = String.graphemes(buffer)
    after_ = Enum.drop(chars, pos)

    # Skip non-word chars, then skip word chars
    skipped =
      after_
      |> Enum.drop_while(&(!word_char?(&1)))
      |> Enum.drop_while(&word_char?/1)
      |> length()

    pos + (length(after_) - skipped)
  end

  defp word_char?(char) do
    char =~ ~r/[a-zA-Z0-9_]/
  end
end