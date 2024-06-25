defmodule Merquery.Schemas.Auth do
  use Flint,
    schema: [
      field(:scheme, Ecto.Enum,
        values: [:basic, :bearer, :netrc, :none, :string],
        default: :none
      ),
      field(:type, Ecto.Enum,
        values: [plaintext: 0, secret: 1, variable: 2],
        default: :plaintext
      ),
      field(:value, :string, default: "")
    ]
end
