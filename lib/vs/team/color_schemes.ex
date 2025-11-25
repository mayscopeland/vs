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
      id: "blue-red",
      name: "Blue & Red",
      primary: "#0033a0",
      accent: "#c8102e",
      text: "#ffffff"
    },
    %{
      id: "black-yellow",
      name: "Black & Yellow",
      primary: "#000000",
      accent: "#ffb81c",
      text: "#ffffff"
    },
    %{
      id: "black-silver",
      name: "Black & Silver",
      primary: "#000000",
      accent: "#a5acaf",
      text: "#ffffff"
    },
    %{
      id: "green-yellow",
      name: "Green & Yellow",
      primary: "#003831",
      accent: "#efb21e",
      text: "#ffffff"
    },
    %{
      id: "blue-orange",
      name: "Blue & Orange",
      primary: "#002d72",
      accent: "#ff5910",
      text: "#ffffff"
    },
    %{
      id: "black-sky",
      name: "Black & Sky Blue",
      primary: "#000000",
      accent: "#00a3e0",
      text: "#ffffff"
    },
    %{
      id: "purple-yellow",
      name: "Purple & Yellow",
      primary: "#552583",
      accent: "#fdb927",
      text: "#ffffff"
    },
    %{
      id: "navy-white",
      name: "Navy & White",
      primary: "#0c2340",
      accent: "#ffffff",
      text: "#ffffff"
    },
    %{
      id: "red-white",
      name: "Red & White",
      primary: "#c41e3a",
      accent: "#ffffff",
      text: "#ffffff"
    },
    %{
      id: "green-white",
      name: "Green & White",
      primary: "#007a33",
      accent: "#ffffff",
      text: "#ffffff"
    },
    %{
      id: "orange-black",
      name: "Orange & Black",
      primary: "#fd5a1e",
      accent: "#000000",
      text: "#000000"
    },
    %{
      id: "teal-orange",
      name: "Teal & Orange",
      primary: "#008e97",
      accent: "#fc4c02",
      text: "#ffffff"
    },
    %{
      id: "purple-black",
      name: "Purple & Black",
      primary: "#241773",
      accent: "#000000",
      text: "#ffffff"
    },
    %{
      id: "red-black",
      name: "Red & Black",
      primary: "#e03a3e",
      accent: "#000000",
      text: "#ffffff"
    },
    %{
      id: "navy-gold",
      name: "Navy & Gold",
      primary: "#12284b",
      accent: "#ffc52f",
      text: "#ffffff"
    },
    %{
      id: "burgundy-gold",
      name: "Burgundy & Gold",
      primary: "#773141",
      accent: "#ffb81c",
      text: "#ffffff"
    },
    %{
      id: "teal-purple",
      name: "Teal & Purple",
      primary: "#00788c",
      accent: "#1d1160",
      text: "#ffffff"
    },
    %{
      id: "red-navy",
      name: "Red & Navy",
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
