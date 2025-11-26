defmodule Vs.Team.ColorSchemes do
  @moduledoc """
  Defines the available color schemes for teams.
  """

  @type t :: %{
          id: String.t(),
          primary: String.t(),
          accent: String.t(),
          text: String.t()
        }

  @schemes [
    %{
      id: "cub",
      primary: "#0033a0",
      accent: "#c8102e",
      text: "#ffffff"
    },
    %{
      id: "pirate",
      primary: "#000000",
      accent: "#ffb81c",
      text: "#ffb81c"
    },
    %{
      id: "raider",
      primary: "#000000",
      accent: "#a5acaf",
      text: "#ffffff"
    },
    %{
      id: "packer",
      primary: "#003831",
      accent: "#efb21e",
      text: "#ffffff"
    },
    %{
      id: "bronco",
      primary: "#002d72",
      accent: "#ff5910",
      text: "#ffffff"
    },
    %{
      id: "panther",
      primary: "#000000",
      accent: "#00a3e0",
      text: "#ffffff"
    },
    %{
      id: "laker",
      primary: "#552583",
      accent: "#fdb927",
      text: "#ffffff"
    },
    %{
      id: "yankee",
      primary: "#0c2340",
      accent: "#ffffff",
      text: "#ffffff"
    },
    %{
      id: "cardinal",
      primary: "#c41e3a",
      accent: "#ffffff",
      text: "#ffffff"
    },
    %{
      id: "eagle",
      primary: "#ffffff",
      accent: "#007a33",
      text: "#007a33"
    },
    %{
      id: "bengal",
      primary: "#fd5a1e",
      accent: "#000000",
      text: "#000000"
    },
    %{
      id: "dolphin",
      primary: "#008e97",
      accent: "#fc4c02",
      text: "#ffffff"
    },
    %{
      id: "raven",
      primary: "#241773",
      accent: "#000000",
      text: "#ffffff"
    },
    %{
      id: "bull",
      primary: "#e03a3e",
      accent: "#000000",
      text: "#ffffff"
    },
    %{
      id: "ram",
      primary: "#12284b",
      accent: "#ffc52f",
      text: "#ffffff"
    },
    %{
      id: "commander",
      primary: "#773141",
      accent: "#ffb81c",
      text: "#ffffff"
    },
    %{
      id: "hornet",
      primary: "#00788c",
      accent: "#1d1160",
      text: "#ffffff"
    },
    %{
      id: "patriot",
      primary: "#c8102e",
      accent: "#0c2340",
      text: "#ffffff"
    }
  ]

  def all, do: @schemes

  def get(id) do
    Enum.find(@schemes, fn scheme -> scheme.id == id end)
  end

  def random do
    Enum.random(@schemes)
  end

  def default do
    List.first(@schemes)
  end
end
