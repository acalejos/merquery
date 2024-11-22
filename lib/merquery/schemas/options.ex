defmodule Merquery.Schemas.Options do
  use Flint.Schema

  embedded_schema do
    field :contentType, Merquery.Schemas.ContentType, default: :elixir
    field :raw, :string, default: ""
  end
end
