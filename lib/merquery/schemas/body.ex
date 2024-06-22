defmodule Merquery.Schemas.Body do
  alias Merquery.Schemas.ContentType
  alias Merquery.Schemas.MultiInput

  use Merquery.Schema,
    schema: [
      field(:contentType, ContentType, default: :none),
      embeds_many(:form, MultiInput),
      field(:raw, :string, default: "")
    ]
end
