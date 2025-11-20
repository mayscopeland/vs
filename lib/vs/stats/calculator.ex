defmodule Vs.Stats.Calculator do
  @moduledoc """
  Calculates formula-based statistics from observation data.

  Supports simple formulas like:
  - Division: "FGM / FGA"
  - Addition: "OREB + DREB"
  - Subtraction: "FGM - FGA"
  - Multiplication: "PTS * 2"
  """

  @doc """
  Evaluates a formula given a map of stats.

  Returns nil if the formula can't be evaluated (missing stats, division by zero, etc.)

  ## Examples

      iex> calculate("FGM / FGA", %{"FGM" => 10, "FGA" => 20})
      0.5

      iex> calculate("OREB + DREB", %{"OREB" => 5, "DREB" => 10})
      15

      iex> calculate("FGM / FGA", %{"FGM" => 10, "FGA" => 0})
      nil
  """
  def calculate(nil, _stats), do: nil
  def calculate("", _stats), do: nil

  def calculate(formula, stats) when is_binary(formula) and is_map(stats) do
    # Remove extra whitespace and parse the formula
    formula = String.trim(formula)

    cond do
      String.contains?(formula, "/") ->
        calculate_division(formula, stats)

      String.contains?(formula, "+") ->
        calculate_addition(formula, stats)

      String.contains?(formula, "-") ->
        calculate_subtraction(formula, stats)

      String.contains?(formula, "*") ->
        calculate_multiplication(formula, stats)

      true ->
        # Single stat lookup
        Map.get(stats, formula)
    end
  end

  def calculate(_, _), do: nil

  defp calculate_division(formula, stats) do
    case String.split(formula, "/", parts: 2) do
      [left, right] ->
        left_val = get_value(String.trim(left), stats)
        right_val = get_value(String.trim(right), stats)

        case {left_val, right_val} do
          {nil, _} -> nil
          {_, nil} -> nil
          {_, 0} -> nil
          {_l, r} when r == 0.0 -> nil
          {l, r} -> l / r
        end

      _ -> nil
    end
  end

  defp calculate_addition(formula, stats) do
    case String.split(formula, "+", parts: 2) do
      [left, right] ->
        left_val = get_value(String.trim(left), stats)
        right_val = get_value(String.trim(right), stats)

        case {left_val, right_val} do
          {nil, _} -> nil
          {_, nil} -> nil
          {l, r} -> l + r
        end

      _ -> nil
    end
  end

  defp calculate_subtraction(formula, stats) do
    case String.split(formula, "-", parts: 2) do
      [left, right] ->
        left_val = get_value(String.trim(left), stats)
        right_val = get_value(String.trim(right), stats)

        case {left_val, right_val} do
          {nil, _} -> nil
          {_, nil} -> nil
          {l, r} -> l - r
        end

      _ -> nil
    end
  end

  defp calculate_multiplication(formula, stats) do
    case String.split(formula, "*", parts: 2) do
      [left, right] ->
        left_val = get_value(String.trim(left), stats)
        right_val = get_value(String.trim(right), stats)

        case {left_val, right_val} do
          {nil, _} -> nil
          {_, nil} -> nil
          {l, r} -> l * r
        end

      _ -> nil
    end
  end

  defp get_value(key, stats) do
    # Try to parse as a number first, then look up in stats
    case Float.parse(key) do
      {num, ""} -> num
      _ ->
        case Integer.parse(key) do
          {num, ""} -> num
          _ -> Map.get(stats, key)
        end
    end
  end
end
