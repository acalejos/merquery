defmodule Merquery.Schemas.MultiInput do
  use Merquery.Schema,
    schema: [
      field(:active, :boolean, default: true),
      field(:key, :string, default: ""),
      field(:value, :string, default: ""),
      field(:type, Ecto.Enum,
        values: [plaintext: 0, secret: 1, variable: 2],
        embed_as: :dumped,
        default: :plaintext
      )
    ]

  def to_quoted(%__MODULE__{key: key, value: value, type: :secret}),
    do: {key, quote(do: System.fetch_env!(unquote("LB_#{value}")))}

  def to_quoted(%__MODULE__{key: key, value: value, type: :plaintext}), do: {key, value}

  def to_quoted(%__MODULE__{key: key, value: value, type: :variable}),
    do: {key, quote(do: unquote(Merquery.Helpers.quoted_var(value)))}
end
