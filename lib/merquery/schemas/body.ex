defmodule Merquery.Schemas.Body do
  alias Merquery.Schemas.ContentType
  alias Merquery.Schemas.MultiInput

  use Flint,
    schema: [
      field(:contentType, ContentType, default: :none),
      embeds_many(:form, MultiInput),
      field(:raw, :string, default: "")
    ]
end
