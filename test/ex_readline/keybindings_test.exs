defmodule ExReadline.KeybindingsTest do
  use ExUnit.Case, async: true
  
  alias ExReadline.{Keybindings, LineEditor.State}
  
  # Create a mock terminal mode for testing
  @mock_terminal_mode {:test_mode, nil}
  
  # Helper function to insert a string by inserting each character
  defp insert_string(state, string) do
    string
    |> String.to_charlist()
    |> Enum.reduce(state, fn char, acc_state ->
      State.insert_char(acc_state, char)
    end)
  end
  
  # Helper function to move cursor to a specific position
  defp move_to_position(state, position) do
    cond do
      position < state.cursor ->
        # Move left
        Enum.reduce(1..(state.cursor - position), state, fn _, acc_state ->
          State.move_left(acc_state)
        end)
      position > state.cursor ->
        # Move right
        Enum.reduce(1..(position - state.cursor), state, fn _, acc_state ->
          State.move_right(acc_state)
        end)
      true ->
        state
    end
  end
  
  describe "basic key handling" do
    test "enter key completes input" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      state = insert_string(state, "test input")
      
      assert {:done, {:ok, "test input"}} = Keybindings.handle_key(13, state, @mock_terminal_mode)
    end
    
    test "ctrl-c interrupts input" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      
      assert {:done, {:error, :interrupted}} = Keybindings.handle_key(3, state, @mock_terminal_mode)
    end
    
    test "printable characters are inserted" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      
      assert {:continue, new_state} = Keybindings.handle_key(?a, state, @mock_terminal_mode)
      assert new_state.buffer == "a"
      assert new_state.cursor == 1
      
      assert {:continue, new_state} = Keybindings.handle_key(?b, new_state, @mock_terminal_mode)
      assert new_state.buffer == "ab"
      assert new_state.cursor == 2
    end
    
    test "backspace removes characters" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      state = insert_string(state, "hello")
      
      assert {:continue, new_state} = Keybindings.handle_key(127, state, @mock_terminal_mode)
      assert new_state.buffer == "hell"
      assert new_state.cursor == 4
    end
  end
  
  describe "cursor movement" do
    test "ctrl-a moves to beginning" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      state = insert_string(state, "hello world")
      
      assert {:continue, new_state} = Keybindings.handle_key(1, state, @mock_terminal_mode)  # Ctrl-A
      assert new_state.cursor == 0
      assert new_state.buffer == "hello world"
    end
    
    test "ctrl-e moves to end" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      state = insert_string(state, "hello world")
      state = State.move_to_start(state)
      
      assert {:continue, new_state} = Keybindings.handle_key(5, state, @mock_terminal_mode)  # Ctrl-E
      assert new_state.cursor == String.length("hello world")
      assert new_state.buffer == "hello world"
    end
    
    test "ctrl-b moves backward" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      state = insert_string(state, "hello")
      
      assert {:continue, new_state} = Keybindings.handle_key(2, state, @mock_terminal_mode)  # Ctrl-B
      assert new_state.cursor == 4
    end
    
    test "ctrl-f moves forward" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      state = insert_string(state, "hello")
      state = State.move_left(state)
      
      assert {:continue, new_state} = Keybindings.handle_key(6, state, @mock_terminal_mode)  # Ctrl-F
      assert new_state.cursor == 5
    end
  end
  
  describe "line editing" do
    test "ctrl-k kills to end of line" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      state = insert_string(state, "hello world")
      state = move_to_position(state, 5)  # Position after "hello"
      
      assert {:continue, new_state} = Keybindings.handle_key(11, state, @mock_terminal_mode)  # Ctrl-K
      assert new_state.buffer == "hello"
      assert new_state.cursor == 5
    end
    
    test "ctrl-u kills to beginning of line" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      state = insert_string(state, "hello world")
      state = move_to_position(state, 6)  # Position at space
      
      assert {:continue, new_state} = Keybindings.handle_key(21, state, @mock_terminal_mode)  # Ctrl-U
      assert new_state.buffer == "world"
      assert new_state.cursor == 0
    end
    
    test "ctrl-d deletes character or signals EOF" do
      # Delete character when buffer has content
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      state = insert_string(state, "hello")
      state = State.move_left(state)  # Move cursor before 'o'
      
      assert {:continue, new_state} = Keybindings.handle_key(4, state, @mock_terminal_mode)  # Ctrl-D
      assert new_state.buffer == "hell"
      
      # Signal EOF when buffer is empty
      empty_state = State.new(prompt: "> ", history: [], completion_fn: nil)
      assert {:done, {:error, :interrupted}} = Keybindings.handle_key(4, empty_state, @mock_terminal_mode)
    end
  end
  
  describe "history navigation" do
    test "ctrl-p navigates to previous history" do
      history = ["first", "second", "third"]
      state = State.new(prompt: "> ", history: history, completion_fn: nil)
      
      assert {:continue, new_state} = Keybindings.handle_key(16, state, @mock_terminal_mode)  # Ctrl-P
      assert new_state.buffer == "third"
      
      assert {:continue, new_state2} = Keybindings.handle_key(16, new_state, @mock_terminal_mode)
      assert new_state2.buffer == "second"
    end
    
    test "ctrl-n navigates to next history" do
      history = ["first", "second", "third"]
      state = State.new(prompt: "> ", history: history, completion_fn: nil)
      
      # Go back twice
      {:continue, state} = Keybindings.handle_key(16, state, @mock_terminal_mode)  # Ctrl-P
      {:continue, state} = Keybindings.handle_key(16, state, @mock_terminal_mode)  # Ctrl-P
      assert state.buffer == "second"
      
      # Go forward once
      assert {:continue, new_state} = Keybindings.handle_key(14, state, @mock_terminal_mode)  # Ctrl-N
      assert new_state.buffer == "third"
    end
  end
  
  describe "special keys" do
    test "ctrl-l clears screen and redraws" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      state = insert_string(state, "test")
      
      assert {:continue, new_state} = Keybindings.handle_key(12, state, @mock_terminal_mode)  # Ctrl-L
      assert new_state.buffer == "test"  # Buffer should remain unchanged
    end
    
    test "unknown keys are ignored" do
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      
      # Test with non-printable character
      assert {:continue, _new_state} = Keybindings.handle_key(1, state, @mock_terminal_mode)
      
      # Test with out-of-range character
      assert {:continue, _new_state} = Keybindings.handle_key(200, state, @mock_terminal_mode)
    end
  end
end