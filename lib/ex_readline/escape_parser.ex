defmodule ExReadline.EscapeParser do
  @moduledoc """
  Parser for ANSI escape sequences when terminal raw mode is not available.
  
  This module handles parsing of escape sequences from standard input
  when we can't use direct terminal control (e.g., in some escript environments).
  """
  
  alias ExReadline.Terminal
  
  @doc """
  Reads and parses an escape sequence, returning the equivalent key code.
  
  This function is called when we receive an escape character (27) and need
  to determine what key was actually pressed by reading the following characters.
  """
  @spec parse_escape_sequence(term()) :: {:ok, :up | :down | :left | :right | :home | :end | :delete | {:alt, byte()} | :unknown} | {:error, term()}
  def parse_escape_sequence(terminal_mode) do
    case Terminal.read_key(terminal_mode) do
      {:ok, ?[} ->
        parse_csi_sequence(terminal_mode)
      {:ok, key} ->
        # Alt + key combination
        {:ok, {:alt, key}}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Parse Control Sequence Introducer (CSI) sequences like \e[A
  defp parse_csi_sequence(terminal_mode) do
    case Terminal.read_key(terminal_mode) do
      {:ok, ?A} -> {:ok, :up}
      {:ok, ?B} -> {:ok, :down}
      {:ok, ?C} -> {:ok, :right}
      {:ok, ?D} -> {:ok, :left}
      {:ok, ?H} -> {:ok, :home}
      {:ok, ?F} -> {:ok, :end}
      {:ok, ?1} ->
        # Could be Home (\e[1~) or other sequences
        parse_extended_sequence(terminal_mode, ?1)
      {:ok, ?3} ->
        # Could be Delete (\e[3~)
        parse_extended_sequence(terminal_mode, ?3)
      {:ok, ?4} ->
        # Could be End (\e[4~)
        parse_extended_sequence(terminal_mode, ?4)
      {:ok, _other} ->
        # Unknown sequence, consume any remaining characters
        {:ok, :unknown}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Parse extended sequences that end with ~
  defp parse_extended_sequence(terminal_mode, first_char) do
    case Terminal.read_key(terminal_mode) do
      {:ok, ?~} ->
        case first_char do
          ?1 -> {:ok, :home}
          ?3 -> {:ok, :delete}
          ?4 -> {:ok, :end}
          _ -> {:ok, :unknown}
        end
      {:ok, _} ->
        # Multi-character sequence, just mark as unknown
        {:ok, :unknown}
      {:error, reason} ->
        {:error, reason}
    end
  end
end