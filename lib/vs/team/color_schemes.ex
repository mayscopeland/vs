defmodule Vs.Team.ColorSchemes do
  @moduledoc """
  Defines the available color schemes for teams.
  """

  @type t :: %{
          id: String.t(),
          name: String.t(),
          primary: String.t(),
          accent: String.t(),
          text: String.t()
        }

  @schemes [
    %{
      id: "arizona-diamondbacks",
      name: "Arizona Diamondbacks",
      primary: "#a71930",
      accent: "#000000",
      text: "#ffffff"
    },
    %{
      id: "atlanta-braves",
      name: "Atlanta Braves",
      primary: "#13274f",
      accent: "#ce1141",
      text: "#ffffff"
    },
    %{
      id: "baltimore-orioles",
      name: "Baltimore Orioles",
      primary: "#df4601",
      accent: "#000000",
      text: "#000000"
    },
    %{
      id: "boston-red-sox",
      name: "Boston Red Sox",
      primary: "#bd3039",
      accent: "#0c2340",
      text: "#ffffff"
    },
    %{
      id: "chicago-cubs",
      name: "Chicago Cubs",
      primary: "#0e3386",
      accent: "#cc3433",
      text: "#ffffff"
    },
    %{
      id: "chicago-white-sox",
      name: "Chicago White Sox",
      primary: "#27251f",
      accent: "#c4ced4",
      text: "#ffffff"
    },
    %{
      id: "cincinnati-reds",
      name: "Cincinnati Reds",
      primary: "#c6011f",
      accent: "#000000",
      text: "#ffffff"
    },
    %{
      id: "cleveland-guardians",
      name: "Cleveland Guardians",
      primary: "#00385d",
      accent: "#e50022",
      text: "#ffffff"
    },
    %{
      id: "colorado-rockies",
      name: "Colorado Rockies",
      primary: "#333366",
      accent: "#c4ced4",
      text: "#ffffff"
    },
    %{
      id: "detroit-tigers",
      name: "Detroit Tigers",
      primary: "#0c2340",
      accent: "#fa4616",
      text: "#ffffff"
    },
    %{
      id: "houston-astros",
      name: "Houston Astros",
      primary: "#002d62",
      accent: "#eb6e1f",
      text: "#ffffff"
    },
    %{
      id: "kansas-city-royals",
      name: "Kansas City Royals",
      primary: "#004687",
      accent: "#bd9b60",
      text: "#ffffff"
    },
    %{
      id: "los-angeles-angels",
      name: "Los Angeles Angels",
      primary: "#003263",
      accent: "#ba0021",
      text: "#ffffff"
    },
    %{
      id: "los-angeles-dodgers",
      name: "Los Angeles Dodgers",
      primary: "#005a9c",
      accent: "#a5acaf",
      text: "#ffffff"
    },
    %{
      id: "miami-marlins",
      name: "Miami Marlins",
      primary: "#000000",
      accent: "#00a3e0",
      text: "#ffffff"
    },
    %{
      id: "milwaukee-brewers",
      name: "Milwaukee Brewers",
      primary: "#12284b",
      accent: "#ffc52f",
      text: "#ffffff"
    },
    %{
      id: "minnesota-twins",
      name: "Minnesota Twins",
      primary: "#002b5c",
      accent: "#d31145",
      text: "#ffffff"
    },
    %{
      id: "new-york-mets",
      name: "New York Mets",
      primary: "#002d72",
      accent: "#ff5910",
      text: "#ffffff"
    },
    %{
      id: "new-york-yankees",
      name: "New York Yankees",
      primary: "#0c2340",
      accent: "#c4ced3",
      text: "#ffffff"
    },
    %{
      id: "oakland-athletics",
      name: "Oakland Athletics",
      primary: "#003831",
      accent: "#efb21e",
      text: "#ffffff"
    },
    %{
      id: "philadelphia-phillies",
      name: "Philadelphia Phillies",
      primary: "#e81828",
      accent: "#002d72",
      text: "#ffffff"
    },
    %{
      id: "pittsburgh-pirates",
      name: "Pittsburgh Pirates",
      primary: "#27251f",
      accent: "#fdb827",
      text: "#ffffff"
    },
    %{
      id: "san-diego-padres",
      name: "San Diego Padres",
      primary: "#2f241d",
      accent: "#ffc425",
      text: "#ffffff"
    },
    %{
      id: "san-francisco-giants",
      name: "San Francisco Giants",
      primary: "#27251f",
      accent: "#fd5a1e",
      text: "#ffffff"
    },
    %{
      id: "seattle-mariners",
      name: "Seattle Mariners",
      primary: "#0c2c56",
      accent: "#005c5c",
      text: "#ffffff"
    },
    %{
      id: "st-louis-cardinals",
      name: "St. Louis Cardinals",
      primary: "#c41e3a",
      accent: "#0c2340",
      text: "#ffffff"
    },
    %{
      id: "tampa-bay-rays",
      name: "Tampa Bay Rays",
      primary: "#092c5c",
      accent: "#8fbc36",
      text: "#ffffff"
    },
    %{
      id: "texas-rangers",
      name: "Texas Rangers",
      primary: "#003278",
      accent: "#c0111f",
      text: "#ffffff"
    },
    %{
      id: "toronto-blue-jays",
      name: "Toronto Blue Jays",
      primary: "#134a8e",
      accent: "#e8291c",
      text: "#ffffff"
    },
    %{
      id: "washington-nationals",
      name: "Washington Nationals",
      primary: "#ab0003",
      accent: "#14225a",
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
