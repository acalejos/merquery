defmodule Merquery.Schemas.Body do
  use Flint.Schema

  embedded_schema do
    field :contentType, Merquery.Schemas.ContentType, default: :none
    embeds_many :form, Merquery.Schemas.MultiInput
    field :raw, :string, default: ""
  end
end
