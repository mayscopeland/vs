defmodule Vs.Team.FontStyles do
  @moduledoc """
  Defines the available font styles for teams.
  """

  @type t :: %{
          id: String.t(),
          name: String.t()
        }

  @styles [
    %{
      id: "olde",
      name: "Olde"
    },
    %{
      id: "wood",
      name: "Woodcut"
    }
  ]

  def all, do: @styles

  def get(id) do
    Enum.find(@styles, fn style -> style.id == id end)
  end

  def random do
    Enum.random(@styles)
  end

  def default do
    List.first(@styles)
  end
end
