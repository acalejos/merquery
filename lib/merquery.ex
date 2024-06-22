defmodule Merquery do
  @moduledoc """
  Documentation for `Merquery`.
  """

  def new(module, params \\ %{}) do
    if function_exported?(module, :new, 2) do
      apply(module, :new, [params])
    else
      module.__struct__
      |> Merquery.Schema.cast_all(params)
      |> Ecto.Changeset.apply_changes()
    end
  end
end
