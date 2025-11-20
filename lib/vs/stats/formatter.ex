defmodule Vs.Stats.Formatter do
  @moduledoc """
  Formats statistical values according to their format specification.

  Supported formats:
  - "integer" - Round to integer (default)
  - "percentage_N" - Display as percentage with N decimal places (e.g., "percentage_1" -> "56.7%")
  - "decimal_N" - Display as decimal with N decimal places (e.g., "decimal_3" -> "0.567")
  """

  @doc """
  Formats a value according to the format specification.

  Returns nil if value is nil.

  ## Examples

      iex> format(123.456, "integer")
      "123"

      iex> format(0.567, "percentage_1")
      "56.7%"

      iex> format(0.56789, "decimal_3")
      "0.568"

      iex> format(nil, "integer")
      nil
  """
  def format(nil, _format), do: nil

  def format(value, format) when is_number(value) do
    case parse_format(format) do
      {:integer} ->
        value |> round() |> to_string()

      {:percentage, precision} ->
        percentage = value * 100
        "#{Float.round(percentage, precision)}%"

      {:decimal, precision} ->
        Float.round(value, precision) |> to_string()

      _ ->
        # Default to integer
        value |> round() |> to_string()
    end
  end

  def format(value, _format) when is_binary(value), do: value
  def format(value, _format), do: to_string(value)

  defp parse_format(nil), do: {:integer}
  defp parse_format("integer"), do: {:integer}

  defp parse_format("percentage_" <> precision_str) do
    case Integer.parse(precision_str) do
      {precision, ""} -> {:percentage, precision}
      _ -> {:integer}
    end
  end

  defp parse_format("decimal_" <> precision_str) do
    case Integer.parse(precision_str) do
      {precision, ""} -> {:decimal, precision}
      _ -> {:integer}
    end
  end

  defp parse_format(_), do: {:integer}
end
