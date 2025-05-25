defmodule ExReadline.History do
  @moduledoc """
  History management for readline implementations.

  This module handles loading, saving, and managing command history.
  """

  require Logger

  @doc """
  Loads history from a file.

  Returns a list of history entries with newest first.
  """
  @spec load(binary()) :: [binary()]
  def load(path) do
    case File.read(path) do
      {:ok, content} ->
        content
        |> String.split("\n", trim: true)
        |> Enum.reverse()

      {:error, _} ->
        []
    end
  end

  @doc """
  Saves history to a file.

  The history list should have newest entries first.
  """
  @spec save([binary()], binary()) :: :ok | {:error, term()}
  def save(history, path) do
    dir = Path.dirname(path)

    # Ensure directory exists
    with :ok <- File.mkdir_p(dir) do
      # Write history (newest first in file)
      content =
        history
        |> Enum.reverse()
        |> Enum.join("\n")

      case File.write(path, content <> "\n") do
        :ok -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  rescue
    e ->
      Logger.warning("Failed to save history: #{Exception.message(e)}")
      {:error, e}
  end

  @doc """
  Adds a line to history, avoiding duplicates of the last entry.

  Returns the updated history list.
  """
  @spec add(binary(), [binary()], non_neg_integer()) :: [binary()]
  def add(line, history, max_size) do
    # Don't add empty lines
    if line == "" do
      history
    else
      # Don't add duplicates of the last entry
      if history == [] or hd(history) != line do
        [line | history]
        |> Enum.take(max_size)
      else
        history
      end
    end
  end

  @doc """
  Searches history for entries matching a pattern.

  Returns matching entries with their indices.
  """
  @spec search([binary()], binary() | Regex.t()) :: [{non_neg_integer(), binary()}]
  def search(history, pattern) when is_binary(pattern) do
    history
    |> Enum.with_index()
    |> Enum.filter(fn {line, _index} ->
      String.contains?(line, pattern)
    end)
  end

  def search(history, %Regex{} = pattern) do
    history
    |> Enum.with_index()
    |> Enum.filter(fn {line, _index} ->
      String.match?(line, pattern)
    end)
  end
end