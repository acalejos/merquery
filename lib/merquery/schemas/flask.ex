defmodule Merquery.Schemas.Flask do
  use Flint.Schema

  embedded_schema do
    embeds_many :queries, Merquery.Schemas.Query
    field :queryIndex, :integer, default: 0
  end
end
