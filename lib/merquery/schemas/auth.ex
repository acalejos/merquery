defmodule Merquery.Schemas.Auth do
  use Flint.Schema

  embedded_schema do
    field :scheme, Ecto.Enum, values: [:basic, :bearer, :netrc, :none, :string], default: :none
    field :type, Merquery.Types.MultiInput, default: :plaintext
    field :value, :string, default: ""
  end
end
