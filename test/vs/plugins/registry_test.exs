defmodule Vs.Plugins.RegistryTest do
  use ExUnit.Case, async: true
  alias Vs.Plugins.Registry

  describe "get_plugin_config/2" do
    test "loads NBA 2025 config successfully" do
      assert {:ok, config} = Registry.get_plugin_config("NBA", 2025)
      assert config.contest_type == "NBA"
      assert config.season.year == 2025
    end

    test "returns error for non-existent contest type" do
      assert {:error, :not_found} = Registry.get_plugin_config("INVALID", 2025)
    end
  end

  describe "plugin_exists?/2" do
    test "returns true for existing plugin" do
      assert Registry.plugin_exists?("NBA", 2025)
    end

    test "returns false for non-existent plugin" do
      refute Registry.plugin_exists?("INVALID", 2025)
    end
  end

  describe "list_available_contest_types/0" do
    test "returns list including NBA 2025" do
      types = Registry.list_available_contest_types()
      assert {"NBA", 2025} in types
    end
  end
end
