defmodule ExReadline.SimpleReaderTest do
  use ExUnit.Case

  alias ExReadline.SimpleReader

  setup do
    # Create temp directory for history
    tmp_dir = System.tmp_dir!()
    test_dir = Path.join(tmp_dir, "ex_readline_test_#{:os.system_time(:nanosecond)}")
    File.mkdir_p!(test_dir)
    history_file = Path.join(test_dir, "history")

    {:ok, pid} = SimpleReader.start_link(
      history_file: history_file,
      name: :"test_reader_#{:os.system_time()}"
    )

    on_exit(fn ->
      if Process.alive?(pid), do: GenServer.stop(pid)
      File.rm_rf!(test_dir)
    end)

    {:ok, pid: pid, history_file: history_file}
  end

  describe "start_link/1" do
    test "starts with custom history file" do
      tmp = Path.join(System.tmp_dir!(), "custom_history_#{:os.system_time()}")
      {:ok, pid} = SimpleReader.start_link(history_file: tmp, name: :custom_simple)
      assert Process.alive?(pid)
      GenServer.stop(pid)
      File.rm_rf!(tmp)
    end

    test "starts without history persistence" do
      {:ok, pid} = SimpleReader.start_link(history_file: nil, name: :no_history)
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end

  describe "add_to_history/1" do
    test "adds lines to history", %{pid: pid, history_file: history_file} do
      GenServer.cast(pid, {:add_to_history, "first command"})
      GenServer.cast(pid, {:add_to_history, "second command"})
      
      # Give it time to save
      Process.sleep(100)
      
      # Check history was saved
      assert {:ok, content} = File.read(history_file)
      assert content =~ "first command"
      assert content =~ "second command"
    end

    test "doesn't add duplicate consecutive entries", %{pid: pid} do
      GenServer.cast(pid, {:add_to_history, "same command"})
      GenServer.cast(pid, {:add_to_history, "same command"})
      GenServer.cast(pid, {:add_to_history, "different"})
      GenServer.cast(pid, {:add_to_history, "different"})
      
      # Give it time to process
      Process.sleep(50)
      
      # Check internal state
      state = :sys.get_state(pid)
      assert length(state.history) == 2
    end

    test "respects max history size" do
      # Start new reader with small history
      {:ok, pid} = SimpleReader.start_link(
        max_history_size: 3,
        history_file: nil,
        name: :small_history
      )
      
      # Add more than max
      GenServer.cast(pid, {:add_to_history, "1"})
      GenServer.cast(pid, {:add_to_history, "2"})
      GenServer.cast(pid, {:add_to_history, "3"})
      GenServer.cast(pid, {:add_to_history, "4"})
      GenServer.cast(pid, {:add_to_history, "5"})
      
      Process.sleep(50)
      
      state = :sys.get_state(pid)
      assert length(state.history) == 3
      assert hd(state.history) == "5"
      
      GenServer.stop(pid)
    end
  end

  describe "set_completion_fn/1" do
    test "is a no-op for simple reader" do
      assert :ok = SimpleReader.set_completion_fn(fn _ -> ["test"] end)
    end
  end

  describe "history persistence" do
    test "loads existing history on start" do
      tmp = Path.join(System.tmp_dir!(), "preexisting_#{:os.system_time()}")
      dir = Path.dirname(tmp)
      File.mkdir_p!(dir)
      
      # Create history file
      File.write!(tmp, "old command 1\nold command 2\n")
      
      # Start reader
      {:ok, pid} = SimpleReader.start_link(history_file: tmp, name: :with_history)
      
      # Check it loaded the history
      state = :sys.get_state(pid)
      assert "old command 2" in state.history
      assert "old command 1" in state.history
      
      GenServer.stop(pid)
      File.rm!(tmp)
    end
  end
end