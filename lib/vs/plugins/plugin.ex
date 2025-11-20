defmodule Vs.Plugins.Plugin do
  @callback get_schedule(date :: Date.t() | String.t()) :: {:ok, map()} | {:error, term()}
  @callback get_observations(date :: Date.t() | String.t()) :: {:ok, map()} | {:error, term()}
end
