defmodule Vs.Plugins.RegistryTest do
  use ExUnit.Case, async: true

  alias Vs.Plugins.Registry

  describe "get_plugin_config/1" do
    test "loads NBA config successfully" do
      assert {:ok, config} = Registry.get_plugin_config("NBA")
      assert config.contest_type == "NBA"
    end

    test "returns error for non-existent contest type" do
      assert {:error, :not_found} = Registry.get_plugin_config("INVALID")
    end

    test "is case-insensitive for contest type" do
      assert {:ok, config1} = Registry.get_plugin_config("NBA")
      assert {:ok, config2} = Registry.get_plugin_config("nba")
      assert {:ok, config3} = Registry.get_plugin_config("Nba")

      assert config1.contest_type == config2.contest_type
      assert config2.contest_type == config3.contest_type
    end
  end

  describe "get_plugin_config!/1" do
    test "returns config map for valid contest type" do
      config = Registry.get_plugin_config!("NBA")
      assert config.contest_type == "NBA"
    end

    test "raises error for non-existent contest type" do
      assert_raise RuntimeError, ~r/Plugin configuration not found/, fn ->
        Registry.get_plugin_config!("INVALID")
      end
    end
  end

  describe "season parsing" do
    test "extracts season information correctly" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      assert config.season.year == 2025
      assert config.season.start_date == ~D[2025-10-15]
      assert config.season.end_date == ~D[2026-04-15]
    end
  end

  describe "periods parsing" do
    test "loads all 26 periods" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      assert length(config.periods) == 26
    end

    test "periods are properly structured" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      first_period = Enum.at(config.periods, 0)
      assert first_period.name == "Week 1"
      assert first_period.sequence == 1
      assert first_period.start_date == ~D[2025-10-15]
      assert first_period.end_date == ~D[2025-10-21]
      assert first_period.is_playoff == false

      last_period = Enum.at(config.periods, 25)
      assert last_period.name == "Week 26"
      assert last_period.sequence == 26
      assert last_period.start_date == ~D[2026-04-08]
      assert last_period.end_date == ~D[2026-04-15]
      assert last_period.is_playoff == false
    end

    test "periods are in sequence order" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      sequences = Enum.map(config.periods, & &1.sequence)
      assert sequences == Enum.to_list(1..26)
    end
  end

  describe "roster positions parsing" do
    test "loads all 9 roster positions" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      assert length(config.roster_positions) == 9
    end

    test "includes all expected positions" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      positions = Enum.map(config.roster_positions, & &1.position)
      assert "PG" in positions
      assert "SG" in positions
      assert "SF" in positions
      assert "PF" in positions
      assert "C" in positions
      assert "G" in positions
      assert "F" in positions
      assert "UT" in positions
      assert "BN" in positions
    end

    test "roster positions are properly structured" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      pg_position = Enum.find(config.roster_positions, &(&1.position == "PG"))
      assert pg_position.count == 1
      assert pg_position.sequence == 1

      ut_position = Enum.find(config.roster_positions, &(&1.position == "UT"))
      assert ut_position.count == 2
      assert ut_position.sequence == 8

      bn_position = Enum.find(config.roster_positions, &(&1.position == "BN"))
      assert bn_position.count == 3
      assert bn_position.sequence == 9
    end

    test "roster positions are in sequence order" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      sequences = Enum.map(config.roster_positions, & &1.sequence)
      assert sequences == Enum.to_list(1..9)
    end
  end

  describe "scoring categories parsing" do
    test "loads all 9 scoring categories" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      assert length(config.scoring_categories) == 9
    end

    test "includes all expected categories" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      category_names = Enum.map(config.scoring_categories, & &1.name)
      assert "PTS" in category_names
      assert "REB" in category_names
      assert "AST" in category_names
      assert "STL" in category_names
      assert "BLK" in category_names
      assert "FG%" in category_names
      assert "FT%" in category_names
      assert "3PM" in category_names
      assert "TO" in category_names
    end

    test "scoring categories are properly structured" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      pts_category = Enum.find(config.scoring_categories, &(&1.name == "PTS"))
      assert pts_category.multiplier == 1.0
      assert pts_category.sequence == 1

      to_category = Enum.find(config.scoring_categories, &(&1.name == "TO"))
      assert to_category.multiplier == -1.0
      assert to_category.sequence == 9
    end

    test "scoring categories are in sequence order" do
      {:ok, config} = Registry.get_plugin_config("NBA")

      sequences = Enum.map(config.scoring_categories, & &1.sequence)
      assert sequences == Enum.to_list(1..9)
    end
  end

  describe "list_available_contest_types/0" do
    test "returns list including NBA" do
      contest_types = Registry.list_available_contest_types()

      assert is_list(contest_types)
      assert "NBA" in contest_types
    end

    test "returns sorted list" do
      contest_types = Registry.list_available_contest_types()

      assert contest_types == Enum.sort(contest_types)
    end
  end

  describe "plugin_exists?/1" do
    test "returns true for existing plugin" do
      assert Registry.plugin_exists?("NBA") == true
    end

    test "returns false for non-existent plugin" do
      assert Registry.plugin_exists?("INVALID") == false
    end

    test "is case-insensitive" do
      assert Registry.plugin_exists?("NBA") == true
      assert Registry.plugin_exists?("nba") == true
      assert Registry.plugin_exists?("Nba") == true
    end
  end
end
