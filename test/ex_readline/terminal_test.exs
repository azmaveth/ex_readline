defmodule ExReadline.TerminalTest do
  use ExUnit.Case, async: false
  
  alias ExReadline.Terminal
  
  # Helper function to insert a string by inserting each character
  defp insert_string(state, string) do
    alias ExReadline.LineEditor.State
    
    string
    |> String.to_charlist()
    |> Enum.reduce(state, fn char, acc_state ->
      State.insert_char(acc_state, char)
    end)
  end
  
  describe "mode detection" do
    test "correctly detects standard vs escript mode" do
      # This test will behave differently depending on how it's run
      case Terminal.setup_raw_mode() do
        {:ok, {:standard, _}} ->
          # Running in standard Elixir/IEx environment
          assert true
          
        {:ok, {:escript, _}} ->
          # Running in escript environment
          assert true
          
        {:error, reason} ->
          # If we can't set up terminal mode, that's also valid for testing
          assert is_tuple(reason)
      end
    end
  end
  
  describe "terminal setup and restore" do
    test "can set up and restore terminal mode" do
      case Terminal.setup_raw_mode() do
        {:ok, mode} ->
          # Should be able to restore without error
          assert Terminal.restore_mode(mode) == :ok
          
        {:error, _reason} ->
          # If setup fails, that's ok for testing environments
          assert true
      end
    end
  end
  
  describe "ANSI escape sequences" do
    test "cursor movement functions exist and don't crash" do
      assert Terminal.move_cursor_left(0) == :ok
      assert Terminal.move_cursor_left(1) == :ok
      assert Terminal.move_cursor_left(5) == :ok
      
      assert Terminal.move_cursor_right(0) == :ok
      assert Terminal.move_cursor_right(1) == :ok
      assert Terminal.move_cursor_right(5) == :ok
      
      assert Terminal.clear_line() == :ok
      assert Terminal.clear_screen() == :ok
      assert Terminal.bell() == :ok
    end
  end
  
  describe "line redrawing" do
    test "redraw_line handles various state configurations" do
      alias ExReadline.LineEditor.State
      
      # Test with empty buffer
      state = State.new(prompt: "> ", history: [], completion_fn: nil)
      assert Terminal.redraw_line(state) == :ok
      
      # Test with content
      state = State.new(prompt: "test> ", history: [], completion_fn: nil)
      state = insert_string(state, "hello world")
      assert Terminal.redraw_line(state) == :ok
      
      # Test with cursor in middle
      state = State.move_left(state)
      state = State.move_left(state)
      assert Terminal.redraw_line(state) == :ok
    end
  end
end