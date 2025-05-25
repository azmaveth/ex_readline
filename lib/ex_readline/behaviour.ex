defmodule ExReadline.Behaviour do
  @moduledoc """
  Behaviour for readline implementations.

  This behaviour defines the interface that readline implementations must follow.
  """

  @doc """
  Reads a line from the user with the given prompt.
  """
  @callback read_line(prompt :: binary(), opts :: keyword()) :: binary() | :eof

  @doc """
  Adds a line to the history.
  """
  @callback add_to_history(line :: binary()) :: :ok

  @doc """
  Sets the completion function for tab completion.
  """
  @callback set_completion_fn(fun :: (binary() -> [binary()])) :: :ok
end