defmodule Merquery.Schemas.Plugin do
  use Flint.Schema

  embedded_schema do
    field :active, :boolean, default: true
    field :description, :string
    field :name, :string
    field :version, :string
  end
end
