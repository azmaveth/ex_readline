defmodule ExReadline.LineEditor.StateTest do
  use ExUnit.Case

  alias ExReadline.LineEditor.State

  describe "new/1" do
    test "creates default state" do
      state = State.new()
      assert state.buffer == ""
      assert state.cursor == 0
      assert state.history == []
      assert state.prompt == "> "
      assert state.saved_line == nil
      assert state.completion_fn == nil
    end

    test "accepts options" do
      history = ["old command"]
      completion = fn _ -> [] end
      
      state = State.new(
        history: history,
        prompt: "$ ",
        completion_fn: completion
      )
      
      assert state.history == history
      assert state.prompt == "$ "
      assert state.completion_fn == completion
      assert state.history_index == 1
    end
  end

  describe "insert_char/2" do
    test "inserts at cursor position" do
      state = %State{buffer: "hllo", cursor: 1}
      new_state = State.insert_char(state, ?e)
      assert new_state.buffer == "hello"
      assert new_state.cursor == 2
    end

    test "inserts at beginning" do
      state = %State{buffer: "ello", cursor: 0}
      new_state = State.insert_char(state, ?h)
      assert new_state.buffer == "hello"
      assert new_state.cursor == 1
    end

    test "inserts at end" do
      state = %State{buffer: "hell", cursor: 4}
      new_state = State.insert_char(state, ?o)
      assert new_state.buffer == "hello"
      assert new_state.cursor == 5
    end
  end

  describe "backspace/1" do
    test "deletes character before cursor" do
      state = %State{buffer: "hello", cursor: 5}
      new_state = State.backspace(state)
      assert new_state.buffer == "hell"
      assert new_state.cursor == 4
    end

    test "does nothing at beginning" do
      state = %State{buffer: "hello", cursor: 0}
      new_state = State.backspace(state)
      assert new_state == state
    end

    test "deletes in middle" do
      state = %State{buffer: "hello", cursor: 3}
      new_state = State.backspace(state)
      assert new_state.buffer == "helo"
      assert new_state.cursor == 2
    end
  end

  describe "delete_char/1" do
    test "deletes character at cursor" do
      state = %State{buffer: "hello", cursor: 0}
      new_state = State.delete_char(state)
      assert new_state.buffer == "ello"
      assert new_state.cursor == 0
    end

    test "does nothing at end" do
      state = %State{buffer: "hello", cursor: 5}
      new_state = State.delete_char(state)
      assert new_state == state
    end
  end

  describe "movement functions" do
    test "move_left/1" do
      state = %State{buffer: "hello", cursor: 3}
      new_state = State.move_left(state)
      assert new_state.cursor == 2
      
      # At beginning
      state = %State{buffer: "hello", cursor: 0}
      assert State.move_left(state) == state
    end

    test "move_right/1" do
      state = %State{buffer: "hello", cursor: 3}
      new_state = State.move_right(state)
      assert new_state.cursor == 4
      
      # At end
      state = %State{buffer: "hello", cursor: 5}
      assert State.move_right(state) == state
    end

    test "move_to_start/1" do
      state = %State{buffer: "hello", cursor: 3}
      new_state = State.move_to_start(state)
      assert new_state.cursor == 0
    end

    test "move_to_end/1" do
      state = %State{buffer: "hello", cursor: 2}
      new_state = State.move_to_end(state)
      assert new_state.cursor == 5
    end
  end

  describe "kill functions" do
    test "kill_to_end/1" do
      state = %State{buffer: "hello world", cursor: 5, kill_ring: []}
      new_state = State.kill_to_end(state)
      assert new_state.buffer == "hello"
      assert new_state.kill_ring == [" world"]
    end

    test "kill_to_start/1" do
      state = %State{buffer: "hello world", cursor: 6, kill_ring: []}
      new_state = State.kill_to_start(state)
      assert new_state.buffer == "world"
      assert new_state.cursor == 0
      assert new_state.kill_ring == ["hello "]
    end

    test "kill ring is limited to 10 entries" do
      state = %State{buffer: "test", cursor: 2, kill_ring: Enum.map(1..10, &"kill#{&1}")}
      new_state = State.kill_to_end(state)
      assert length(new_state.kill_ring) == 10
      assert hd(new_state.kill_ring) == "st"  # Killed text from cursor
    end
  end

  describe "history navigation" do
    setup do
      history = ["third", "second", "first"]
      state = %State{
        buffer: "current",
        cursor: 7,
        history: history,
        history_index: 3,
        saved_line: nil
      }
      {:ok, state: state}
    end

    test "history_prev/1 moves to previous entry", %{state: state} do
      new_state = State.history_prev(state)
      assert new_state.buffer == "first"  # History is newest-first, so index 2 is "first"
      assert new_state.history_index == 2
      assert new_state.saved_line == "current"
      assert new_state.cursor == 5
    end

    test "history_prev/1 continues through history", %{state: state} do
      new_state = state
      |> State.history_prev()
      |> State.history_prev()
      
      assert new_state.buffer == "second"
      assert new_state.history_index == 1
    end

    test "history_prev/1 stops at beginning", %{state: state} do
      new_state = %{state | history_index: 0}
      assert State.history_prev(new_state) == new_state
    end

    test "history_next/1 moves to next entry", %{state: state} do
      # First go back in history
      state = %{state | history_index: 1, buffer: "second", saved_line: "current"}
      
      new_state = State.history_next(state)
      assert new_state.buffer == "first"  # History is newest-first
      assert new_state.history_index == 2
    end

    test "history_next/1 restores saved line at end", %{state: state} do
      # Go back then forward to end
      state = %{state | history_index: 2, buffer: "third", saved_line: "my input"}
      
      new_state = State.history_next(state)
      assert new_state.buffer == "my input"
      assert new_state.history_index == 3
    end

    test "history_next/1 stops at end", %{state: state} do
      assert State.history_next(state) == state
    end
  end
end