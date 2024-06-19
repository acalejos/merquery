defmodule Merquery.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Kino.SmartCell.register(Merquery.SmartCell)

    children = [{Merquery.Helpers.State, %{}}]
    opts = [strategy: :one_for_one, name: Merquery.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
