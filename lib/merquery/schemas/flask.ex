defmodule Merquery.Schemas.Flask do
  alias Merquery.Schemas.Query

  use Merquery.Schema,
    schema: [
      embeds_many(:queries, Query, on_replace: :delete),
      field(:queryIndex, :integer, default: 0)
    ]
end
