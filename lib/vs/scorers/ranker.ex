defmodule Vs.Scorers.Ranker do
  @moduledoc """
  Calculates ranks for scorers based on league scoring settings.
  """

  alias Vs.{Repo, Scorer, Players, Seasons}

  def calculate_ranks(season) do
    season = Repo.preload(season, :league)
    scorers = Players.list_players_for_league(season.league_id)
    scoring_categories = Seasons.get_active_scoring_categories(season)

    # Determine scoring type
    scoring_type = season.scoring_type || "points"

    # We need to calculate ranks for each "stat key" (e.g. "2025", "2024", "projection")
    # Collect all unique keys from all scorers' stats
    stat_keys =
      scorers
      |> Enum.flat_map(fn s -> Map.keys(s.stats || %{}) end)
      |> Enum.uniq()

    # For each key, calculate ranks
    updates =
      Enum.reduce(stat_keys, %{}, fn key, acc ->
        ranked_scorers =
          case scoring_type do
            "roto" -> calculate_roto_ranks(scorers, key, scoring_categories)
            _ -> calculate_points_ranks(scorers, key, scoring_categories)
          end

        # Merge into accumulator: %{scorer_id => %{key => rank}}
        Enum.reduce(ranked_scorers, acc, fn {scorer_id, rank}, inner_acc ->
          current_ranks = Map.get(inner_acc, scorer_id, %{})
          Map.put(inner_acc, scorer_id, Map.put(current_ranks, key, rank))
        end)
      end)

    # Bulk update scorers
    Enum.each(updates, fn {scorer_id, new_ranks} ->
      scorer = Repo.get(Scorer, scorer_id)
      updated_ranks = Map.merge(scorer.rank || %{}, new_ranks)

      scorer
      |> Scorer.changeset(%{rank: updated_ranks})
      |> Repo.update()
    end)
  end

  defp calculate_points_ranks(scorers, key, categories) do
    scorers
    |> Enum.map(fn scorer ->
      stats = Map.get(scorer.stats, key)
      points = calculate_fantasy_points(stats, categories)
      {scorer.id, points}
    end)
    |> sort_and_rank()
  end

  defp calculate_fantasy_points(nil, _), do: 0.0

  defp calculate_fantasy_points(stats, categories) do
    Enum.reduce(categories, 0.0, fn cat, total ->
      val = Map.get(stats, cat.name) || 0
      # Handle string values if any? Stats should be numbers.
      val = to_number(val)
      weight = cat.multiplier || 0
      total + val * weight
    end)
  end

  defp calculate_roto_ranks(scorers, key, categories) do
    # Let's separate categories into counting and rate
    {rate_cats, _counting_cats} =
      Enum.split_with(categories, fn cat ->
        Map.get(cat, :formula) && String.contains?(cat.formula, "/")
      end)

    # Calculate league averages for rate stats
    league_averages =
      Enum.map(rate_cats, fn cat ->
        {numerator_formula, denominator_formula} = parse_rate_formula(cat.formula)

        total_num = sum_formula(scorers, key, numerator_formula)
        total_denom = sum_formula(scorers, key, denominator_formula)

        avg_rate = if total_denom == 0, do: 0, else: total_num / total_denom
        {cat.name, {numerator_formula, denominator_formula, avg_rate}}
      end)
      |> Map.new()

    # Let's compute the "value" for every player for every category
    scorer_values =
      Enum.map(scorers, fn scorer ->
        stats = Map.get(scorer.stats, key) || %{}

        cat_values =
          Enum.map(categories, fn cat ->
            val =
              if Map.has_key?(league_averages, cat.name) do
                # Rate stat logic
                {num_form, denom_form, avg_rate} = league_averages[cat.name]
                num = evaluate_formula(num_form, stats)
                denom = evaluate_formula(denom_form, stats)
                num - avg_rate * denom
              else
                # Counting stat
                to_number(Map.get(stats, cat.name) || 0)
              end

            {cat.name, val}
          end)
          |> Map.new()

        {scorer.id, cat_values}
      end)

    # Calculate Mean and StdDev for each category based on `scorer_values`
    cat_stats =
      Enum.map(categories, fn cat ->
        values = Enum.map(scorer_values, fn {_, vals} -> vals[cat.name] end)
        mean = Statistics.mean(values)
        std_dev = Statistics.stdev(values)
        {cat.name, {mean, std_dev}}
      end)
      |> Map.new()

    # Calculate total Z-score for each scorer
    scorers
    |> Enum.map(fn scorer ->
      {_, values} = Enum.find(scorer_values, fn {id, _} -> id == scorer.id end)

      total_z =
        Enum.reduce(categories, 0.0, fn cat, acc ->
          val = values[cat.name]
          {mean, std_dev} = cat_stats[cat.name]

          z = if std_dev == 0, do: 0, else: (val - mean) / std_dev

          # Flip for negative categories (like TOV)
          # We check the multiplier from settings
          z = if (cat.multiplier || 1) < 0, do: -z, else: z

          acc + z
        end)

      {scorer.id, total_z}
    end)
    |> sort_and_rank()
  end

  defp sum_formula(scorers, key, formula) do
    Enum.reduce(scorers, 0.0, fn s, acc ->
      stats = Map.get(s.stats, key) || %{}
      acc + evaluate_formula(formula, stats)
    end)
  end

  defp parse_rate_formula(formula) do
    # Assumes format "NUMERATOR / DENOMINATOR"
    # We split by the *last* slash that isn't inside parentheses, but for now,
    # let's assume the top-level division is the split point.
    # A simple split on " / " might be safer if we enforce spaces, but let's try to be robust.
    # For now, we'll just split on the first "/" found.
    # TODO: Make this more robust for nested divisions if needed.
    case String.split(formula, "/", parts: 2) do
      [num, denom] -> {String.trim(num), String.trim(denom)}
      _ -> {"0", "1"}
    end
  end

  defp evaluate_formula(formula, stats) do
    # 1. Replace variables with values
    # We need to be careful not to replace substrings of other variables.
    # We can use a regex to find words and replace them if they are in stats.

    # This is a simple evaluator. For production, consider a proper parser.
    # We will support +, -, *, /, (, ) and numbers/variables.

    try do
      {result, _} = Code.eval_string(sanitize_and_inject(formula, stats))
      to_number(result)
    rescue
      _ -> 0.0
    end
  end

  defp sanitize_and_inject(formula, stats) do
    # This is a "quick and dirty" evaluator using Code.eval_string but attempting to be safe
    # by only allowing known keys and math operators.

    # 1. Identify all potential variable names (alphanumeric + underscores)
    Regex.replace(~r/[a-zA-Z0-9_%]+/, formula, fn match ->
      # If it looks like a number, leave it
      if Regex.match?(~r/^[0-9]+(\.[0-9]+)?$/, match) do
        match
      else
        # It's a variable. Look it up.
        val = Map.get(stats, match) || 0
        to_string(to_number(val))
      end
    end)
  end

  defp to_number(val) when is_binary(val) do
    case Float.parse(val) do
      {num, _} -> num
      :error -> 0.0
    end
  end

  defp to_number(val) when is_number(val), do: val
  defp to_number(_), do: 0.0

  defp sort_and_rank(scorer_scores) do
    scorer_scores
    |> Enum.sort_by(fn {_, score} -> score end, :desc)
    |> Enum.with_index(1)
    |> Enum.map(fn {{id, _score}, rank} -> {id, rank} end)
  end
end

defmodule Statistics do
  def mean([]), do: 0.0
  def mean(list), do: Enum.sum(list) / length(list)

  def stdev([]), do: 0.0

  def stdev(list) do
    avg = mean(list)

    variance =
      list
      |> Enum.map(fn x -> :math.pow(x - avg, 2) end)
      |> Enum.sum()
      |> Kernel./(length(list))

    :math.sqrt(variance)
  end
end
