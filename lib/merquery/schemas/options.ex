defmodule Merquery.Schemas.Options do
  alias Merquery.Schemas.ContentType

  use Merquery.Schema,
    schema: [
      field(:contentType, ContentType, default: :elixir),
      field(:raw, :string, default: "")
    ]
end
