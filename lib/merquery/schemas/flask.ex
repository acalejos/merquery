defmodule Merquery.Schemas.Flask do
  alias Merquery.Schemas.Query

  use Flint,
    schema: [
      embeds_many(:queries, Query),
      field(:queryIndex, :integer, default: 0)
    ]
end
