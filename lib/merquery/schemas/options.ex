defmodule Merquery.Schemas.Options do
  alias Merquery.Schemas.ContentType

  use Flint,
    schema: [
      field(:contentType, ContentType, default: :elixir),
      field(:raw, :string, default: "")
    ]
end
