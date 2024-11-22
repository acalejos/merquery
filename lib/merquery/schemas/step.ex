defmodule Merquery.Schemas.Step do
  use Flint.Schema

  embedded_schema do
    field :active, :boolean, default: true
    field :doc, :string
    field :name, :string
  end
end
