defmodule Merquery.Helpers.State do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{"bindings" => []} end, name: __MODULE__)
  end

  def get_bindings() do
    Agent.get(__MODULE__, &Map.get(&1, "bindings", []))
  end

  def update_bindings(bindings) do
    Agent.update(__MODULE__, &Map.update!(&1, "bindings", fn _ -> bindings end))
  end

  def state() do
    Agent.get(__MODULE__, & &1)
  end
end
