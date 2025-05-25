defmodule ExReadline.HistoryTest do
  use ExUnit.Case

  alias ExReadline.History

  describe "load/1" do
    test "loads history from file" do
      tmp = Path.join(System.tmp_dir!(), "history_#{:os.system_time()}")
      File.write!(tmp, "command 1\ncommand 2\ncommand 3\n")
      
      history = History.load(tmp)
      assert history == ["command 3", "command 2", "command 1"]
      
      File.rm!(tmp)
    end

    test "returns empty list for non-existent file" do
      history = History.load("/tmp/does_not_exist_#{:os.system_time()}")
      assert history == []
    end

    test "handles empty file" do
      tmp = Path.join(System.tmp_dir!(), "empty_#{:os.system_time()}")
      File.write!(tmp, "")
      
      history = History.load(tmp)
      assert history == []
      
      File.rm!(tmp)
    end
  end

  describe "save/2" do
    test "saves history to file" do
      tmp_dir = Path.join(System.tmp_dir!(), "history_test_#{:os.system_time()}")
      tmp = Path.join(tmp_dir, "history")
      
      history = ["newest", "middle", "oldest"]
      assert :ok = History.save(history, tmp)
      
      assert {:ok, content} = File.read(tmp)
      assert content == "oldest\nmiddle\nnewest\n"
      
      File.rm_rf!(tmp_dir)
    end

    test "creates directory if needed" do
      tmp_dir = Path.join(System.tmp_dir!(), "new_dir_#{:os.system_time()}")
      tmp = Path.join([tmp_dir, "nested", "history"])
      
      assert :ok = History.save(["test"], tmp)
      assert File.exists?(tmp)
      
      File.rm_rf!(tmp_dir)
    end

    test "handles empty history" do
      tmp = Path.join(System.tmp_dir!(), "empty_save_#{:os.system_time()}")
      
      assert :ok = History.save([], tmp)
      assert {:ok, "\n"} = File.read(tmp)
      
      File.rm!(tmp)
    end
  end

  describe "add/3" do
    test "adds new line to history" do
      history = ["old1", "old2"]
      new_history = History.add("new", history, 10)
      assert new_history == ["new", "old1", "old2"]
    end

    test "doesn't add empty lines" do
      history = ["old"]
      new_history = History.add("", history, 10)
      assert new_history == ["old"]
    end

    test "doesn't add duplicate of last entry" do
      history = ["last", "previous"]
      new_history = History.add("last", history, 10)
      assert new_history == ["last", "previous"]
    end

    test "adds duplicate if not last entry" do
      history = ["last", "duplicate", "other"]
      new_history = History.add("duplicate", history, 10)
      assert new_history == ["duplicate", "last", "duplicate", "other"]
    end

    test "respects max size" do
      history = ["1", "2", "3"]
      new_history = History.add("4", history, 3)
      assert new_history == ["4", "1", "2"]
      assert length(new_history) == 3
    end

    test "handles empty history" do
      new_history = History.add("first", [], 10)
      assert new_history == ["first"]
    end
  end

  describe "search/2" do
    setup do
      history = [
        "git commit -m 'fix bug'",
        "ls -la",
        "git status",
        "cd projects",
        "git push origin main"
      ]
      {:ok, history: history}
    end

    test "searches with string pattern", %{history: history} do
      results = History.search(history, "git")
      assert length(results) == 3
      assert {"git commit -m 'fix bug'", 0} in results
      assert {"git status", 2} in results
      assert {"git push origin main", 4} in results
    end

    test "searches with regex pattern", %{history: history} do
      results = History.search(history, ~r/^git/)
      assert length(results) == 3
      
      results = History.search(history, ~r/main$/)
      assert results == [{"git push origin main", 4}]
    end

    test "returns empty list for no matches", %{history: history} do
      assert History.search(history, "npm") == []
      assert History.search(history, ~r/^npm/) == []
    end

    test "handles empty history" do
      assert History.search([], "test") == []
    end
  end
end