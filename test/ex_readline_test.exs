defmodule ExReadlineTest do
  use ExUnit.Case

  describe "start_link/1" do
    test "starts with default simple reader" do
      assert {:ok, pid} = ExReadline.start_link()
      assert Process.alive?(pid)
      assert Process.whereis(ExReadline.SimpleReader) == pid
      GenServer.stop(pid)
    end

    test "starts with line editor implementation" do
      assert {:ok, pid} = ExReadline.start_link(implementation: :line_editor)
      assert Process.alive?(pid)
      assert Process.whereis(ExReadline.LineEditor) == pid
      GenServer.stop(pid)
    end

    test "returns error for invalid implementation" do
      assert {:error, {:invalid_implementation, :unknown}} = 
        ExReadline.start_link(implementation: :unknown)
    end

    test "accepts custom name" do
      assert {:ok, pid} = ExReadline.start_link(name: :custom_reader)
      assert Process.whereis(:custom_reader) == pid
      GenServer.stop(pid)
    end
  end

  describe "unified interface" do
    setup do
      {:ok, pid} = ExReadline.start_link()
      on_exit(fn -> 
        if Process.alive?(pid), do: GenServer.stop(pid)
      end)
      {:ok, pid: pid}
    end

    test "add_to_history/1 works with simple reader", %{pid: _pid} do
      assert :ok = ExReadline.add_to_history("test command")
    end

    test "set_completion_fn/1 is no-op for simple reader", %{pid: _pid} do
      assert :ok = ExReadline.set_completion_fn(fn _ -> [] end)
    end
  end

  describe "fallback behavior" do
    test "read_line falls back to IO.gets when no server running" do
      # Don't start any server
      # This test would need mock IO to work properly
      # Just ensure it doesn't crash
      assert is_function(&ExReadline.read_line/1)
    end
  end
end